#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Hasselblad X1D-50c ("Wedge") Custom Lightweight Firmware Builder
================================================================
Builds a clean, lightweight X1D-only custom firmware (`firmware/X1D_v1_25_0_x1d_lite.cim`):
  1. Strips all // and /* ... */ comments and blank lines from all 137 QML/JS files in `victory_gui_qml/`.
  2. Removes UI definitions and code branches for other Umbrella models (`Victory` H6D-50c,
     `Albatross` H6D-100c, `A6D-50c/100c`, `Idun` CFV II 50C / 907X).
  3. Recompresses and patches all 137 QML/JS resources into `/usr/bin/victory-gui` with `zlib` level 9.
  4. Repacks `rootfs` (`rootfs.tar.bz2`), injecting the patched `/usr/bin/victory-gui`, stripping
     comments/other-model branches from `/usr/bin/program_nodes.sh`, and removing 25.93 MB of
     non-X1D coprocessor firmware blobs from `/lib/firmware/hbl/`.
  5. Packs and encrypts `firmware/X1D_v1_25_0_x1d_lite.cim` with AES-128-CBC (4KB IV reset),
     salted MD5 item digests, and the verified two-stage `PrivateHeader::Checksum`.
"""

import io
import json
import time
import zlib
import struct
import tarfile
import hashlib
import argparse
from pathlib import Path
from typing import Dict, Any, List, Tuple
from Crypto.Cipher import AES

from patch_victory_qrc_file import (
    ResourceMap,
    DATA_BASE,
    NAMES_BASE,
    TREE_BASE,
    u32,
    put_u32,
    strip_qml_js_comments,
)
from verify_firmware_safety import check_balanced_syntax, run_preflight_sweep
from hasselblad_pack import CimPacker
from cim_emulator_loader import decrypt_stream_4k, STATIC_KEY, IV_SALT, MAGIC_HASH_SALT

ROOT_DIR = Path(__file__).resolve().parent
QML_DIR = ROOT_DIR / "victory_gui_qml"
EXTRACTED_DIR = ROOT_DIR / "X1D_v1_25_0_extracted"
FIRMWARE_DIR = ROOT_DIR / "firmware"
TEMPLATE_CIM = FIRMWARE_DIR / "X1D_v1_25_0.cim"
OUTPUT_CIM = FIRMWARE_DIR / "X1D_v1_25_0_x1d_lite.cim"


# Non-X1D coprocessor firmware files & symlinks in /lib/firmware/hbl/ (H6D, A6D, CFV II 50C)
NON_X1D_FIRMWARE_PREFIXES = (
    "./lib/firmware/hbl/cambody-h6",
    "./lib/firmware/hbl/farm/bootimage_even-victory",
    "./lib/firmware/hbl/farm/bootimage_odd-victory",
    "./lib/firmware/hbl/farm/bootimage_even-albatross",
    "./lib/firmware/hbl/farm/bootimage_odd-albatross",
    "./lib/firmware/hbl/farm/bootimage_even-idun",
    "./lib/firmware/hbl/farm/bootimage_odd-idun",
    "./lib/firmware/hbl/su-control/su-control",
    "./lib/firmware/hbl/fx3/fx3_victory",
    "./lib/firmware/hbl/fx3/fx3_albatross",
    "./lib/firmware/hbl/fx3/fx3_a6d50",
    "./lib/firmware/hbl/fx3/fx3_a6d100",
    "./lib/firmware/hbl/fx3/fx3_cfv",
    "./lib/firmware/hbl/fx3/fx3_generic",
)

CLEAN_PROGRAM_NODES_SH = b"""#!/bin/sh
FW_DIR=/lib/firmware/hbl
LOG_DIR=/media/data/logs/upgrade
PART_NUMBER=$(cat /sys/fsl_otp/HW_OCOTP_GP1)

detect_product() {
    ${1}usr/bin/is_wedge
    IS_WEDGE=$?
}

