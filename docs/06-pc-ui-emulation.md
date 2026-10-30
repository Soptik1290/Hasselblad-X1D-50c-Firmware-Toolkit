# 06 – PC UI Emulation & Safe Off-Camera Testing

Before packing anything into a `.cim` container and flashing it onto the camera, there are **three levels of safe testing for `victory-gui` modifications**:

1. **Level 1 (Instant on Windows/macOS/Linux): Local 640×480 PC UI Simulator & QML Inspector** (`ui_simulator/run_simulator.py`) – Directly executes the extracted `MenuItemSpecifications*.js` scripts, loads the original `HelveticaNeueLTStd` OTF fonts, and renders all 267 PNG icons from `victory_gui_qml/`.
2. **Level 2 (Full ARM Linux Emulation on PC): Running the original `victory-gui` binary inside QEMU** (`qemu-system-arm`) with the Weston/Wayland compositor and an emulated `640×480` framebuffer.
3. **Level 3 (On-Camera Testing Without Flashing eMMC): Running a patched `victory-gui` from `/media/data/victory-gui`** or using the built-in `--main` CLI flag.

---

## 1. Local PC UI Simulator (`ui_simulator/run_simulator.py`)

Why can't you simply open `victory_gui_qml/main.qml` in standard desktop `qmlscene`?
In `main.qml` (lines 3–17), the UI imports 15 proprietary C++ QML plugins registered inside `/usr/bin/victory-gui` and backed by D-Bus daemons:
```qml
import com.hasselblad.config 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.power 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.storage 1.0
import com.hasselblad.error 1.0
import com.hasselblad.systemd 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.settings 1.0
import com.hasselblad.lens 1.0
import com.hasselblad.sound 1.0
```

Because the menu structure and item specifications are written in pure JavaScript (`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`), we built **`ui_simulator/`**, which:
- **Directly loads and executes the live `victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js` file** (as well as `MenuItemSpecifications.js` for H6D, `MenuItemSpecificationsCFV.js` for 907X/CFV II 50C, and `MenuItemSpecificationsA6D.js` for A6D).
- Renders at the **exact 640×480 px native resolution** using the original **`HelveticaNeueLTStd-Lt_1.otf`** and **`HelveticaNeueLTStd-Bd_1.otf`** fonts (extracted from `/usr/lib/fonts/` in `rootfs`) and **original PNG icons** from `victory_gui_qml/icons/`.
- Replicates `MainScreen.qml`, `Menu.qml`, `SettingsGeneric.qml`, `DemoMarker.qml` (red highlight overlay on `demo: true` items), and `DemoModeIndicator.qml` (`NO STORAGE`).
- Includes a **C++ Backend X-Ray Inspector** and **Live QRC Slot Size Checker (`zlib` level 9)**—whenever you edit any file in `victory_gui_qml/` and click reload, the simulator immediately updates the menu and calculates how many spare bytes remain in the `victory-gui` binary slot.

### Launching the Simulator & Direct `.cim` Bootloader
From the repository root, run:
```powershell
python ui_simulator/run_simulator.py
```
This starts a local server on `http://127.0.0.1:8125/` and opens the interactive bilingual (EN / CZ) simulator in your browser.

#### Direct `.cim` Firmware Bootloader (`cim_emulator_loader.py`)
You can unpack and boot **any official or custom `.cim` firmware image (`v1.20.0` – `v1.25.0`)** directly on Windows:
1. **In the WebUI (`http://127.0.0.1:8125/`)**: Select any `.cim` file from the top dropdown and click **`⚡ Boot .CIM`** (or open the **4. `.CIM` & ARM Emulator** tab). The server decrypts the `VHABCIM` container, verifies the two-stage `PrivateHeader::Checksum`, extracts `/usr/bin/victory-gui`, `/usr/bin/configstore`, and `/etc/version` from `rootfs.tar.bz2`, dynamically locates the `DATA_BASE`, `NAMES_BASE`, and `TREE_BASE` QRC tables inside the ELF binary, unpacks all 405 QRC assets, displays an animated 640×480 U-Boot/Linux boot log, and hot-reloads the UI.
2. **From the Command Line**:
   ```powershell
   python cim_emulator_loader.py --list
   python cim_emulator_loader.py "firmware/X1D_v1_20_0.cim"
   ```

#### 5-Stage Anti-Brick Pre-Flight Sweep & Memory Counter (`verify_firmware_safety.py`)
Before repacking or flashing any modified firmware, run the automated safety sweep (either in the **3. Anti-Brick Sweep** WebUI tab or via CLI):
```powershell
python verify_firmware_safety.py --fast
```
It verifies:
1. **QML & JS Syntax Integrity** across all 128 QML and 9 JS files.
2. **QRC Slot Capacity & Comment-Stripped Headroom** (confirming every modified file fits its compressed `zlib` slot, with **+60.2 KB** freed by automatic comment stripping in `patch_victory_qrc_file.py`).
3. **Binary ELF & QRC Decompression Round-Trip** (`405/405` assets).
4. **U-Boot A/B Rollback Protection & `rootfs` Symlink Integrity** (verifying that `hbl-upgrade` only flashes the inactive eMMC bank and never overwrites U-Boot `/dev/mtd0`, and checking `/sbin/init` + `readlink` so `hbl-post-upgrade` sets `boot_ok=1`).
5. **`.cim` Cryptographic & Two-Stage Checksum Verification** across all firmware containers.

