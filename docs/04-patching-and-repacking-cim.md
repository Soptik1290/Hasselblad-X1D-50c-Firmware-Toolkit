# 04 – Patching `victory-gui` QRC Resources & Repacking `.cim`

This document explains:
1. How QML/JS/PNG resources are stored and compressed inside the `/usr/bin/victory-gui` ELF binary (Qt Resource System) and how [`patch_victory_qrc_file.py`](../patch_victory_qrc_file.py) overwrites them in place.
2. How `/usr/bin/upgrade-daemon` parses the internal `.cim` container structures (`Cim::PublicHeader`, `Cim::PrivateHeader`, `Cim::ItemHeader`) and how [`hasselblad_pack.py`](../hasselblad_pack.py) repacks a valid `.cim` image.

---

## 1. Internal Qt Resource (`qrc://`) Layout in `victory-gui`

The `victory-gui` binary (`2,210,236` bytes in `v1.25.0`) embeds 3 standard **Qt Resource System** tables inside its `.rodata` section:

| Table | Offset in `victory-gui` | Size / Range | Purpose |
| :--- | :--- | :--- | :--- |
| **`DATA_BASE` (`qt_resource_data`)** | `0x0FC7F8` | `898,636` B (`0x0FC7F8` – `0x1D7E44`) | Raw or `zlib`-compressed payload of all 405 embedded files (QML, JS, PNG, TTF) |
| **`NAMES_BASE` (`qt_resource_name`)** | `0x1D7E44` | `18,860` B (`0x1D7E44` – `0x1DC7F0`) | UTF-16BE file and directory names (`[len 2B][hash 4B][UTF-16BE chars]`) |
| **`TREE_BASE` (`qt_resource_struct`)** | `0x1DC7F0` | `14` B per node | Directory hierarchy and file metadata nodes |

### `TREE_BASE` Node Format (14 bytes, Big-Endian)
Each node at `TREE_BASE + index * 14` has the following layout:
* `+0x00` (`4B`): `name_offset` – Offset into `NAMES_BASE`
* `+0x04` (`2B`): `flags` – Node flags:
  * `0x02` = Directory (followed by `a` = child count, `b` = first child index)
  * `0x01` = File compressed with **`zlib`** (`qCompress`)
  * `0x00` = Uncompressed file (e.g. pre-compressed PNG icons)
* `+0x06` (`4B`): `a` – Child count for directories, or locale/country flags for files
* `+0x0A` (`4B`): `b` (`data_offset`) – For files, the **byte offset relative to `DATA_BASE`**

### Compressed File Format at `DATA_BASE + data_offset` (`flags & 0x1`)
Qt stores `zlib`-compressed resources (with a `qCompress` header) as:
```text
[total block length N (4B Big-Endian)]
[uncompressed file size U (4B Big-Endian)]
[zlib stream (N - 4 bytes, starting with 0x78 0x9C or 0x78 0xDA)]
```
The total space occupied in `DATA_BASE` is `4 + N = 8 + len(zlib_stream)` bytes.

---

## 2. How In-Place Patching Works (`patch_victory_qrc_file.py`)

[`patch_victory_qrc_file.py`](../patch_victory_qrc_file.py) preserves all node offsets in `TREE_BASE`, leaving every other file and all ARM machine code in `victory-gui` untouched:

1. Walks `TREE_BASE` to locate the target resource path (e.g. `components/popups/PopoverFocusMode.qml`) and its `data_offset`.
2. Computes the available **slot size (`slot_size`)** as the difference between the target file's `data_offset` and the next higher `data_offset` in `DATA_BASE`.
3. Compresses the replacement file using maximum `zlib` compression (`zlib.compress(replacement, 9)`).
4. If `8 + len(compressed)` fits within `slot_size`:
   * Writes the new block length `4 + len(compressed)` (4B BE) and uncompressed length `len(replacement)` (4B BE).
   * Writes the new `zlib` stream.
   * Zero-fills any remaining slack bytes (`slot_size - needed`).

### Slot Headroom for Key QML/JS Files

