# 02 – `.cim` Container Format & Firmware Update Process

## 1. Structure of the `.cim` (`VHABCIM`) Public Header

The first `128` bytes (`0x00`–`0x7F`) of `X1D_v1_25_0.cim` (total size `63,410,176` bytes = `0x03C79000`) form an unencrypted header:

```text
0000: 56 48 41 42 43 49 4d 0d 0a 31 36 30 31 32 35 34  VHABCIM..1601254
0010: 5f 50 56 46 0d 0a 32 35 35 2e 32 35 35 2e 32 35  _PVF..255.255.25
0020: 35 52 0d 0a 32 30 32 30 2d 31 30 2d 32 32 0d 0a  5R..2020-10-22..
0030: 31 30 3a 32 33 3a 30 39 0d 0a 1a 00 00 00 00 03  10:23:09........
0040: 41 88 6a 34 03 c7 90 00 00 00 00 00 00 00 00 00  A.j4............
```

### Header Field Breakdown:
1. **`VHABCIM\r\n`** – Magic string (*Victor Hasselblad AB Camera Image*).
2. **`1601254_PVF\r\n`** – Internal part number / firmware package identifier.
3. **`255.255.255R\r\n`** – Container version string.
4. **`2020-10-22\r\n`** – Build date (`YYYY-MM-DD`).
5. **`10:23:09\r\n`** – Build time (`HH:MM:SS`).
6. **`0x1A`** (offset `0x3A`) – End-of-text marker (DOS EOF).
7. **Offset `0x3F` (`03`)** – CIM container format version (`3`).
8. **Offset `0x40` (`41 88 6a 34`)** – Encryption magic flag (`isEncrypted`).
9. **Offset `0x44` (`03 c7 90 00`)** – Total file size in Big-Endian (`0x03C79000` = `63,410,176` bytes).

---

## 2. Cryptographic Scheme of the `.cim` Container

From offset `0x80` to the end of the file, the payload has an entropy of `7.999997` bits/byte and is encrypted using **AES-128-CBC**.

### Cryptographic Constants (see [`hasselblad_extract.py`](../hasselblad_extract.py) and [`hasselblad_pack.py`](../hasselblad_pack.py))

* **Static AES-128 Key (16 bytes):**
  ```text
  93 F8 2C A2 44 AB 29 E0 36 69 34 D5 67 13 EE A2
  ```
* **IV Derivation Salt (`IV_SALT`, 16 bytes):**
  ```text
  E6 36 FA DC 3D 99 2D 07 05 FD 95 8E 82 E3 14 7A
  ```
* **Integrity Hash Salt (`MAGIC_HASH_SALT`, 16 bytes):**
  ```text
  CD 87 D7 27 FA 5E E7 F9 5D 43 E2 C4 9E 90 D7 0B
  ```

### Initialization Vector (IV) Derivation
A 16-byte buffer `time_buf` is constructed from the ASCII date and time in the public header (`2020-10-22` and `10:23:09`):
* `time_buf[0] = year // 100` (`20`)
* `time_buf[1] = year % 100` (`20`)
* `time_buf[2] = month` (`10`)
* `time_buf[3] = day` (`22`)
* `time_buf[4] = hour` (`10`)
* `time_buf[5] = minute` (`23`)
* `time_buf[6] = second` (`9`)
* `time_buf[7..15] = 0x00`

The AES-CBC IV is computed as:
$$\text{IV} = \text{MD5}(\text{IV\_SALT} \parallel \text{time\_buf})$$
For `X1D_v1_25_0.cim`, the derived IV is:
```text
74d898a2302518ee02bd6e2e76637206
```

### 4096-Byte Chunked AES-CBC Decryption
A critical detail of the `.cim` format is that AES-CBC cipher state does not chain continuously across the entire file:
1. At the start of the private header (`0x80`), at the start of each `ItemHeader` (`0x200`, `0x300`, `0x400`, `0x500`), and at the start of each embedded file, AES-128-CBC is initialized with `STATIC_KEY` and the derived `IV`.
2. **Every `4096` bytes (`0x1000`), the AES-CBC `IV` is reset back to the original derived `IV`!**

### Integrity Verification (Salted MD5 & Two-Stage `PrivateHeader::Checksum`)
A `.cim` file contains two independent levels of integrity verification checked by `/usr/bin/upgrade-daemon` prior to installation:

1. **Two-Stage `PrivateHeader::Checksum` (file offset `0x90..0x9F`, i.e. `+0x10..+0x1F` in the decrypted private header):**
   * The function `Cim::PrivateHeader::verifyChecksumFormat3()` (at address `0x2d6ac` in `/usr/bin/upgrade-daemon`, called from `Cim::PrivateHeader::read()` at `0x30170`) computes this 16-byte MD5 digest in two stages:
     * **Stage 1:** Compute the MD5 over all **encrypted** bytes from offset `0x200` (start of the `ItemHeader` table) to the end of the `.cim` file (`EOF`), followed by the 16-byte `MAGIC_HASH_SALT`:
       $$\text{Hash}_1 = \text{MD5}(\text{Encrypted\_Bytes}[0\text{x}200:\text{EOF}] \parallel \text{MAGIC\_HASH\_SALT})$$
     * **Stage 2:** Concatenate the 16 raw bytes of $\text{Hash}_1$ with the decrypted remainder of the private header from `+0x20` to `+0x180` (`352` bytes containing the build number, timestamp, item count, and target metadata) and compute the final MD5:
       $$\text{PrivateHeader::Checksum} = \text{MD5}(\text{Hash}_1 \parallel \text{Decrypted\_PrivateHeader}[0\text{x}20:0\text{x}180])$$
   * We verified this exact formula against all **6 official firmware releases** (`v1.20.0` through `v1.25.0`) with a 100% match.