### Things to Try in the Simulator:
1. **Unlocking Hidden Menu Items (`guiconfig.hideDemoItems`)**:
   - Uncheck `guiconfig.hideDemoItems` in the right-hand inspector panel.
   - The top bar of the main menu displays `Build: 1.25.0` (matching `MainScreen.qml:1192`), and **Autofocus**, **Custom Buttons**, **Configuration**, **Quality**, and **Display** reveal all hidden options highlighted with the translucent red `DemoMarker.qml` overlay.
   - Unchecking `DemoState.demoOn` hides the red overlay.
2. **Triggering the Built-In Easter Egg**:
   - Open **General Settings (gear icon) → About**.
   - Click the **`Firmware: 1.25.0`** row 5 times.
   - `guiconfig.showSecretMenuItems = true` unlocks **Deactivate Storage**, **Firmware Update Retry**, and **Scroll Wheel Handling** under **General Settings → Service**.
3. **Testing Front/Rear Dial Swap in Manual Mode (`Front Wheel in M`)**:
   - Navigate to **Camera Settings → Configuration → Front Wheel in M** and switch from `Aperture` to `Shutterspeed`.
   - Press the **CTRL (✕)** button next to the display and scroll the front/rear wheels above the screen—their roles swap immediately.

---

## 2. Command-Line Flags in `/usr/bin/victory-gui`

Running `/usr/bin/victory-gui --help` inside the ARMv7 container reveals the exact `QCommandLineParser` options supported by the binary:

| CLI Flag | Description in `victory-gui` | Effect |
| :--- | :--- | :--- |
| `-w, --wedge` | `Run in Wedge Mode.` | Forces **Hasselblad X1D-50c** mode (`guiconfig.isWedge = true`) regardless of CPU OTP fuses |
| `-a, --albatross` | `Run in Albatross Mode.` | Forces **H6D-100c** mode |
| `-c, --cfv` | `Run in CFV Mode.` | Forces **907X / CFV II 50C** mode |
| `-k, --a6d50` | `Run in A6D 50 Mode.` | Forces **A6D-50c** mode |
| `-l, --a6d100` | `Run in A6D 100 Mode.` | Forces **A6D-100c** mode |
| `-s, --session` | `Use the DBus session bus.` | Uses the D-Bus session bus instead of `--system` (intended for desktop Linux development) |
| `-f, --fullscreen` | `Run in fullscreen.` | Runs in fullscreen mode |
| `-h, --help` / `-v, --version` | `Displays this help / version.` | Prints CLI usage and version |

Additionally, the `KeyInject` class (`com.hasselblad.mockup`, offset `0x7fd90`) accepts simulated button presses over D-Bus (`menu`, `f1`..`f5`, `left`, `right`, `double_click`), used by Hasselblad developers in Gothenburg for automated GUI testing.

---

## 3. Full ARMv7 Linux Rootfs Emulator on Windows (`run_arm_emulator.py`)

To run the camera's extracted ARMv7 Linux `rootfs` and daemons (`configstore`, `victory-gui`) inside a real ARMv7 environment on Windows via Docker Desktop (`arm32v7` QEMU user-mode emulation) and inspect the `640×480` Weston display in your browser via **noVNC**:

```powershell
python run_arm_emulator.py --cim "firmware/X1D_v1_25_0.cim"
```

### How It Works:
1. **Unpacks `rootfs.tar.bz2`** from the selected `.cim` firmware into `.emulator_cache/<firmware>/rootfs_full/` (preserving Linux symlinks inside the container).
2. **Builds & Starts the `x1d-armv7-emulator` Container (`arm_emulator/`)**:
   - Copies the camera's D-Bus security policies (`/etc/dbus-1/system.d/com.hasselblad.*.conf`) and starts `dbus-daemon --system`.
   - Starts the camera's native ARMv7 `/usr/bin/configstore` daemon (which registers `com.hasselblad.config` and serves all 162 camera properties) alongside `arm_emulator/mock_hardware_dbus.py` (mocking `com.hasselblad.cambody`, `com.hasselblad.camera`, `com.hasselblad.lens`, `com.hasselblad.systemmanager`, etc.).
   - Starts a `640×480` virtual framebuffer (`Xvfb :0`), the **Weston** Wayland compositor (`640×480`), `x11vnc`, and **noVNC** on port `6080`.
3. **Connecting via Browser (`noVNC`)**:
   - Open **`http://127.0.0.1:6080/vnc.html?autoconnect=true`** in your browser.
   - If you see the **noVNC** connection box in the top-right corner (`Host: 127.0.0.1`, `Port: 6080`, `Password: [empty]`), simply click the **`Connect`** button (no password is required) to view the live `640×480` ARMv7 Weston screen.