Because the original firmware compiled QML resources using default `zlib` compression rather than level `9`, simply recompressing with level `9` immediately frees dozens to hundreds of bytes:

| Resource Path in `victory-gui` | Original Size | Slot Size | After `zlib` (Level 9) | Free Slack (Before Stripping Comments) |
| :--- | ---: | ---: | ---: | ---: |
| `common/TouchWindow.qml` | `100,512` B | `18,120` B | `17,822` B | **`+298` B** |
| `settings/SettingsGeneric.qml` | `59,881` B | `9,968` B | `9,741` B | **`+227` B** |
| `controlscreen/ControlScreen.qml` | `62,132` B | `8,157` B | `7,947` B | **`+210` B** |
| `main.qml` | `48,941` B | `8,676` B | `8,509` B | **`+167` B** |
| `settings/scripts/MenuItemSpecificationsWedge.js` | `42,105` B | `6,052` B | `6,026` B | **`+26` B** |
| `components/popups/PopoverFocusMode.qml` | `4,323` B | `1,184` B | `1,183` B | **`+1` B** |
| `DebugCam.qml` | `2,291` B | `670` B | `669` B | **`+1` B** |

> [!TIP]
> **How to gain even more space in any slot:**
> All QML and JS files in `victory-gui` contain extensive developer comments (`// ...`, `/* ... */`) and indentation whitespace. Removing a single comment line in `PopoverFocusMode.qml` or `MenuItemSpecificationsWedge.js` frees hundreds of bytes in the compressed slot for custom code.

### Example Usage of `patch_victory_qrc_file.py`
```powershell
python patch_victory_qrc_file.py `
  "X1D_v1_25_0_extracted\victory-gui" `
  "components/popups/PopoverFocusMode.qml" `
  "victory_gui_qml\components\popups\PopoverFocusMode.qml" `
  -o "X1D_v1_25_0_extracted\victory-gui-patched"
```

---

## 3. Detailed `.cim` Header Structures in `/usr/bin/upgrade-daemon`

By reverse-engineering `/usr/bin/upgrade-daemon` (`Cim::PublicHeader`, `Cim::PrivateHeader`, `Cim::ItemHeader`, and `Cim::EncryptedFileReader`), we reconstructed the exact binary layout of the `.cim` container:

### A) `Cim::PublicHeader` (`0x0000` – `0x007F`, `128` bytes, unencrypted)
* `0x00`..`0x39`: CRLF-delimited text lines (`File Id = VHABCIM`, `Part number = 1601254_PVF`, `Version = 255.255.255R`, `Generation date = 2020-10-22`, `Generation time = 10:23:09`).
* `0x3A`: `0x1A` (`EOF`).
* `0x3B`..`0x3E`: `00 00 00 00` (`Zero Padding`).
* `0x3F`: `0x03` (`CIM Format = 3`).
* `0x40`..`0x43`: `41 88 6A 34` (constant `isEncrypted` magic value across all encrypted `.cim` files).
* `0x44`..`0x47`: Total `.cim` file size in bytes (Big-Endian `uint32`, `0x03C79000` = `63,410,176` B for X1D v1.25.0).
* `0x48`..`0x7F`: `Zero padding` (`0x00`).