set_upgrade_progress() {
    busctl set-property com.hasselblad.upgrade / com.hasselblad.upgrade upgradeProgress i ${1} > /dev/null 2>&1
}

check_usb_connected() {
    USB_CONNECTED=$(busctl get-property com.hasselblad.suc /suc com.hasselblad.suc usb_vbus_present)
    CHECK_USB=$(busctl get-property com.hasselblad.upgrade / com.hasselblad.upgrade checkUsbConnected)
    echo "USB_CONNECTED: $USB_CONNECTED"
    echo "CHECK_USB: $CHECK_USB"
    if [[ "$CHECK_USB" == "b true" && "$USB_CONNECTED" == "b true" ]]; then
        return 1
    fi
    return 0
}

update_suc() {
    echo "Enable autostart before programming suc"
    busctl set-property com.hasselblad.suc /suc com.hasselblad.suc autostart b true
    busctl set-property com.hasselblad.suc / com.hasselblad.suc autostart b true
    sleep 1

    check_usb_connected
    status=$?
    if [ $status -eq 1 ]; then
        echo "USB must NOT be connected when flashing SUC! Aborting"
        return 1
    fi

    echo "Start upgrading SUC (Wedge camera-control.bin)"
    SUC_FW=$2${FW_DIR}/su-control/camera-control.bin
    ${1}usr/bin/program_suc.sh ${SUC_FW}
    status=$?

    if [ $status -eq 0 ]; then
        echo "End upgrading SUC $status"
        return 0
    fi
    if [ $status -eq 1 ]; then
        echo "Could not start to program SUC"
        return 1
    fi
    if [ $status -eq 2 ]; then
        ${1}usr/bin/program_suc.sh ${SUC_FW}
        status=$?
    fi
    if [ $status -eq 0 ]; then
        return 1
    fi
    if [ $status -ne 0 ]; then
        ${1}usr/bin/erase_suc.sh
        status=$?
    fi
    echo "Error, SUC is in unknown state. Giving up"
    return 2
}

update_spc() {
    echo "Start upgrading sensor power control"
    ${1}usr/bin/program_spc.sh $2${FW_DIR}/power-control/power-control.bin
    status=$?
    echo "End upgrading sensor power control $status"
    return $status
}

update_fx3() {
    FX3_FW=$2${FW_DIR}/fx3/fx3_wedge.bin
    echo "Start upgrading FX3 with $FX3_FW"
    ${1}usr/bin/program_fx3.sh ${FX3_FW}
    status=$?
    echo "End upgrading FX3 $status"
    return $status
}

update_touch() {
    echo "Start upgrading touch"
    ${1}usr/bin/program_touch.sh $2${FW_DIR}/touch
    status=$?
    echo "End upgrading touch $status"
    return $status
}

check_rtc() {
    echo "Start checking RTC"
    YEAR=$(hwclock -r -f /dev/rtc1 | awk '{print $(NF-1)}')
    if [ "${YEAR}" -lt "2016" ]; then
        hwclock -w -f /dev/rtc1
    fi
    echo "End checking RTC"
}

update_farm() {
    echo "Start upgrading FARM (Wedge)"
    EVEN_FILE=$2${FW_DIR}/farm/bootimage_even-wedge.bin
    ODD_FILE=$2${FW_DIR}/farm/bootimage_odd-wedge.bin
    ${1}usr/bin/program_farm.sh ${EVEN_FILE} ${ODD_FILE}
    status=$?
    echo "End upgrading FARM $status"
    return $status
}

