# Hasselblad X1D-50c (1st Gen) – Firmware Research, Modding Toolkit & UI Simulator

[![Platform](https://img.shields.io/badge/Platform-Hasselblad%20Umbrella%202.0.3%20(NXP%20i.MX6Quad)-blue)](#architecture--hardware-highlights)
[![Firmware](https://img.shields.io/badge/Firmware-v1.20.0%20–%20v1.25.0%20(.cim)-success)](#documentation-docs)
[![UI](https://img.shields.io/badge/UI-Qt%205.5.1%20%2F%20QML%20%2B%20640×480%20PC%20Simulator-orange)](#quickstart--tools)

> 🇨🇿 **Česká verze dokumentace:** Kompletní dokumentaci v češtině najdete v [`README.cs.md`](README.cs.md) a ve složce [`dokumentace/`](dokumentace/).

A comprehensive reverse-engineering research repository, `.cim` decryption/repacking toolkit, in-place Qt Resource (`qrc://`) patcher, and interactive **640×480 PC UI Simulator** for the 1st-generation **Hasselblad X1D-50c** medium-format mirrorless camera (internal codename **`Wedge`**, running *Hasselblad Umbrella Distro 2.0.3* on NXP i.MX6Quad).

While newer Hasselblad cameras (`X1D II 50C`, `X2D 100C`, `907X 100C`) switched to an Android/OTA-based architecture, the original **X1D-50c** shares a unified embedded Yocto Linux + Wayland/Weston + Qt 5.5.1/QML platform with the **H6D-50c (`Victory`)**, **H6D-100c (`Albatross`)**, **A6D**, and **CFV II 50C / 907X (`Idun`)**.

---

## Key Discoveries & Highlights

* **Complete `.cim` (`VHABCIM`) Container Decryption & Repacking:**
  * Documented the chunked **AES-128-CBC** encryption scheme (4096-byte IV reset), timestamp-based IV derivation, salted MD5 item hashes, and reverse-engineered the **two-stage `PrivateHeader::Checksum` algorithm** (`Cim::PrivateHeader::verifyChecksumFormat3` at `0x2d6ac` in `upgrade-daemon`), verified with a **100% match across all 6 official firmware releases (`v1.20.0` – `v1.25.0`)**.
* **Built-In Secret Service Menu (Works Out-of-the-Box Without Modding!):**
  * Navigating to **Menu → General Settings → About** and repeatedly tapping **`Firmware: 1.25.0`** triggers `guiconfig.wantToSeeFWUpdateRetryClicked()`, sets `guiconfig.showSecretMenuItems = true`, and unlocks **Deactivate Storage (RAM-only capture)**, **Firmware Update Retry**, and **Scroll Wheel Handling (`Original` / `Adjusted`)** in the **Service** menu.
* **C++ Backend Audit of Hidden `demo: true` Features:**
  * Cross-referenced all 405 extracted QML/JS/PNG assets from `/usr/bin/victory-gui` against `/usr/bin/configstore`, `/usr/bin/msg2dbus`, `/usr/bin/camera-daemon` (`WedgeStateMachine`), `/usr/bin/bodystate-daemon`, and `/usr/bin/storage-daemon` to prove which hidden QML features are **100% wired and functional on real X1D-50c hardware**:
    * Custom button remapping for **`AE-L`** and **`AF-D`** (all 33 actions in `bodystate-daemon`).
    * **`Front Wheel in M`** (swap front/rear command dials in Manual mode).
    * **`Hide B/T Mode`** & **`AE-L when Half-pressed`**.
    * **`Eye Sensor Distance`** (`Short` / `Medium` / `Long` EVF proximity threshold).
    * **Engineering Autofocus Tuning:** custom XCD lens AF stepping motor speed (**`7000`–`31000`**, `af_cmd_speed`), FPGA Brenner contrast metric weighting (**`x+y`**, **`x+y/4`**, **`x+y/2`**), FIR contrast curve filtering (`af_fir`), full-range AF sweep (`af_full_scan`), and AF sequence logging (`af_log`).
* **Local 640×480 PC UI Simulator (`ui_simulator/`):**
  * Runs the live extracted `MenuItemSpecificationsWedge.js` menu definitions, original `HelveticaNeueLTStd` OTF fonts, and all 267 PNG icons in your browser at native `640×480` resolution—complete with a live `zlib` (level 9) QRC slot-headroom calculator and C++ backend X-ray inspector.

---

## Repository Structure

```text
X1D_FirmwareDump/
├── README.md                              # English project overview & documentation index
├── README.cs.md                           # Czech project overview (Český rozcestník)
├── hasselblad_extract.py                  # Decrypts and unpacks .cim firmware containers
├── hasselblad_pack.py                     # Repacks & encrypts .cim containers (with two-stage PrivateHeader checksum)
├── extract_victory_qrc.py                 # Extracts all 405 Qt/QML resources from /usr/bin/victory-gui
├── patch_victory_qrc_file.py              # In-place QRC patcher (zlib level 9) for /usr/bin/victory-gui
├── ui_simulator/                          # Interactive 640×480 PC UI Simulator & QRC Slot Inspector
│   ├── run_simulator.py                   # Local HTTP server serving live QML/JS & icons from victory_gui_qml/
│   ├── index.html                         # 640×480 X1D touchscreen & physical button/wheel simulator
│   └── fonts/                             # Original HelveticaNeueLTStd OTF fonts from rootfs
├── docs/                                  # Complete English Technical Documentation
│   ├── 01-architecture-and-hardware.md    # i.MX6Q hardware, coprocessors (FARM, SUC, FX3, SPC), Umbrella distro
│   ├── 02-cim-format-and-update-process.md# VHABCIM AES-128-CBC crypto, two-stage checksum & A/B update flow
│   ├── 03-gui-qml-and-hidden-features.md  # victory-gui QML architecture, Easter Egg & hidden demo:true options
│   ├── 04-patching-and-repacking-cim.md   # Qt Resource binary format, in-place patching & .cim header specs
│   ├── 05-cpp-backend-and-feature-analysis.md # Deep C++ daemon analysis (what actually works on X1D hardware)
│   ├── 06-pc-ui-emulation.md              # Local PC UI simulator, hidden victory-gui CLI flags & QEMU setup
│   └── 07-firmware-version-comparison.md  # Full comparison across all 6 releases (v1.20.0 to v1.25.0)
├── dokumentace/                           # Complete Czech Technical Documentation (Česká dokumentace)
│   ├── 01-architektura-a-hardware.md
│   ├── 02-format-cim-a-aktualizace.md
│   ├── 03-gui-qml-a-skryte-funkce.md
│   ├── 04-patchovani-a-baleni-cim.md
│   ├── 05-analyza-cpp-backendu-a-funkci.md
│   ├── 06-emulace-ui-na-pc.md
│   └── 07-porovnani-verzi-firmwaru.md
├── victory_gui_qml/                       # 405 extracted UI assets from victory-gui (128 QML, 9 JS, 267 PNG, 1 TTF)
└── firmware/                              # Place official X1D_v1_*.cim files here (ignored by git)
```

---

## Documentation (`docs/`)

1. **[01 – Architecture & Hardware (`docs/01-architecture-and-hardware.md`)](docs/01-architecture-and-hardware.md)**
   * Architectural comparison between the 1st-gen X1D-50c (Yocto Linux on NXP i.MX6Quad) and 2nd-gen X1D II / X2D / 907X 100C (Android/OTA).
   * The unified **Hasselblad Umbrella Distro 2.0.3** and internal model codenames (`Wedge` = X1D-50c, `Victory` = H6D-50c, `Albatross` = H6D-100c / A6D, `Idun` = 907X / CFV II 50C).
   * Subordinate hardware coprocessors (`FARM` FPGA, `FX3` USB 3.0, `SUC` STM32 microcontroller, `SPC` sensor power controller), eMMC A/B partition layout, and `systemd` services.
2. **[02 – `.cim` Container Format & Firmware Update Process (`docs/02-cim-format-and-update-process.md`)](docs/02-cim-format-and-update-process.md)**
   * Binary layout of the `VHABCIM` header, static AES-128-CBC key, timestamp IV derivation, 4096-byte chunked IV reset, salted MD5 hashes, and the two-stage `PrivateHeader::Checksum` formula.
   * Step-by-step walkthrough of `hbl-upgrade`, `program_nodes.sh`, and `hbl-post-upgrade`.
3. **[03 – Graphical User Interface (`victory-gui`), QML & Hidden Features (`docs/03-gui-qml-and-hidden-features.md`)](docs/03-gui-qml-and-hidden-features.md)**
   * Wayland/Weston and Qt 5.5.1 / QML architecture inside `/usr/bin/victory-gui`.
   * How to unlock the built-in **Service Menu Easter Egg** on a stock camera.
   * Complete catalog of hidden `demo: true` menu items in `MenuItemSpecificationsWedge.js` and RAW sensor calibration modes in `DebugCam.qml`.
4. **[04 – Patching `victory-gui` QRC Resources & Repacking `.cim` (`docs/04-patching-and-repacking-cim.md`)](docs/04-patching-and-repacking-cim.md)**
   * Internal structure of the Qt Resource tables (`DATA_BASE`, `NAMES_BASE`, `TREE_BASE`) in `victory-gui` and how in-place `zlib` (level 9) patching works.
   * Reverse-engineered C++ structures (`Cim::PublicHeader`, `Cim::PrivateHeader`, `Cim::ItemHeader`) from `/usr/bin/upgrade-daemon`.
5. **[05 – Deep Analysis of the C++ Backend & Hidden Features (`docs/05-cpp-backend-and-feature-analysis.md`)](docs/05-cpp-backend-and-feature-analysis.md)**
   * End-to-end property flow across `victory-gui` (`SettingsMiddleLayer`), `configstore`, `msg2dbus`, `bodystate-daemon`, `camera-daemon` (`WedgeStateMachine`), and `storage-daemon`.
   * Full support matrix showing which hidden features work on real X1D-50c hardware and disassembly proof (`WedgeStateMachine::checkFocusMode` at `0x32860`) of why `AF-C` and `True Focus` fall back to `AF-S`.
6. **[06 – PC UI Emulation & Safe Off-Camera Testing (`docs/06-pc-ui-emulation.md`)](docs/06-pc-ui-emulation.md)**
   * Guide to the local 640×480 PC UI Simulator (`ui_simulator/run_simulator.py`), hidden command-line flags in `victory-gui` (`--wedge`, `--session`, `--main`), and full ARM emulation in QEMU.
7. **[07 – Comparison Across All 6 Firmware Releases (`docs/07-firmware-version-comparison.md`)](docs/07-firmware-version-comparison.md)**
   * Detailed comparison of `v1.20.0`, `v1.20.1`, `v1.21.0`, `v1.22.0`, `v1.24.0`, and `v1.25.0`: container hashes, coprocessor firmware versions, kernel revisions, and feature additions (ALSA/TFA9882 audio feedback in `v1.21.0`, Focus Bracketing in `v1.22.0`, 4 µm XCD lens stepping in `v1.24.0`).

---

## Quickstart & Tools

### 1. Launch the Interactive 640×480 PC UI Simulator
```powershell
python ui_simulator/run_simulator.py
```
Opens `http://127.0.0.1:8125/` in your browser with the live X1D-50c menu, physical button/dial controls, C++ backend inspector, and QRC slot size calculator.

### 2. Decrypt & Extract a `.cim` Firmware Image
```powershell
python hasselblad_extract.py "firmware/X1D_v1_25_0.cim" -o "X1D_v1_25_0_extracted"
```

### 3. Extract Qt/QML/JS/PNG Resources from `victory-gui`
```powershell
python extract_victory_qrc.py "X1D_v1_25_0_extracted/victory-gui" -o "victory_gui_qml"
```

### 4. Patch a Modified QML/JS File Back into `victory-gui`
```powershell
python patch_victory_qrc_file.py `
  "X1D_v1_25_0_extracted/victory-gui" `
  "settings/scripts/MenuItemSpecificationsWedge.js" `
  "victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js" `
  -o "X1D_v1_25_0_extracted/victory-gui.patched"
```

### 5. Repack & Encrypt a Custom `.cim` Firmware Container
```powershell
python hasselblad_pack.py `
  -t "firmware/X1D_v1_25_0.cim" `
  -i "X1D_v1_25_0_extracted" `
  -o "firmware/X1D_v1_25_0_custom.cim"
```

---

## Related Projects & Acknowledgements

### 1st-Generation X1D-50c / Umbrella Platform
* **[YuHaoyua/hasselblad-x1d-reverse-engineering](https://github.com/YuHaoyua/hasselblad-x1d-reverse-engineering)** – Foundational reverse-engineering research on the 1st-gen X1D-50c (D-Bus APIs, `sutest-daemon` protocol, USB shell access, QEMU emulation, and QRC resource patching).
* **[YuHaoyua/hasselblad-cim-firmware-extractor](https://github.com/YuHaoyua/hasselblad-cim-firmware-extractor)** – Decryption and extraction tool for Hasselblad `.cim` firmware containers.

### Newer Generations (X1D II / X2D / 907X 100C – Android/OTA Platform)
* **[derrickyau9/Hasselblad_X1D_II_FirmwareDump](https://github.com/derrickyau9/Hasselblad_X1D_II_FirmwareDump)** – Extracted Android OTA firmware dump from the 2nd-gen X1D II 50C.
* **[Gothenburg-R-D-Team/x2d-907-one-click-extension-toolkit](https://github.com/Gothenburg-R-D-Team/x2d-907-one-click-extension-toolkit)** – One-click extension toolkit for the X2D 100C and 907X / CFV 100C.
* **[derrickyau9/Hasselblad-X-System-QEMU-DevKit](https://github.com/derrickyau9/Hasselblad-X-System-QEMU-DevKit)** – QEMU development kit for newer Android-based X-System firmware.

---

## Disclaimer

This repository is intended strictly for educational, interoperability, and personal hardware research purposes. Always test UI modifications in the local PC simulator (`ui_simulator/run_simulator.py`) or by running `victory-gui` temporarily from `/media/data/victory-gui` before flashing any custom `.cim` image to your camera.
