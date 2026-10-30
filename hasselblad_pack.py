#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Hasselblad Firmware Packer (.cim)
=================================
Repacks extracted firmware components (hbl-upgrade, rootfs, uboot, hbl-kks-revisions)
into an AES-128-CBC encrypted VHABCIM (.cim) container.
"""

import os
import struct
import hashlib
import argparse
from pathlib import Path
from typing import List, Tuple
from Crypto.Cipher import AES


class CimPacker:
    STATIC_KEY = bytes([
        0x93, 0xF8, 0x2C, 0xA2, 0x44, 0xAB, 0x29, 0xE0,
        0x36, 0x69, 0x34, 0xD5, 0x67, 0x13, 0xEE, 0xA2
    ])

    IV_SALT = bytes([
        0xE6, 0x36, 0xFA, 0xDC, 0x3D, 0x99, 0x2D, 0x07,
        0x05, 0xFD, 0x95, 0x8E, 0x82, 0xE3, 0x14, 0x7A
    ])

    MAGIC_HASH_SALT = bytes([
        0xCD, 0x87, 0xD7, 0x27,
        0xFA, 0x5E, 0xE7, 0xF9,
        0x5D, 0x43, 0xE2, 0xC4,
        0x9E, 0x90, 0xD7, 0x0B
    ])

    CHUNK_SIZE = 4096

    DEFAULT_FILES = [
        "hbl-upgrade",
        "rootfs",
        "uboot",
        "hbl-kks-revisions",
    ]

    def __init__(self, template_cim: Path, input_dir: Path, output_cim: Path):
        self.template_cim = template_cim
        self.input_dir = input_dir
        self.output_cim = output_cim

    def _parse_header_timestamp(self, header_bytes: bytes) -> Tuple[str, str]:
        header_end = header_bytes.find(b'\x1a')
        header_text = header_bytes[:header_end].decode('utf-8', errors='ignore')
        lines = header_text.split('\r\n')
        date_str = next(line for line in lines if '-' in line and len(line) == 10)
        time_str = next(line for line in lines if ':' in line and len(line) == 8)
        return date_str, time_str

    def _derive_iv(self, date_str: str, time_str: str) -> bytes:
        year, month, day = map(int, date_str.split('-'))
        hour, minute, second = map(int, time_str.split(':'))

        time_buf = bytearray(16)
        time_buf[0] = year // 100
        time_buf[1] = year % 100
        time_buf[2] = month
        time_buf[3] = day
        time_buf[4] = hour
        time_buf[5] = minute
        time_buf[6] = second

        h = hashlib.md5()
        h.update(self.IV_SALT)
        h.update(time_buf)
        return h.digest()

    def _compute_salted_md5(self, filepath: Path) -> Tuple[int, bytes]:
        h = hashlib.md5()
        size = 0
        with filepath.open('rb') as f:
            while True:
                chunk = f.read(65536)
                if not chunk:
                    break
                h.update(chunk)
                size += len(chunk)
        h.update(self.MAGIC_HASH_SALT)
        return size, h.digest()

    def _build_item_header(self, name: str, offset: int, size: int, md5_digest: bytes, iv: bytes) -> bytes:
        buf = bytearray(0x100)
        struct.pack_into('>II16s', buf, 0x24, offset, size, md5_digest)
        name_bytes = name.encode('ascii')[:29]
        buf[0x60:0x60 + len(name_bytes)] = name_bytes
        buf[0x7E:0x80] = b'\r\n'
        cipher = AES.new(self.STATIC_KEY, AES.MODE_CBC, iv)
        return cipher.encrypt(bytes(buf))

    def pack(self):
        with self.template_cim.open('rb') as f_tpl:
            pub_header = bytearray(f_tpl.read(0x80))
            priv_header_enc = f_tpl.read(0x180)

        date_s, time_s = self._parse_header_timestamp(pub_header)
        iv = self._derive_iv(date_s, time_s)
        priv_plain = bytearray(AES.new(self.STATIC_KEY, AES.MODE_CBC, iv).decrypt(priv_header_enc))
        print(f"[*] Template timestamp: {date_s} {time_s}")
        print(f"[*] Derived IV:         {iv.hex()}")

        entries = []
        current_offset = 0x600

        for name in self.DEFAULT_FILES:
            fpath = self.input_dir / name
            if not fpath.exists():
                raise FileNotFoundError(f"Missing component file: {fpath}")
            size, digest = self._compute_salted_md5(fpath)
            # Align next file offset: 4KB chunk boundary / 0x200 alignment matching original layout
            padded_slot = ((size + 0x1FF) // 0x200) * 0x200
            if padded_slot - size < 0x100:
                padded_slot += 0x200
            entries.append({
                'name': name,
                'path': fpath,
                'offset': current_offset,
                'size': size,
                'padded_slot': padded_slot,
                'hash': digest,
            })
            current_offset += padded_slot

        # Final file size is aligned to 0x1000 (4096 bytes)
        total_size = ((entries[-1]['offset'] + entries[-1]['size'] + 0xFFF) // 0x1000) * 0x1000
        entries[-1]['padded_slot'] = total_size - entries[-1]['offset']

        # Update total size in PublicHeader at 0x44..0x48 (Big-Endian)
        struct.pack_into('>I', pub_header, 0x44, total_size)

        print(f"[*] Total output .cim size: {total_size} bytes (0x{total_size:08X})")
        h_from_200 = hashlib.md5()

        with self.output_cim.open('wb') as f_out:
            f_out.write(pub_header)
            f_out.write(priv_header_enc)  # placeholder, updated after computing two-stage PrivateHeader checksum

            for e in entries:
                item_hdr_enc = self._build_item_header(e['name'], e['offset'], e['size'], e['hash'], iv)
                f_out.write(item_hdr_enc)
                h_from_200.update(item_hdr_enc)

            for e in entries:
                assert f_out.tell() == e['offset'], f"Offset mismatch: {f_out.tell():#x} != {e['offset']:#x}"
                print(f"[*] Packing {e['name']:<20} @ 0x{e['offset']:08X} (size={e['size']} B, md5={e['hash'].hex()})")
                written = 0
                with e['path'].open('rb') as f_in:
                    while written < e['padded_slot']:
                        chunk_plain = bytearray(f_in.read(self.CHUNK_SIZE))
                        read_n = len(chunk_plain)
                        need_pad = min(self.CHUNK_SIZE, e['padded_slot'] - written) - read_n
                        if need_pad > 0:
                            chunk_plain.extend(b'\x00' * need_pad)
                        cipher = AES.new(self.STATIC_KEY, AES.MODE_CBC, iv)
                        enc_chunk = cipher.encrypt(bytes(chunk_plain))
                        f_out.write(enc_chunk)
                        h_from_200.update(enc_chunk)
                        written += len(chunk_plain)

            # Two-stage PrivateHeader::Checksum (verified in upgrade-daemon @ 0x2d6ac):
            # Stage 1: hash1 = MD5(encrypted_bytes[0x200:EOF] + MAGIC_HASH_SALT)
            # Stage 2: priv_checksum = MD5(hash1 + priv_plain[0x20:0x180])
            h_from_200.update(self.MAGIC_HASH_SALT)
            hash1 = h_from_200.digest()
            priv_checksum = hashlib.md5(hash1 + priv_plain[0x20:0x180]).digest()
            priv_plain[0x10:0x20] = priv_checksum
            priv_header_enc_new = AES.new(self.STATIC_KEY, AES.MODE_CBC, iv).encrypt(bytes(priv_plain))
            f_out.seek(0x80)
            f_out.write(priv_header_enc_new)
            print(f"[*] Updated PrivateHeader::Checksum @ 0x90..0x9F: {priv_checksum.hex()}")

        print(f"[+] Successfully packed .cim to {self.output_cim}")


def main():
    parser = argparse.ArgumentParser(description="Pack extracted Hasselblad X1D firmware files into a .cim container.")
    parser.add_argument("-t", "--template", type=Path, required=True, help="Original .cim file used for headers")
    parser.add_argument("-i", "--input-dir", type=Path, required=True, help="Directory with hbl-upgrade, rootfs, uboot, hbl-kks-revisions")
    parser.add_argument("-o", "--output", type=Path, required=True, help="Output .cim file path")
    args = parser.parse_args()

    packer = CimPacker(args.template, args.input_dir, args.output)
    packer.pack()


if __name__ == "__main__":
    main()
