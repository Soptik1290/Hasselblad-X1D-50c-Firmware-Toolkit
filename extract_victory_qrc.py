#!/usr/bin/env python3
import argparse
import shutil
import zlib
from pathlib import Path


RESOURCE_SETS = {
    "victory-gui": {
        "names": 0x1D7E44,
        "tree": 0x1DC7F0,
        "data": 0x0FC7F8,
    },
}


def u16(buf, off):
    return int.from_bytes(buf[off:off + 2], "big")


def u32(buf, off):
    return int.from_bytes(buf[off:off + 4], "big")


class QtResourceExtractor:
    def __init__(self, blob, names_base, tree_base, data_base):
        self.blob = blob
        self.names_base = names_base
        self.tree_base = tree_base
        self.data_base = data_base

    def name_at(self, offset):
        base = self.names_base + offset
        length = u16(self.blob, base)
        raw = self.blob[base + 6:base + 6 + length * 2]
        return raw.decode("utf-16-be")

    def node_at(self, index):
        base = self.tree_base + index * 14
        return {
            "name_offset": u32(self.blob, base),
            "flags": u16(self.blob, base + 4),
            "a": u32(self.blob, base + 6),
            "b": u32(self.blob, base + 10),
        }

    def data_at(self, offset, flags):
        base = self.data_base + offset
        length = u32(self.blob, base)
        if flags & 0x1:
            compressed_payload = self.blob[base + 4:base + 4 + length]
            uncompressed_length = u32(compressed_payload, 0)
            compressed = compressed_payload[4:]
            data = zlib.decompress(compressed)
            if len(data) != uncompressed_length:
                raise ValueError(f"bad decompressed size at 0x{offset:x}")
            return data
        return self.blob[base + 4:base + 4 + length]

    def walk(self, index=0, parts=None):
        parts = [] if parts is None else parts
        node = self.node_at(index)
        name = "" if index == 0 else self.name_at(node["name_offset"])
        current = parts + ([name] if name else [])

        if node["flags"] & 0x2:
            for child in range(node["b"], node["b"] + node["a"]):
                yield from self.walk(child, current)
            return

        yield "/".join(current), node["flags"], node["b"], self.data_at(node["b"], node["flags"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path, help="Path to rootfs/usr/bin/victory-gui")
    parser.add_argument("-o", "--output", type=Path, default=Path("victory_gui_qml_extracted"))
    parser.add_argument("--keep", action="store_true", help="Do not remove the output directory first")
    args = parser.parse_args()

    blob = args.binary.read_bytes()
    offsets = RESOURCE_SETS["victory-gui"]
    extractor = QtResourceExtractor(blob, offsets["names"], offsets["tree"], offsets["data"])
    files = list(extractor.walk())

    if args.output.exists() and not args.keep:
        shutil.rmtree(args.output)
    args.output.mkdir(parents=True, exist_ok=True)

    for relpath, _flags, _offset, data in files:
        target = args.output / relpath
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)

    qml = sum(path.endswith(".qml") for path, *_ in files)
    js = sum(path.endswith(".js") for path, *_ in files)
    png = sum(path.endswith(".png") for path, *_ in files)
    print(f"extracted {len(files)} files to {args.output}")
    print(f"qml={qml} js={js} png={png}")


if __name__ == "__main__":
    main()