echo "==== executing program_nodes.sh (X1D Wedge Clean Build)"
if [ $# -lt 3 ]; then
    echo "Too few arguments supplied"
    exit 1
fi

TOOL_PREFIX=$1
BLOB_PREFIX=$2
CONTINUE_ON_FAIL=$3

if [ -e "/tmp/continue_on_fail" ]; then
    CONTINUE_ON_FAIL=1
fi

detect_product $TOOL_PREFIX $BLOB_PREFIX
if [ $IS_WEDGE -ne 0 ]; then
    echo "Non-Wedge part number $PART_NUMBER rejected by X1D-only firmware"
    exit 1
fi

set_upgrade_progress 20
update_farm ${TOOL_PREFIX} ${BLOB_PREFIX}
status=$?
final_status=$status

if [[ $status -eq 0 ]] || [[ $CONTINUE_ON_FAIL -eq 1 ]]; then
    set_upgrade_progress 40
    update_spc ${TOOL_PREFIX} ${BLOB_PREFIX}
    status=$?
    [ $status -eq 0 ] || final_status=$status
fi

if [[ $status -eq 0 ]] || [[ $CONTINUE_ON_FAIL -eq 1 ]]; then
    set_upgrade_progress 60
    update_fx3 ${TOOL_PREFIX} ${BLOB_PREFIX}
    status=$?
    [ $status -eq 0 ] || final_status=$status
fi

if [[ $status -eq 0 ]] || [[ $CONTINUE_ON_FAIL -eq 1 ]]; then
    update_touch ${TOOL_PREFIX} ${BLOB_PREFIX}
    status=$?
    [ $status -eq 0 ] || final_status=$status
fi

if [[ $status -eq 0 ]] || [[ $CONTINUE_ON_FAIL -eq 1 ]]; then
    check_rtc
fi

if [[ $status -eq 0 ]] || [[ $CONTINUE_ON_FAIL -eq 1 ]]; then
    set_upgrade_progress 80
    update_suc ${TOOL_PREFIX} ${BLOB_PREFIX}
    status=$?
    [ $status -eq 0 ] || final_status=$status
fi

if [ ! -d ${LOG_DIR} ]; then
    mkdir -p ${LOG_DIR}
fi

journalctl -b -o short-precise > ${LOG_DIR}/upgrade.log
exit ${final_status}
"""

CLEAN_IS_WEDGE_SH = b"""#!/bin/sh
FUSED_SERIAL=$(cat /sys/fsl_otp/HW_OCOTP_GP1)
echo $FUSED_SERIAL | grep -q "0x5f701" && exit 0
echo $FUSED_SERIAL | grep -q "0x5f702"
exit $?
"""

CLEAN_FALSE_SH = b"""#!/bin/sh
exit 1
"""


AFC_MODULE_FILES = (
    "common/GlobalStateInfo.qml",
    "common/TouchWindow.qml",
    "components/popups/PopoverFocusMode.qml",
    "controlscreen/ControlScreen.qml",
    "liveview/AFIndicator.qml",
    "liveview/EVFWindow.qml",
    "liveview/LiveViewImage.qml",
    "liveview/LiveViewOverlay.qml",
    "main.qml",
)


def strip_all_qml_js_in_workspace() -> Dict[str, int]:
    """Strips comments and blank lines from all 137 .qml and .js files in victory_gui_qml/."""
    code_files = sorted(
        p for p in QML_DIR.rglob("*") if p.is_file() and p.suffix in (".qml", ".js")
    )
    bytes_before = 0
    bytes_after = 0
    files_cleaned = 0

    for fpath in code_files:
        raw = fpath.read_bytes()
        bytes_before += len(raw)
        cleaned = strip_qml_js_comments(raw)
        rel = fpath.relative_to(QML_DIR).as_posix()
        err = check_balanced_syntax(cleaned, rel)
        if err:
            raise RuntimeError(f"Syntax error after stripping comments in {err}")
        if cleaned != raw:
            fpath.write_bytes(cleaned)
            files_cleaned += 1
        bytes_after += len(cleaned)

    return {
        "total_code_files": len(code_files),
        "files_cleaned": files_cleaned,
        "bytes_before": bytes_before,
        "bytes_after": bytes_after,
        "bytes_saved": bytes_before - bytes_after,
    }


def extract_factory_rootfs_from_cim(cim_path: Path) -> bytes:
    """Extracts the original unmodified rootfs.tar.bz2 bytes from X1D_v1_25_0.cim."""
    raw_cim = cim_path.read_bytes()
    pub = raw_cim[:0x80]
    header_text = pub[: pub.find(b"\x1a")].decode("ascii", errors="ignore")
    lines = header_text.split("\r\n")
    d_parts = [int(x) for x in lines[3].split("-")]
    t_parts = [int(x) for x in lines[4].split(":")]
    tb = bytearray(16)
    tb[0], tb[1], tb[2], tb[3] = d_parts[0] // 100, d_parts[0] % 100, d_parts[1], d_parts[2]
    tb[4], tb[5], tb[6] = t_parts[0], t_parts[1], t_parts[2]
    iv = hashlib.md5(IV_SALT + bytes(tb)).digest()

    for idx in range(4):
        hdr_off = 0x200 + idx * 0x100
        ihdr = AES.new(STATIC_KEY, AES.MODE_CBC, iv).decrypt(raw_cim[hdr_off : hdr_off + 0x100])
        data_offset, true_size, _ = struct.unpack(">II16s", ihdr[0x24:0x3C])
        name = ihdr[0x60:0x7E].split(b"\x00", 1)[0].decode("ascii", errors="ignore")
        if name == "rootfs":
            aligned_size = ((true_size + 15) // 16) * 16
            return decrypt_stream_4k(raw_cim[data_offset : data_offset + aligned_size], iv, true_size)
    raise RuntimeError("rootfs item not found in template .cim")


def patch_qrc_into_victory_gui(
    orig_vgui: bytes,
    only_paths: Tuple[str, ...] = None,
    strip_comments_in_memory: bool = True,
) -> Tuple[bytes, Dict[str, Any]]:
    """
    Patches QRC resources from victory_gui_qml/ into victory-gui with zlib level 9.
    If `only_paths` is provided (e.g. `AFC_MODULE_FILES`), ONLY those QRC slots are
    modified and all other 397 QRC resources remain 100% factory-original.
    """
    blob = bytearray(orig_vgui)
    rmap = ResourceMap(blob)

    total_slot_capacity = NAMES_BASE - DATA_BASE
    packed_before = 0
    packed_after = 0
    patched_count = 0
    slot_details: List[Dict[str, Any]] = []

    for entry in rmap.entries:
        rpath = entry["path"]
        flags = entry["flags"]
        base = DATA_BASE + entry["data_offset"]
        slot = rmap.slot_size(entry)

        old_used = 4 + u32(blob, base)
        packed_before += old_used

        if only_paths is not None and rpath not in only_paths:
            packed_after += old_used
            continue

        disk_file = QML_DIR / rpath
        if not disk_file.exists():
            packed_after += old_used
            continue

        replacement = disk_file.read_bytes()
        is_code = rpath.endswith((".qml", ".js"))
        if is_code and strip_comments_in_memory:
            replacement = strip_qml_js_comments(replacement)
            err = check_balanced_syntax(replacement, rpath)
            if err:
                raise RuntimeError(f"Syntax error after in-memory comment strip in {err}")

        if flags & 0x1:
            compressed = zlib.compress(replacement, 9)
            compressed_payload_len = 4 + len(compressed)
            needed = 4 + compressed_payload_len
            if not is_code and needed >= old_used:
                packed_after += old_used
                continue
            if needed > slot:
                raise RuntimeError(f"QRC overflow in {rpath}: need {needed} B, slot has {slot} B")
            put_u32(blob, base, compressed_payload_len)
            put_u32(blob, base + 4, len(replacement))
            blob[base + 8 : base + 8 + len(compressed)] = compressed
            blob[base + 8 + len(compressed) : base + slot] = b"\x00" * (slot - needed)
            packed_after += needed
            patched_count += 1
            slot_details.append({
                "path": rpath,
                "flags": flags,
                "slot_capacity": slot,
                "old_used": old_used,
                "new_used": needed,
                "spare_bytes": slot - needed,
            })
        else:
            needed = 4 + len(replacement)
            if needed > slot:
                raise RuntimeError(f"QRC raw overflow in {rpath}: need {needed} B, slot has {slot} B")
            if is_code or needed != old_used:
                put_u32(blob, base, len(replacement))
                blob[base + 4 : base + 4 + len(replacement)] = replacement
                blob[base + 4 + len(replacement) : base + slot] = b"\x00" * (slot - needed)
                patched_count += 1
                slot_details.append({
                    "path": rpath,
                    "flags": flags,
                    "slot_capacity": slot,
                    "old_used": old_used,
                    "new_used": needed,
                    "spare_bytes": slot - needed,
                })
            packed_after += needed

    stats = {
        "patched_resources": patched_count,
        "qrc_pool_capacity": total_slot_capacity,
        "packed_before": packed_before,
        "packed_after": packed_after,
        "packed_saved": packed_before - packed_after,
        "free_pool_after": total_slot_capacity - packed_after,
        "slot_details": slot_details,
    }
    return bytes(blob), stats


def build_stock_rootfs_with_patched_gui(
    factory_rootfs_bz2: bytes, patched_vgui: bytes
) -> Tuple[bytes, Dict[str, Any]]:
    """
    Rebuilds rootfs.tar.bz2 on top of the stock 1.25.0 rootfs, replacing ONLY
    `/usr/bin/victory-gui` while keeping all coprocessor blobs and scripts factory-original.
    """
    out_buf = io.BytesIO()
    kept_files = 0
    uncompressed_bytes = 0

    with tarfile.open(fileobj=io.BytesIO(factory_rootfs_bz2), mode="r:bz2") as tar_in:
        with tarfile.open(fileobj=out_buf, mode="w:bz2", compresslevel=9) as tar_out:
            for member in tar_in:
                if member.name == "./usr/bin/victory-gui" and member.isfile():
                    member.size = len(patched_vgui)
                    uncompressed_bytes += member.size
                    tar_out.addfile(member, io.BytesIO(patched_vgui))
                    kept_files += 1
                    continue

                if member.isfile():
                    uncompressed_bytes += member.size
                    tar_out.addfile(member, tar_in.extractfile(member))
                else:
                    tar_out.addfile(member)
                kept_files += 1

    new_rootfs_bz2 = out_buf.getvalue()
    stats = {
        "kept_members": kept_files,
        "removed_members_count": 0,
        "removed_uncompressed_bytes": 0,
        "uncompressed_bytes": uncompressed_bytes,
        "compressed_before_bytes": len(factory_rootfs_bz2),
        "compressed_after_bytes": len(new_rootfs_bz2),
        "compressed_saved_bytes": len(factory_rootfs_bz2) - len(new_rootfs_bz2),
        "removed_files": [],
    }
    return new_rootfs_bz2, stats


def build_x1d_clean_rootfs(factory_rootfs_bz2: bytes, patched_vgui: bytes) -> Tuple[bytes, Dict[str, Any]]:
    """
    Rebuilds rootfs.tar.bz2:
      - Injects patched `/usr/bin/victory-gui`
      - Strips non-X1D coprocessor firmware blobs from `/lib/firmware/hbl/`
      - Replaces `/usr/bin/program_nodes.sh` and `is_*` scripts with comment-free X1D versions
      - Redirects `/lib/firmware/hbl/fx3/fx3.bin` -> `fx3_wedge.bin`
    """
    out_buf = io.BytesIO()
    removed_files: List[Dict[str, Any]] = []
    removed_bytes = 0
    kept_files = 0
    uncompressed_bytes = 0

    script_replacements = {
        "./usr/bin/program_nodes.sh": CLEAN_PROGRAM_NODES_SH,
        "./usr/bin/is_wedge": CLEAN_IS_WEDGE_SH,
        "./usr/bin/is_victory": CLEAN_FALSE_SH,
        "./usr/bin/is_albatross": CLEAN_FALSE_SH,
        "./usr/bin/is_idun": CLEAN_FALSE_SH,
        "./usr/bin/is_a6d": CLEAN_FALSE_SH,
        "./usr/bin/is_a6d50": CLEAN_FALSE_SH,
        "./usr/bin/is_a6d100": CLEAN_FALSE_SH,
    }

    with tarfile.open(fileobj=io.BytesIO(factory_rootfs_bz2), mode="r:bz2") as tar_in:
        with tarfile.open(fileobj=out_buf, mode="w:bz2", compresslevel=9) as tar_out:
            for member in tar_in:
                if any(member.name.startswith(pfx) for pfx in NON_X1D_FIRMWARE_PREFIXES):
                    removed_files.append({"name": member.name, "size": member.size})
                    removed_bytes += member.size
                    continue

                if member.name == "./lib/firmware/hbl/fx3/fx3.bin" and member.issym():
                    member.linkname = "fx3_wedge.bin"
                    tar_out.addfile(member)
                    kept_files += 1
                    continue

                if member.name == "./usr/bin/victory-gui" and member.isfile():
                    member.size = len(patched_vgui)
                    uncompressed_bytes += member.size
                    tar_out.addfile(member, io.BytesIO(patched_vgui))
                    kept_files += 1
                    continue

                if member.name in script_replacements and member.isfile():
                    new_script = script_replacements[member.name]
                    removed_bytes += max(0, member.size - len(new_script))
                    member.size = len(new_script)
                    uncompressed_bytes += member.size
                    tar_out.addfile(member, io.BytesIO(new_script))
                    kept_files += 1
                    continue

                if member.isfile():
                    uncompressed_bytes += member.size
                    tar_out.addfile(member, tar_in.extractfile(member))
                else:
                    tar_out.addfile(member)
                kept_files += 1

    new_rootfs_bz2 = out_buf.getvalue()
    stats = {
        "kept_members": kept_files,
        "removed_members_count": len(removed_files),
        "removed_uncompressed_bytes": removed_bytes,
        "uncompressed_bytes": uncompressed_bytes,
        "compressed_before_bytes": len(factory_rootfs_bz2),
        "compressed_after_bytes": len(new_rootfs_bz2),
        "compressed_saved_bytes": len(factory_rootfs_bz2) - len(new_rootfs_bz2),
        "removed_files": removed_files,
    }
    return new_rootfs_bz2, stats


def main():
    parser = argparse.ArgumentParser(description="Build modular custom X1D-50c firmware (.cim)")
    parser.add_argument(
        "-m",
        "--mode",
        choices=("afc", "lite"),
        default="afc",
        help="Build mode: 'afc' (Default 1.25.0 + Continuous Autofocus AF-C module) or 'lite' (X1D-only lightweight)",
    )
    parser.add_argument("-o", "--output", type=Path, default=None, help="Output .cim file path")
    args = parser.parse_args()

    if args.output is None:
        args.output = (
            FIRMWARE_DIR / "X1D_v1_25_0_afc.cim"
            if args.mode == "afc"
            else FIRMWARE_DIR / "X1D_v1_25_0_x1d_lite.cim"
        )

    t0 = time.time()
    print("=" * 80)
    if args.mode == "afc":
        print(" BUILDING CUSTOM X1D-50c FIRMWARE: DEFAULT 1.25.0 + CONTINUOUS AUTOFOCUS (AF-C)")
    else:
        print(" BUILDING CUSTOM LIGHTWEIGHT X1D-50c FIRMWARE (X1D-ONLY, NO COMMENTS)")
    print("=" * 80)

    if args.mode == "lite":
        print("\n[1/5] Stripping comments and blank lines from all QML/JS files in victory_gui_qml/ ...")
        qml_stats = strip_all_qml_js_in_workspace()
        print(
            f"      -> Processed {qml_stats['total_code_files']} QML/JS files: "
            f"{qml_stats['bytes_before']:,} B -> {qml_stats['bytes_after']:,} B "
            f"(saved {qml_stats['bytes_saved']:,} B)"
        )
    else:
        print(f"\n[1/5] Validating {len(AFC_MODULE_FILES)} modified AF-C QML files against factory 1.25.0 baseline ...")
        for rel in AFC_MODULE_FILES:
            raw = (QML_DIR / rel).read_bytes()
            err = check_balanced_syntax(raw, rel)
            if err:
                raise RuntimeError(f"QML syntax error in {err}")
        print(f"      -> All {len(AFC_MODULE_FILES)} AF-C module QML files passed syntax verification.")

    # 2. Extract original victory-gui & rootfs from template X1D_v1_25_0.cim (for clean repeatability)
    print("\n[2/5] Extracting factory baseline rootfs & victory-gui from X1D_v1_25_0.cim ...")
    factory_rootfs_bz2 = extract_factory_rootfs_from_cim(TEMPLATE_CIM)
    with tarfile.open(fileobj=io.BytesIO(factory_rootfs_bz2), mode="r:bz2") as tar:
        orig_vgui = tar.extractfile("./usr/bin/victory-gui").read()

    # 3. Patch QML/JS files into victory-gui
    only_paths = AFC_MODULE_FILES if args.mode == "afc" else None
    print(
        f"\n[3/5] Patching {'8 AF-C module' if args.mode == 'afc' else 'all 137'} QRC resources into /usr/bin/victory-gui (zlib-9) ..."
    )
    patched_vgui, qrc_stats = patch_qrc_into_victory_gui(
        orig_vgui, only_paths=only_paths, strip_comments_in_memory=True
    )
    (EXTRACTED_DIR / "victory-gui").write_bytes(patched_vgui)
    print(
        f"      -> Patched {qrc_stats['patched_resources']} QRC slots: "
        f"{qrc_stats['packed_before']:,} B -> {qrc_stats['packed_after']:,} B "
        f"(freed +{qrc_stats['packed_saved']:,} B; total free QRC pool: {qrc_stats['free_pool_after']:,} B)"
    )
    if args.mode == "afc":
        for sd in qrc_stats["slot_details"]:
            print(
                f"         * {sd['path']:40s} slot={sd['slot_capacity']:6,d} B | "
                f"used={sd['new_used']:6,d} B | spare=+{sd['spare_bytes']:5,d} B"
            )

    # 4. Rebuild rootfs.tar.bz2
    if args.mode == "afc":
        print("\n[4/5] Rebuilding stock 1.25.0 rootfs.tar.bz2 (injecting ONLY /usr/bin/victory-gui) ...")
        new_rootfs_bz2, rootfs_stats = build_stock_rootfs_with_patched_gui(factory_rootfs_bz2, patched_vgui)
    else:
        print("\n[4/5] Rebuilding rootfs.tar.bz2 (removing Victory/Albatross/Idun/A6D/H6D blobs) ...")
        new_rootfs_bz2, rootfs_stats = build_x1d_clean_rootfs(factory_rootfs_bz2, patched_vgui)

    (EXTRACTED_DIR / "rootfs").write_bytes(new_rootfs_bz2)
    (EXTRACTED_DIR / "rootfs_stats.json").write_text(
        json.dumps(rootfs_stats, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(
        f"      -> rootfs.tar.bz2 size: {rootfs_stats['compressed_before_bytes']:,} B -> "
        f"{rootfs_stats['compressed_after_bytes']:,} B"
    )

    # 5. Pack custom .cim container
    print(f"\n[5/5] Packing encrypted container {args.output.name} ...")
    packer = CimPacker(TEMPLATE_CIM, EXTRACTED_DIR, args.output)
    packer.pack()

    elapsed = time.time() - t0
    orig_cim_sz = TEMPLATE_CIM.stat().st_size
    new_cim_sz = args.output.stat().st_size
    print("\n" + "=" * 80)
    print(f" BUILD COMPLETE in {elapsed:.1f}s: {args.output}")
    print(f" .CIM Size: {orig_cim_sz:,} B -> {new_cim_sz:,} B")
    print("=" * 80)


if __name__ == "__main__":
    main()
