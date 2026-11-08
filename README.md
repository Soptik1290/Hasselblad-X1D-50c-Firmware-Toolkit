# Hasselblad X1D-50c (1st Gen) – Firmware Research, Modding Toolkit & UI Simulator

[![Platform](https://img.shields.io/badge/Platform-Hasselblad%20Umbrella%202.0.3%20(NXP%20i.MX6Quad)-blue)](#architecture--hardware-highlights)
[![Firmware](https://img.shields.io/badge/Firmware-v1.20.0%20–%20v1.25.0%20(.cim)-success)](#documentation-docs)
[![UI](https://img.shields.io/badge/UI-Qt%205.5.1%20%2F%20QML%20%2B%20640×480%20PC%20Simulator-orange)](#quickstart--tools)
[![Roadmap](https://img.shields.io/badge/Roadmap-Active%20Development-purple)](#️-roadmap--feature-progress)

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
    * **Engineering Autofocus Tuning:** custom XCD lens AF stepping motor speed (**`7000`–`19000`** dropdown / max **`20000`** enforced by `/usr/bin/configstore` at `0x13d68`, `af_cmd_speed`), FPGA Brenner contrast metric weighting (**`x+y`**, **`x+y/4`**, **`x+y/2`**), FIR contrast curve filtering (`af_fir`), full-range AF sweep (`af_full_scan`), and AF sequence logging (`af_log`).
* **Custom Firmware Modules (`build_custom_firmware.py`, `custom_firmware_docs/` / `custom_firmware_dokumentace/`):**
  * **Continuous Autofocus (`AF-C` + Touch-to-Track, `--mode afc`):** Standalone QML patch built directly on top of stock `v1.25.0` (`X1D_v1_25_0_afc.cim`, `63,270,912 B`) that unlocks `Continuous Focus` (`Config.Focus_AFC = 2`), accelerates the XCD stepping motor (`DebugAfSpeed = 19000`), and drives the lens with a closed-loop **5-state Gated CDAF + Left/Right Peak Drop Rate** controller over `Lens.moveRelativePos4um` 4 µm micro-steps (zero hunting while in focus), with single-tap **Touch-to-Track** and instant full-shutter priority. The earlier session-cycling prototype (which causes full-sweep hunting on real hardware because every `image_find_focus_req` in the `FARM` `af_service.c` runs a blind two-edge sweep) is archived as `X1D_v1_25_0_afc_old.cim`. *Verified in the ARMv7 emulator with a physics-based contrast simulator only – not yet on real hardware.*
  * **`FARM` (Xilinx Zynq-7000) Dual-QSPI De-Interleaving:** Reconstructed the `FARM` boot image from the bit-interleaved `bootimage_even/odd-wedge` files (FSBL + FPGA bitstream + FreeRTOS `farm_app.bin`) and reverse-engineered `../src/services/af_service.c`.
  * **X1D-Only Lite Edition (`--mode lite`):** Strips QML/JS comments and non-X1D (`H6D`/`A6D`/`CFV`) branches & assets (`X1D_v1_25_0_x1d_lite.cim`), freeing **+78.4 KB** in `victory-gui`'s QRC pool and **−26.1 MB** on eMMC `rootfs`.
* **Local 640×480 PC UI Simulator & Direct `.cim` Bootloader (`ui_simulator/`, `cim_emulator_loader.py`):**
  * Dynamically decrypts, unpacks, and boots **any `.cim` firmware image (`v1.20.0` – `v1.25.0` or custom repacked `.cim`)** on Windows in seconds—auto-detecting QRC table offsets across compiler builds and running the live `MenuItemSpecificationsWedge.js` menu definitions, original `HelveticaNeueLTStd` OTF fonts, and all 267 PNG icons at native `640×480` resolution.
* **5-Stage Anti-Brick Pre-Flight Sweep & Memory Counter (`verify_firmware_safety.py`):**
  * Verifies QML/JS syntax, Qt 5.4 uppercase C++ signal connection guards (`QQmlConnectionsParser`), `/usr/bin/configstore` parameter range limits (`DebugAfSpeed` `3000..20000`), Wayland dual-window focus guards (`TouchWindow` vs. `EVFWindow`), QRC slot capacity (with automatic comment-stripping that frees **+58.9 KB to +78.4 KB** of compressed space), ELF/QRC round-trip decompression, U-Boot A/B dual-slot rollback protection, `rootfs` boot symlinks (`readlink`), and two-stage `.cim` checksums before any firmware touches the camera.
* **Full ARMv7 Linux Rootfs Emulator with Live Graphics & Telemetry (`run_arm_emulator.py`, `arm_emulator/`):**
  * Boots the extracted ARMv7 `rootfs.tar.bz2` environment inside an `arm32v7` Docker/QEMU container, running the **real unmodified `/usr/bin/victory-gui` (Qt5 QML)** binary alongside the native `/usr/bin/configstore` daemon.
  * Bridges physical Vivante GC2000 GPU (`/dev/galcore`) to **Mesa Software OpenGL ES 2.0 (LLVMpipe / swrast)** and Wayland-EGL using three custom compatibility shims (`libxshmfence_compat.c`, `libbsd_compat.c`, `patch_libm.py`) solving Yocto GLIBC 2.22 limitations without breaking the rootfs.
  * Fully interactive via browser over noVNC (`http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale`): touch/click aperture `f/2.8`, shutter speed `125`, `ISO 100` to open popovers; press `F1` for the 9-tile Main Menu; press `1`–`6` for mode dial; press arrows for scroll wheels; with live D-Bus telemetry (`Ev 10.0`, `95%` battery, dual SD card slots).

---

## 🗺️ Roadmap & Feature Progress

Overview of upcoming features, community collaborations, and current modding milestones for the Hasselblad X1D-50c custom firmware:

| # | Feature | Status | Progress | Highlights & Target |
| :-: | :--- | :--- | :---: | :--- |
| **1** | **Continuous Autofocus (`AF-C` & Touch-to-Track)** | 🟡 **Ready for Testing** | `[█████████░] 90%` | Custom 5-state Gated CDAF closed-loop controller using `Lens.moveRelativePos4um` micro-stepping in `X1D_v1_25_0_afc.cim`. Verified in ARMv7 emulator; ready for live testing on physical X1D hardware with XCD lenses. |
| **2** | **Film Emulation & Color Profiles (Hazel / Haxel)** | 🟠 **In Active Development** | `[████░░░░░░] 45%` | Collaboration with **[@duart38](https://github.com/duart38)** (**[Hazel-firmware](https://github.com/duart38/Hazel-firmware)** / *Haxel*). Integrating custom 3D LUTs, film simulation recipes (Portra, Tri-X, Provia), and in-camera preview rendering into the UI. |
| **3** | **Double Exposure (Multi-Exposure Mode)** | 🔵 **In Design & Architecture** | `[██░░░░░░░░] 20%` | Multi-frame composite capture on the 50MP medium-format sensor with real-time ghosted Live View overlay (EVF & rear LCD) and selectable blend modes (Additive, Average, Lighten/Darken). |
| **4** | **Phocus Mobile 2 Connectivity / Custom Mobile App** | 🟣 **Research & Prototyping** | `[█░░░░░░░░░] 15%` | Reverse-engineering Phocus Mobile 2 Wi-Fi / WebSocket protocols, or creating a lightweight cross-platform mobile companion app (remote shutter trigger, Live View streaming & RAW/JPEG download). |

### Feature Details & Milestones

#### 1. 🎯 Continuous Autofocus (`AF-C` & Touch-to-Track) – *Almost Complete / Ready for Hardware Testing*
* **Status:** **~90%** – Implemented as a standalone patch module on top of stock firmware `v1.25.0` (`firmware/X1D_v1_25_0_afc.cim`, `63,270,912 B`).
* **Technical Architecture:** Replaces the camera's stock blind two-edge sweep (`af_service.c` in `FARM` FPGA) that caused severe hunting. Implements a closed-loop 5-state Gated CDAF state machine (`IDLE` → `POLL` → `TRACK` → `CONVERGED` → `RECOVERY`) directly driving the XCD lens stepping motor via `Lens.moveRelativePos4um` 4 µm micro-steps (zero hunting once locked), single-tap **Touch-to-Track**, and instant full-shutter priority. Fully validated in the ARMv7 Linux container emulator with a physics-based contrast simulator.
* **Next Step:** Flashing to a physical X1D-50c camera body and conducting real-world optical testing with physical XCD lenses to calibrate deadzone thresholds and step speed settings.

#### 2. 🎞️ Film Emulation & Custom Color Profiles (Hazel / Haxel Collaboration)
* **Status:** **~45%** – Active cross-project collaboration with **[@duart38](https://github.com/duart38)** (**[Hazel-firmware](https://github.com/duart38/Hazel-firmware)** / *Haxel*).
* **Technical Architecture:** Developing in-camera 3D LUT support and film stock profiles to bring classic analog aesthetics (Kodak Portra 160/400, Kodak Tri-X 400, Fujifilm Provia/Velvia, and monochrome film toning) directly into the X1D-50c live preview and JPEG processing engine, paired with custom DNG color profiles.
* **Next Step:** Implementing the QML profile selector in `victory-gui` and testing live preview LUT transformation shaders.

#### 3. 📸 Double Exposure (Multi-Exposure Mode)
* **Status:** **~20%** – UI workflow and image buffer architecture in design.
* **Technical Architecture:** Bringing creative multiple exposure capabilities to medium-format shooting. The camera will retain the first exposure in memory and render a live semi-transparent (ghosted) overlay on the rear LCD and EVF during Live View, allowing the photographer to accurately frame subsequent shots.
* **Planned Features:** Configurable blend algorithms (Additive, Average, Screen, Darken, Lighten) and the option to save both individual unmerged RAW exposures and the composite image.
* **Next Step:** Prototyping the QML overlay component in `victory-gui` and validating raw buffer combination routines.

#### 4. 📱 Modern Wireless Connectivity: Phocus Mobile 2 or Custom Mobile App
* **Status:** **~15%** – Protocol analysis & architecture definition.
* **Technical Architecture:** The 1st-generation X1D-50c includes built-in 802.11a/b/g/n Wi-Fi hardware, but the official original "Phocus Mobile" app is outdated and largely unusable on modern iOS/Android versions, while "Phocus Mobile 2" officially dropped support for 1st-gen cameras.
  * **Option A (Phocus Mobile 2 Protocol Bridge):** Reverse-engineer the network and D-Bus protocol used by Phocus Mobile 2 (on X1D II / X2D) and implement a lightweight bridging service on the X1D-50c so users can connect directly with the official Phocus Mobile 2 app on iPad/iPhone/Android.
  * **Option B (Custom Mobile Companion App / Web PWA):** Build a dedicated lightweight open-source mobile client or responsive local Web UI (hosted directly on the camera's Linux system) providing wireless remote trigger, Live View streaming, camera parameter adjustment (aperture, shutter, ISO), and direct wireless RAW/JPEG offload.
* **Next Step:** Packet analysis of Phocus Mobile 2 Wi-Fi traffic and mapping camera daemon network sockets.

---

## Repository Structure

```text
X1D_FirmwareDump/
├── README.md                              # English project overview & documentation index
├── README.cs.md                           # Czech project overview (Český rozcestník)
├── hasselblad_extract.py                  # Decrypts and unpacks .cim firmware containers
├── hasselblad_pack.py                     # Repacks & encrypts .cim containers (with two-stage PrivateHeader checksum)
├── extract_victory_qrc.py                 # Extracts all 405 Qt/QML resources from /usr/bin/victory-gui
├── patch_victory_qrc_file.py              # In-place QRC patcher (zlib level 9 + optional comment stripper)
├── build_custom_firmware.py               # Modular Custom Firmware Builder (--mode afc / --mode lite)
├── verify_firmware_safety.py              # 5-Stage Anti-Brick Pre-Flight Test Sweep & Memory Counter
├── cim_emulator_loader.py                 # Direct .cim Firmware Unpacker & Bootloader for Windows / WebUI
├── run_arm_emulator.py                    # One-click launcher for the ARMv7 Docker/QEMU Linux Rootfs Emulator
├── custom_firmware_docs/                  # Complete English Custom Firmware & Builder Specifications
├── custom_firmware_dokumentace/           # Complete Czech Custom Firmware & Builder Specifications
├── arm_emulator/                          # ARMv7 Linux container setup (D-Bus, configstore, Weston, noVNC)
│   ├── Dockerfile                         # arm32v7 environment for running X1D-50c ARM binaries
│   ├── entrypoint_arm.sh                  # Container boot script (Mesa GLVND, Weston, D-Bus, noVNC)
│   ├── mock_hardware_dbus.py              # Multi-bus mock com.hasselblad.* D-Bus services with live telemetry
│   ├── patch_libm.py                      # Binary ELF patcher for Yocto libm.so.6 (GLIBC_2.27 math symbols)
│   ├── libxshmfence_compat.c              # Futex/shm compat layer avoiding memfd_create
│   └── libbsd_compat.c                    # arc4random_buf compat layer avoiding __explicit_bzero_chk
├── ui_simulator/                          # Interactive 640×480 PC UI Simulator (EN/CZ), Memory Counter & Sweep
│   ├── run_simulator.py                   # Local HTTP server & REST API (/api/cim-boot, /api/safety-sweep, etc.)
│   ├── index.html                         # 640×480 X1D touchscreen, .cim bootloader & engineering workspace
│   └── fonts/                             # Original HelveticaNeueLTStd OTF fonts from rootfs
├── docs/                                  # Complete English Technical Documentation
│   ├── 01-architecture-and-hardware.md    # i.MX6Q hardware, coprocessors (FARM, SUC, FX3, SPC), Umbrella distro
│   ├── 02-cim-format-and-update-process.md# VHABCIM AES-128-CBC crypto, two-stage checksum & A/B update flow
│   ├── 03-gui-qml-and-hidden-features.md  # victory-gui QML architecture, Easter Egg & hidden demo:true options
│   ├── 04-patching-and-repacking-cim.md   # Qt Resource binary format, in-place patching & .cim header specs
│   ├── 05-cpp-backend-and-feature-analysis.md # Deep C++ daemon analysis (what actually works on X1D hardware)
│   ├── 06-pc-ui-emulation.md              # Local PC UI simulator, .cim Bootloader & ARMv7 Docker/QEMU Emulator
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
   * `FARM` Zynq-7000 Dual-QSPI de-interleaving, the `af_service.c` full-sweep state machine, and the low-level `LensProxy` (`Lens.moveRelativePos4um`) micro-stepping interface.
6. **[06 – PC UI Emulation & Safe Off-Camera Testing (`docs/06-pc-ui-emulation.md`)](docs/06-pc-ui-emulation.md)**
   * Guide to the local 640×480 PC UI Simulator (`ui_simulator/run_simulator.py`), hidden command-line flags in `victory-gui` (`--wedge`, `--session`, `--main`), and full ARM emulation in QEMU.
7. **[07 – Comparison Across All 6 Firmware Releases (`docs/07-firmware-version-comparison.md`)](docs/07-firmware-version-comparison.md)**
   * Detailed comparison of `v1.20.0`, `v1.20.1`, `v1.21.0`, `v1.22.0`, `v1.24.0`, and `v1.25.0`: container hashes, coprocessor firmware versions, kernel revisions, and feature additions (ALSA/TFA9882 audio feedback in `v1.21.0`, Focus Bracketing in `v1.22.0`, 4 µm XCD lens stepping in `v1.24.0`).

### Custom Firmware & Builder Specifications (`custom_firmware_docs/`)

* **[00 – Custom Firmware Builder Architecture & Technical Rules (`custom_firmware_docs/00-custom-firmware-builder-architecture.md`)](custom_firmware_docs/00-custom-firmware-builder-architecture.md)** – Specifications for memory gauges, module JSON schemas, and 4 critical runtime rules from real ARMv7 execution (Wayland dual-windows, Qt 5.4 uppercase signal connections, `/usr/bin/configstore` speed clamps, and D-Bus signatures).
* **[01 – Module X1D Lite Edition (`custom_firmware_docs/01-module-x1d-lite-edition.md`)](custom_firmware_docs/01-module-x1d-lite-edition.md)** – Unlocking `+78.4 KB` in the QRC table and saving `−26.14 MB` on eMMC by pruning foreign camera models (`H6D`/`A6D`/`CFV`) and stripping comments.
* **[02 – Modules for Boot Speed & UI Responsiveness (`custom_firmware_docs/02-modules-boot-speed-and-ui-responsiveness.md`)](custom_firmware_docs/02-modules-boot-speed-and-ui-responsiveness.md)** – Catalog of modules `MOD-SPD-01` to `MOD-SPD-06` (fast touch boot, Weston delay reduction, instant LiveView without 200 ms lag, animation speedups).
* **[03 – Modules for Battery Life & Cooling (`custom_firmware_docs/03-modules-battery-life-and-cooling.md`)](custom_firmware_docs/03-modules-battery-life-and-cooling.md)** – Catalog of modules `MOD-BAT-01` to `MOD-BAT-05` (field offline mode powering down BCM4356 Wi-Fi, sensor LiveView timeouts, double buffering).
* **[04 – Modules for Hidden & New UI Features (`custom_firmware_docs/04-modules-hidden-and-new-ui-features.md`)](custom_firmware_docs/04-modules-hidden-and-new-ui-features.md)** – Catalog of modules `MOD-FEAT-01` to `MOD-FEAT-06` (unlocking `demo: true`, permanent secret Service menu, `DebugCam` FPGA RAW maps, shutter counter in `About`, custom accent themes).
* **[05 – Module Continuous Autofocus `AF-C` + Touch-to-Track (`custom_firmware_docs/05-module-continuous-autofocus-afc.md`)](custom_firmware_docs/05-module-continuous-autofocus-afc.md)** – Standalone module `MOD-FEAT-AFC` (`build_custom_firmware.py --mode afc`) on stock `v1.25.0`: `FARM` Zynq-7000 FPGA de-interleaving, `Lens.moveRelativePos4um` micro-stepping, and the 5-state **Gated CDAF + Peak Drop Rate** engine (`firmware/X1D_v1_25_0_afc.cim`, `63,270,912 B`).

---

## Quickstart & Tools

### 1. Launch the Interactive 640×480 PC UI Simulator & `.cim` Bootloader (EN / CZ)
```powershell
python ui_simulator/run_simulator.py
```
Opens `http://127.0.0.1:8125/` in your browser with:
* **Direct `.cim` Bootloader:** Select any `.cim` file (`v1.20.0` – `v1.25.0` or custom) in the top bar and click **`⚡ Boot .CIM`** to decrypt `rootfs.tar.bz2`, extract `/usr/bin/victory-gui` + `/etc/version` + `/usr/bin/configstore`, unpack all 405 QRC assets, and hot-reload the 640×480 camera UI with a U-Boot/Linux boot log.
* Live 640×480 X1D-50c UI, physical button/dial controls, and **EN / CZ language switch**.
* Interactive **C++ Backend X-Ray** (`victory-gui` ↔ `configstore` ↔ `msg2dbus` ↔ `camera-daemon`).
* **Memory & Storage Counter** (QRC `DATA_BASE` pool, comment-stripped `+60.2 KB` headroom, and eMMC/NOR/MCU/RAM budgets).
* **5-Stage Anti-Brick Pre-Flight Sweep** verifying QML/JS syntax, QRC slot fit, ELF/QRC decompression, U-Boot A/B rollback protection, `rootfs` boot symlinks (`readlink`), and two-stage `.cim` checksums.

### 2. Boot & Unpack Any `.cim` Firmware from CLI (`cim_emulator_loader.py`)
```powershell
# List all available .cim files in firmware/
python cim_emulator_loader.py --list

# Decrypt, extract rootfs + victory-gui, and unpack all 405 QRC assets for a specific .cim
python cim_emulator_loader.py "firmware/X1D_v1_20_0.cim"
```

### 3. Launch the Full ARMv7 Linux Rootfs Emulator (`run_arm_emulator.py`)
```powershell
# Requires Docker Desktop with QEMU arm32v7 binfmt support
python run_arm_emulator.py --cim "firmware/X1D_v1_25_0.cim"
```
Builds and boots the `arm32v7` container with the camera's extracted `rootfs`, `dbus-daemon`, native ARMv7 `/usr/bin/configstore` daemon (162 camera properties), multi-connection mock hardware D-Bus services (`mock_hardware_dbus.py`), and a `640×480` Weston display accessible in your browser at **`http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale`**.

#### Interactive Controls (Mouse / Touch & Keyboard Shortcuts):
| Control | Key / Action | Function |
| :--- | :--- | :--- |
| **Touch / Click** | **Left Mouse Click** | Tapping `f/2.8`, `125`, or `ISO 100` opens the authentic popover selector |
| **MENU Button** | **`F1`** | Toggles between the Camera Display (`ControlScreen`) and the 9-tile Main Menu |
| **Back / Exit** | **`Escape`** | Closes any open popover or submenu and returns one level up |
| **Scroll Wheels** | **Arrow Keys (`←`, `→`, `↑`, `↓`)** | Navigates menus and steps exposure values |
| **Mode Dial** | **`1`** to **`6`** | `1` = Manual (M), `2` = Auto, `3` = Shutter priority (S), `4` = Program (P), `6` = Video |
| **Direct Shortcuts** | **`C`** / **`G`** / **`Y`** | Quick access to ISO (`C`), White Balance (`G`), and dual-axis Spirit Level (`Y`) |

### 4. Run the Standalone Anti-Brick Pre-Flight Sweep & Memory Counter
```powershell
# Instant sweep + memory counter
python verify_firmware_safety.py --fast

# Full deep sweep (scans all 60 MB rootfs.tar.bz2 symlinks & .cim stream checksums)
python verify_firmware_safety.py
```

### 5. Decrypt & Extract a `.cim` Firmware Image
```powershell
python hasselblad_extract.py "firmware/X1D_v1_25_0.cim" -o "X1D_v1_25_0_extracted"
```

### 6. Extract Qt/QML/JS/PNG Resources from `victory-gui`
```powershell
python extract_victory_qrc.py "X1D_v1_25_0_extracted/victory-gui" -o "victory_gui_qml"
```

### 7. Patch a Modified QML/JS File Back into `victory-gui`
```powershell
python patch_victory_qrc_file.py `
  "X1D_v1_25_0_extracted/victory-gui" `
  "settings/scripts/MenuItemSpecificationsWedge.js" `
  "victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js" `
  -o "X1D_v1_25_0_extracted/victory-gui.patched"
```
*(Automatically strips `//` and `/* */` comments if needed, unlocking **+60.2 KB** of compressed space across `victory-gui`—including **+1,119 B** in `MenuItemSpecificationsWedge.js` and **+1,893 B** in `SettingsGeneric.qml`.)*

### 8. Repack & Encrypt a Custom `.cim` Firmware Container
```powershell
python hasselblad_pack.py `
  -t "firmware/X1D_v1_25_0.cim" `
  -i "X1D_v1_25_0_extracted" `
  -o "firmware/X1D_v1_25_0_custom.cim"
```

---

## Collaborations, Related Projects & Acknowledgements

### Active Collaboration – Film Emulation & Custom Color Profiles
* **[duart38/Hazel-firmware](https://github.com/duart38/Hazel-firmware)** – We are actively collaborating with **[@duart38](https://github.com/duart38)** (*Hazel-firmware / Haxel*), as custom **Film Emulation & Color Profiles** are one of the flagship features planned for the Hasselblad X1D-50c custom firmware toolkit. Check out the Hazel-firmware project for complementary Hasselblad firmware research and custom look development!

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