### B) `Cim::PrivateHeader` (`0x0080` – `0x01FF`, `384` bytes, encrypted with its own IV reset)
* `0x0080`..`0x008F`: `Identifier1..4` = `42 42 42 42 4E 41 52 47 45 47 41 48 3C C3 5A A5` (`"BBBBNARGEGAH"` + `0x3CC35AA5`; `NARGEGAH` spelled backwards is **`HAGEGRAN`**, the surname of the format's author at Hasselblad).
* `0x0090`..`0x009F`: **Private Header `Checksum` (16 bytes)** – Two-stage MD5 digest verified by `Cim::PrivateHeader::verifyChecksumFormat3()` (at address `0x2d6ac` in `/usr/bin/upgrade-daemon`, called from `Cim::PrivateHeader::read()` at `0x30170`):
  1. **Stage 1:** Compute a salted MD5 over all **encrypted** bytes from `0x0200` (start of the `ItemHeader` table) to the end of the `.cim` file (`EOF`):
     $$\text{hash}_1 = \text{MD5}(\text{encrypted\_bytes}[0\text{x}200:\text{EOF}] \parallel \text{MAGIC\_HASH\_SALT})$$
  2. **Stage 2:** Concatenate the 16 raw bytes of $\text{hash}_1$ with the decrypted `PrivateHeader` slice from offset `+0x20` to `+0x180` (`0x00A0`..`0x01FF` in the file, `352` bytes):
     $$\text{PrivateHeader::Checksum} = \text{MD5}(\text{hash}_1 \parallel \text{priv\_plain}[0\text{x}20:0\text{x}180])$$
  Verified with 100% accuracy across all 6 official firmware releases (`v1.20.0` to `v1.25.0`).
* `0x00A0`..`0x00A7`: `Build number` (`00 00 00 00 00 00 00 2A` = `42` in v1.25.0).
* `0x00A8`..`0x00AB`: Big-Endian Unix timestamp (`0x5F915D8D` = `2020-10-22 10:23:09 UTC`).
* `0x00AC`..`0x00BB`: `Generated by` (`"build2\0...\r\n"`).
* `0x00BC`..`0x00BF`: `Number of items` (`00 00 00 04`).
* `0x00C0`..`0x01FF`: `HW compatibility` & `Serial number` (`0x00`).

### C) `Cim::ItemHeader` (`0x0200` – `0x05FF`, `4 × 256` bytes, each encrypted with its own IV reset!)
`Cim::EncryptedFileReader` **resets the AES-CBC IV at the beginning of each `ItemHeader` block** (`0x0200`, `0x0300`, `0x0400`, `0x0500`). Once decrypted with the reset IV, each 256-byte `ItemHeader` has the following structure:
* `+0x00`..`+0x23`: `0x00` (`Board type`, `Build type`, `Status`, `Commited by` – unused / zeroed).
* `+0x24`..`+0x27`: `Offset` of the file in `.cim` (4B Big-Endian, aligned to `0x200`).
* `+0x28`..`+0x2B`: `Length` – exact uncompressed file size in bytes (4B Big-Endian).
* `+0x2C`..`+0x3B`: `Checksum` – 16B `MD5(file_contents + MAGIC_HASH_SALT)`.
* `+0x3C`..`+0x5F`: `0x00` (`HW compatibility`, `Bits reversed`).
* `+0x60`..`+0x7D`: `Image name` – null-padded ASCII filename (`hbl-upgrade`, `rootfs`, `uboot`, `hbl-kks-revisions`).
* `+0x7E`..`+0x7F`: `0D 0A` (`\r\n`).
* `+0x80`..`+0xFF`: `0x00` (`Commit ref`).

---

## 4. Repacking `.cim` (`hasselblad_pack.py`)

[`hasselblad_pack.py`](../hasselblad_pack.py) builds a new `.cim` container from a directory containing `hbl-upgrade`, `rootfs`, `uboot`, and `hbl-kks-revisions`:
1. Reads the `PublicHeader` (`0x00`..`0x7F`) and template `PrivateHeader` (`0x80`..`0x1FF`) from an original `.cim` file.
2. Computes the new size, aligned offset, and salted MD5 digest `MD5(data + MAGIC_HASH_SALT)` for each of the 4 files.
3. Builds and encrypts the 4 `Cim::ItemHeader` blocks (`0x200`..`0x5FF`).
4. Encrypts each payload file in 4096-byte chunks (resetting the IV every 4096 B) and updates the total file size in `PublicHeader` (`0x44`..`0x47`).
5. Computes the two-stage `PrivateHeader::Checksum` over all encrypted bytes `0x200..EOF`, writes it to `+0x10..+0x1F` of `PrivateHeader`, and writes the encrypted `PrivateHeader` to `0x80..0x1FF`.

```powershell
python hasselblad_pack.py `
  -t "firmware\X1D_v1_25_0.cim" `
  -i "X1D_v1_25_0_extracted" `
  -o "firmware\X1D_v1_25_0_custom.cim"
```