2. **Per-Item Integrity Check (`ItemHeader` at `0x200..0x5FF`):**
   * Each of the 4 file table records (`0x100` bytes per entry, encrypted independently with the initial `IV`) stores at offset `+0x24`:
     * `Offset` (4B Big-Endian)
     * `Size` (4B Big-Endian)
     * `Expected_Hash` (16B MD5)
     * Zero padding + ASCII filename at `+0x60` terminated with `\r\n` at `+0x7E..+0x7F`
   * Each extracted file's integrity is verified using:
     $$\text{Hash} = \text{MD5}(\text{Decrypted\_Content} \parallel \text{MAGIC\_HASH\_SALT})$$

> [!NOTE]
> Because the 1st-generation `.cim` container relies on symmetric encryption and salted MD5 hashes without asymmetric signatures (RSA/ECDSA), [`hasselblad_pack.py`](../hasselblad_pack.py) can repack modified firmware components into a 100% valid `.cim` container that passes every check in `upgrade-daemon`.

---

## 3. Files Extracted from `X1D_v1_25_0.cim`

| Filename | Offset in `.cim` | Size (Bytes) | MD5 Check | Description |
| :--- | :--- | ---: | :---: | :--- |
| **`hbl-upgrade`** | `0x00000600` | `7,783` | `OK` | Main `/bin/sh` upgrade script executed by `upgrade-daemon` |
| **`rootfs`** | `0x00002600` | `63,123,278` | `OK` | `bzip2`-compressed `tar` archive (`rootfs.tar.bz2`) of the entire Linux rootfs |
| **`uboot`** | `0x03C35600` | `269,312` | `OK` | U-Boot bootloader with i.MX6 IVT header (`d1 00 20 40...`) |
| **`hbl-kks-revisions`** | `0x03C77400` | `7,030` | `OK` | Helper script mapping KKS board revisions to `.dtb` files |

---

## 4. Step-by-Step Firmware Update Flow on the Camera

1. **Triggering the Upgrade (`upgrade-daemon`):**
   * When the user confirms an update from the SD card in **Service → Check for Update**, the GUI invokes the D-Bus method `com.hasselblad.upgrade.Upgrade` (see `upgrade_from_slot.sh`).
   * `upgrade-daemon` verifies and decrypts the `.cim` file into `/media/data/upgrade/` and executes `./hbl-upgrade`.
2. **Preparing the Inactive A/B Slot (`hbl-upgrade`):**
   * Reads the currently active boot slot via `fw_printenv -n current_bootpart`.
   * If running from Slot A (`current_bootpart == 1`), Slot B (`/dev/mmcblk3p3` + `/dev/mmcblk3p4`) becomes the target, and vice versa.
   * Formats the target root partition as `ext4` without a journal (`mkfs.ext4 -E nodiscard` + `tune2fs -O ^has_journal`) and the target boot partition as `FAT32`.
3. **Unpacking `rootfs` & Kernel (`update_imx`):**
   * Extracts `rootfs` (`bzcat rootfs | tar xf - -C root_mnt`).
   * Copies the `zImage` kernel and uses `hbl-kks-revisions` to copy `.dtb` files under filenames matching hardware KKS numbers (e.g. `/boot/0x5f701d1b` for X1D Rev 3) so U-Boot can load the DTB directly from the OTP register value.
   * Verifies that a matching `.dtb` file exists in `/boot` for the current camera's `/sys/fsl_otp/HW_OCOTP_GP1`.
   * Preserves `/etc/machine-id` from the old rootfs.
4. **Updating Subordinate Coprocessors (`program_nodes.sh`):**
   * Sequentially flashes:
     * `update_farm` (20% progress) – FPGA images `bootimage_even-wedge.bin` and `bootimage_odd-wedge.bin`
     * `update_spc` (40% progress) – `power-control.bin`
     * `update_fx3` (60% progress) – USB 3.0 controller `fx3_wedge.bin`
     * `update_touch` – Atmel mXT touchscreen controller configuration
     * `check_rtc` – Real-time clock check (`/dev/rtc1`)
     * `update_suc` (80% progress) – System microcontroller `camera-control.bin` (requires USB cable to be **disconnected**!)
5. **Switching Boot Slots (`hbl-upgrade` + `hbl-post-upgrade`):**
   * Sets U-Boot environment variables `emmcboot` and `upgrade=1`.
   * After reboot, `/usr/bin/hbl-post-upgrade` updates `current_bootpart` (`1 <-> 3`) in SPI NOR flash (`spi_imx` / `m25p80`) and cleans up `/media/data/upgrade`.
