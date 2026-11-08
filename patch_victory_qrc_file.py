#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Qt Resource (QRC) In-Place Patcher for Hasselblad X1D `victory-gui`
===================================================================
Based on YuHaoyua/hasselblad-x1d-reverse-engineering
"""

import argparse
import zlib
from pathlib import Path


NAMES_BASE = 0x1D7E44
TREE_BASE = 0x1DC7F0
DATA_BASE = 0x0FC7F8


def u16(buf, off):
    return int.from_bytes(buf[off:off + 2], "big")


def u32(buf, off):
    return int.from_bytes(buf[off:off + 4], "big")


def put_u32(buf, off, value):
    buf[off:off + 4] = value.to_bytes(4, "big")


def strip_qml_js_comments(source_bytes: bytes) -> bytes:
    """
    Safely strips // line comments and /* ... */ block comments from QML/JS
    while preserving string literals ("..." and '...') to maximize QRC slot headroom.
    """
    text = source_bytes.decode("utf-8", errors="ignore")
    out = []
    i = 0
    n = len(text)
    in_str = None
    while i < n:
        ch = text[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == in_str:
                in_str = None
            i += 1
        else:
            if ch in ('"', "'"):
                in_str = ch
                out.append(ch)
                i += 1
            elif ch == "/" and i + 1 < n and text[i + 1] == "/":
                i += 2
                while i < n and text[i] not in ("\n", "\r"):
                    i += 1
            elif ch == "/" and i + 1 < n and text[i + 1] == "*":
                i += 2
                while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                    i += 1
                i += 2
            else:
                out.append(ch)
                i += 1
    lines = [line.rstrip() for line in "".join(out).splitlines()]
    compact = "\n".join(line for line in lines if line.strip() != "") + "\n"
    return compact.encode("utf-8")



class ResourceMap:
    def __init__(self, blob):
        self.blob = blob
        self.entries = []
        self._walk(0, [])
        offsets = sorted(entry["data_offset"] for entry in self.entries)
        self.next_offset = {}
        for i, offset in enumerate(offsets):
            self.next_offset[offset] = offsets[i + 1] if i + 1 < len(offsets) else None

    def name_at(self, offset):
        base = NAMES_BASE + offset
        length = u16(self.blob, base)
        return self.blob[base + 6:base + 6 + length * 2].decode("utf-16-be")

    def node_at(self, index):
        base = TREE_BASE + index * 14
        return {
            "name_offset": u32(self.blob, base),
            "flags": u16(self.blob, base + 4),
            "a": u32(self.blob, base + 6),
            "b": u32(self.blob, base + 10),
        }

    def _walk(self, index, parts):
        node = self.node_at(index)
        name = "" if index == 0 else self.name_at(node["name_offset"])
        current = parts + ([name] if name else [])
        if node["flags"] & 0x2:
            for child in range(node["b"], node["b"] + node["a"]):
                self._walk(child, current)
            return
        self.entries.append({
            "path": "/".join(current),
            "flags": node["flags"],
            "data_offset": node["b"],
        })

    def find(self, path):
        normalized = path.lstrip("/")
        for entry in self.entries:
            if entry["path"] == normalized:
                return entry
        raise KeyError(path)

    def slot_size(self, entry):
        next_offset = self.next_offset[entry["data_offset"]]
        if next_offset is None:
            return (NAMES_BASE - DATA_BASE) - entry["data_offset"]
        return next_offset - entry["data_offset"]


def patch_file(binary: Path, resource_path: str, replacement: bytes, strip_comments: bool = False) -> bytes:
    blob = bytearray(binary.read_bytes())
    resources = ResourceMap(blob)
    entry = resources.find(resource_path)
    slot = resources.slot_size(entry)
    if slot is None:
        raise RuntimeError("cannot patch last resource safely")

    is_code = resource_path.endswith((".qml", ".js"))
    if strip_comments and is_code:
        replacement = strip_qml_js_comments(replacement)

    base = DATA_BASE + entry["data_offset"]
    flags = entry["flags"]
    if flags & 0x1:
        compressed = zlib.compress(replacement, 9)
        compressed_payload_len = 4 + len(compressed)
        needed = 4 + compressed_payload_len
        if needed > slot and is_code and not strip_comments:
            stripped = strip_qml_js_comments(replacement)
            comp_stripped = zlib.compress(stripped, 9)
            if 8 + len(comp_stripped) <= slot:
                print(f"[*] Auto-stripped QML/JS comments to fit '{resource_path}' ({needed} B -> {8 + len(comp_stripped)} B)")
                replacement = stripped
                compressed = comp_stripped
                compressed_payload_len = 4 + len(compressed)
                needed = 4 + compressed_payload_len
        if needed > slot:
            raise RuntimeError(
                f"replacement does not fit: need {needed} bytes, slot has {slot}"
            )
        put_u32(blob, base, compressed_payload_len)
        put_u32(blob, base + 4, len(replacement))
        blob[base + 8:base + 8 + len(compressed)] = compressed
        blob[base + 8 + len(compressed):base + slot] = b"\0" * (slot - needed)
        print(f"[+] Patched '{resource_path}' (zlib): needed {needed} B / slot {slot} B (free slack: {slot - needed} B)")
    else:
        needed = 4 + len(replacement)
        if needed > slot and is_code and not strip_comments:
            stripped = strip_qml_js_comments(replacement)
            if 4 + len(stripped) <= slot:
                print(f"[*] Auto-stripped QML/JS comments to fit '{resource_path}' ({needed} B -> {4 + len(stripped)} B)")
                replacement = stripped
                needed = 4 + len(replacement)
        if needed > slot:
            raise RuntimeError(
                f"replacement does not fit: need {needed} bytes, slot has {slot}"
            )
        put_u32(blob, base, len(replacement))
        blob[base + 4:base + 4 + len(replacement)] = replacement
        blob[base + 4 + len(replacement):base + slot] = b"\0" * (slot - needed)
        print(f"[+] Patched '{resource_path}' (raw): needed {needed} B / slot {slot} B (free slack: {slot - needed} B)")
    return bytes(blob)


def main():
    parser = argparse.ArgumentParser(description="Patch a single QRC resource inside victory-gui.")
    parser.add_argument("input_binary", type=Path, help="Path to original victory-gui binary")
    parser.add_argument("resource_path", help="Internal QRC path (e.g. components/popups/PopoverFocusMode.qml)")
    parser.add_argument("replacement_file", type=Path, help="Path to modified QML/JS/PNG file")
    parser.add_argument("-o", "--output", type=Path, required=True, help="Path to output patched binary")
    parser.add_argument("--strip-comments", action="store_true", help="Strip // and /* */ comments before compressing")
    args = parser.parse_args()

    if args.output.resolve() == args.input_binary.resolve():
        raise SystemExit("refusing to patch input in place")

    patched = patch_file(args.input_binary, args.resource_path, args.replacement_file.read_bytes(), strip_comments=args.strip_comments)
    args.output.write_bytes(patched)
    print(f"[+] Wrote patched binary to {args.output}")


if __name__ == "__main__":
    main()
