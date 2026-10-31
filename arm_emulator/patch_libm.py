#!/usr/bin/env python3
"""
Patches Yocto libm.so.6 to export GLIBC_2.27 for Mesa swrast / LLVM compatibility.
Replaces the unused GLIBC_2.18 version definition with GLIBC_2.27 and associates
logf, expf, exp2f, powf, and log2f with GLIBC_2.27 so that Mesa 18+ and LLVM 10
can load seamlessly on Yocto Linux without full GLIBC upgrade.
"""

import sys
import struct

def elf_hash(name):
    h = 0
    for c in name.encode('ascii'):
        h = (h << 4) + c
        g = h & 0xf0000000
        if g:
            h ^= g >> 24
        h &= ~g
    return h

def patch_libm(path):
    with open(path, 'rb') as f:
        data = bytearray(f.read())

    # Check if already patched
    if b'GLIBC_2.27' in data:
        print(f"[patch_libm] {path} already defines GLIBC_2.27.")
        return

    idx_str = data.find(b'GLIBC_2.18')
    if idx_str == -1:
        print(f"[patch_libm] Warning: GLIBC_2.18 not found in {path}")
        return

    data[idx_str:idx_str+10] = b'GLIBC_2.27'

    hash_218 = struct.pack('<I', elf_hash('GLIBC_2.18'))
    hash_227 = struct.pack('<I', elf_hash('GLIBC_2.27'))
    idx_hash = data.find(hash_218)
    if idx_hash != -1:
        data[idx_hash:idx_hash+4] = hash_227

    # Update math symbol versions in .gnu.version to index 4 (GLIBC_2.27)
    # Symbol indices in Yocto 2.0.3 libm.so.6:
    # 71: logf, 141: expf, 232: exp2f, 289: powf, 375: log2f
    ver_offset = 0x3664
    indices = [71, 141, 232, 289, 375]
    for idx in indices:
        if ver_offset + idx * 2 + 2 <= len(data):
            struct.pack_into('<H', data, ver_offset + idx * 2, 4)

    with open(path, 'wb') as f:
        f.write(data)

    print(f"[patch_libm] Successfully patched {path} for Mesa SWRAST / LLVM GLIBC_2.27 support.")

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else '/x1d_root/lib/libm.so.6'
    patch_libm(target)
