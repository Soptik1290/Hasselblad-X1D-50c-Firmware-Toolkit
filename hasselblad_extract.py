#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Hasselblad Firmware Decryptor & Extractor (.cim)
================================================
Based on YuHaoyua/hasselblad-cim-firmware-extractor
"""

import sys
import os
import struct
import re
import hashlib
import argparse
from typing import Optional, List, Tuple
from Crypto.Cipher import AES


class CimExtractor:
    # Static AES Key (16 bytes)
    STATIC_KEY = bytes([
        0x93, 0xF8, 0x2C, 0xA2, 0x44, 0xAB, 0x29, 0xE0,
        0x36, 0x69, 0x34, 0xD5, 0x67, 0x13, 0xEE, 0xA2
    ])

    # Salt used for IV generation (16 bytes)
    IV_SALT = bytes([
        0xE6, 0x36, 0xFA, 0xDC, 0x3D, 0x99, 0x2D, 0x07,
        0x05, 0xFD, 0x95, 0x8E, 0x82, 0xE3, 0x14, 0x7A
    ])

    # Magic Salt used for Hash Verification (Appended to content)
    MAGIC_HASH_SALT = bytes([
        0xCD, 0x87, 0xD7, 0x27,
        0xFA, 0x5E, 0xE7, 0xF9,
        0x5D, 0x43, 0xE2, 0xC4,
        0x9E, 0x90, 0xD7, 0x0B
    ])

    CHUNK_SIZE = 4096

    def __init__(self, filepath: str, output_dir: Optional[str] = None):
        self.filepath = filepath
        self.file_size = os.path.getsize(filepath)
        self.output_dir = output_dir
        self.iv = b''

    def _parse_header_timestamp(self, header_bytes: bytes) -> Tuple[Optional[str], Optional[str]]:
        try:
            header_end = header_bytes.find(b'\x1a')
            if header_end == -1:
                return None, None

            header_text = header_bytes[:header_end].decode('utf-8', errors='ignore')
            lines = header_text.split('\r\n')

            date_str = next((line for line in lines if '-' in line and len(line) == 10), None)
            time_str = next((line for line in lines if ':' in line and len(line) == 8), None)

            return date_str, time_str
        except Exception:
            return None, None

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

    def _scan_file_table(self, f_in) -> List[dict]:
        print("[*] Decrypting header to scan for file table...")

        scan_size = 0x2000
        f_in.seek(0x80)

        decrypted_buffer = bytearray()
        processed = 0

        while processed < scan_size:
            remaining = scan_size - processed
            chunk_len = min(self.CHUNK_SIZE, remaining)
            read_len = (chunk_len + 15) // 16 * 16

            ciphertext = f_in.read(read_len)
            if not ciphertext:
                break

            cipher = AES.new(self.STATIC_KEY, AES.MODE_CBC, self.iv)
            plaintext = cipher.decrypt(ciphertext)

            decrypted_buffer.extend(plaintext[:chunk_len])
            processed += chunk_len

        pattern = re.compile(b'\x00{16,}(?P<name>[\x20-\x7E]{3,})\x00')

        files = []
        for match in pattern.finditer(decrypted_buffer):
            try:
                padding_start = match.start()
                meta_start = padding_start - 24

                if meta_start < 0:
                    continue

                offset, size, expected_hash = struct.unpack('>II16s', decrypted_buffer[meta_start:padding_start])
                name = match.group('name').decode('ascii', errors='ignore')

                if offset == 0 or size == 0:
                    continue

                if not any(f['offset'] == offset for f in files):
                    files.append({
                        'name': name,
                        'offset': offset,
                        'size': size,
                        'hash': expected_hash
                    })
            except Exception:
                continue

        if not files:
            print("[!] Warning: Auto-scan found no entries. Attempting default fallback.")
            files.append({
                'name': 'ota.zip',
                'offset': 0x600,
                'size': self.file_size - 0x600,
                'hash': b'\x00' * 16
            })

        files.sort(key=lambda x: x['offset'])
        return files

    def process(self):
        if not os.path.exists(self.filepath):
            print(f"Error: File '{self.filepath}' not found.")
            return

        output_dir = self.output_dir or (os.path.splitext(os.path.basename(self.filepath))[0] + "_extracted")
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        print(f"[*] Analyzing: {self.filepath}")
        print(f"[*] Size:      {self.file_size / (1024*1024):.2f} MB")
        print(f"[*] Output:    {output_dir}{os.sep}")

        with open(self.filepath, 'rb') as f_in:
            header_raw = f_in.read(4096)
            date_s, time_s = self._parse_header_timestamp(header_raw)

            if not date_s:
                print("[-] Error: Could not parse Date/Time from header. Invalid .cim file?")
                return

            self.iv = self._derive_iv(date_s, time_s)
            print(f"[*] Timestamp: {date_s} {time_s}")
            print(f"[*] Derived IV:{self.iv.hex()}")

            files = self._scan_file_table(f_in)

            print("\n" + "=" * 80)
            print(f"{'Filename':<30} | {'Offset (Hex)':<12} | {'Size (Bytes)':<15} | {'Size (MB)':<10}")
            print("-" * 80)
            for f in files:
                print(f"{f['name']:<30} | 0x{f['offset']:08X}   | {f['size']:<15} | {f['size']/1024/1024:<10.2f}")
            print("=" * 80 + "\n")

            for entry in files:
                self._extract_single_file(f_in, entry, output_dir)

        print("\n[*] All operations completed successfully.")

    def _extract_single_file(self, f_in, entry: dict, output_dir: str):
        name = entry['name']
        offset = entry['offset']
        size = entry['size']
        expected_hash = entry['hash']

        safe_name = name.replace('/', '_').replace('\\', '_')
        out_path = os.path.join(output_dir, safe_name)

        print(f"[*] Extracting: {name} ... ", end='', flush=True)

        f_in.seek(offset)
        md5_check = hashlib.md5()
        processed = 0

        try:
            with open(out_path, 'wb') as f_out:
                while processed < size:
                    remaining = size - processed
                    chunk_len = min(self.CHUNK_SIZE, remaining)
                    read_len = (chunk_len + 15) // 16 * 16

                    ciphertext = f_in.read(read_len)
                    if not ciphertext:
                        break

                    cipher = AES.new(self.STATIC_KEY, AES.MODE_CBC, self.iv)
                    plaintext = cipher.decrypt(ciphertext)

                    actual_data = plaintext[:chunk_len]
                    f_out.write(actual_data)
                    md5_check.update(actual_data)
                    processed += chunk_len

            md5_check.update(self.MAGIC_HASH_SALT)
            calc_hash = md5_check.hexdigest()

            if calc_hash == expected_hash.hex():
                print("[OK]")
            else:
                print("[HASH MISMATCH]")
                print(f"    Expected: {expected_hash.hex()}")
                print(f"    Calculated: {calc_hash}")

        except Exception as e:
            print(f"[ERROR] {e}")


def main():
    parser = argparse.ArgumentParser(description="Unpack and decrypt Hasselblad .cim firmware files.")
    parser.add_argument("file", help="Path to the input .cim file")
    parser.add_argument("-o", "--output", help="Output directory", default=None)
    args = parser.parse_args()

    extractor = CimExtractor(args.file, args.output)
    extractor.process()


if __name__ == "__main__":
    main()
