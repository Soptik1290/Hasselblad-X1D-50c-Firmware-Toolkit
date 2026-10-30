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

### Launching the Simulator
From the repository root, run:
```powershell
python ui_simulator/run_simulator.py
```
This starts a local server on `http://127.0.0.1:8125/` and opens the interactive simulator in your browser.

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

## 2. Hidden Command-Line Flags in `/usr/bin/victory-gui`

Static analysis of `/usr/bin/victory-gui` (offsets `0x7f700..0x7f850`) revealed that the binary uses `QCommandLineParser` and supports the following CLI flags:

| CLI Flag | Description in `victory-gui` | Effect |
| :--- | :--- | :--- |
| `--wedge` | `Run in Wedge Mode.` | Forces **Hasselblad X1D-50c** mode (`guiconfig.isWedge = true`) regardless of CPU OTP fuses |
| `--albatross` | `Run in Albatross Mode.` | Forces **H6D-100c** mode |
| `--cfv` | `Run in CFV Mode.` | Forces **907X / CFV II 50C** mode |
| `--a6d50` | `Run in A6D 50 Mode.` | Forces **A6D-50c** mode |
| `--a6d100` | `Run in A6D 100 Mode.` | Forces **A6D-100c** mode |
| `--session` | `Use the DBus session bus.` | Uses the D-Bus session bus instead of `--system` (intended for desktop Linux development) |
| `--fullscreen` | `Run in fullscreen.` | Runs in fullscreen mode |
| `--main <path>` | *(overrides default `qrc:///main.qml`)* | Loads the root QML file from an external filesystem path instead of internal `qrc:///`! |

Additionally, the `KeyInject` class (`com.hasselblad.mockup`, offset `0x7fd90`) accepts simulated button presses over D-Bus (`menu`, `f1`..`f5`, `left`, `right`, `double_click`), used by Hasselblad developers in Gothenburg for automated GUI testing.

---

## 3. Full ARM Emulation in QEMU (`qemu-system-arm`)

If you want to run the actual `/usr/bin/victory-gui` ARM binary alongside the system daemons (`configstore`, `camera-daemon`, `bodystate-daemon`, `weston`) inside an emulated ARM processor on a PC, `YuHaoyua/hasselblad-x1d-reverse-engineering` documents the exact setup:

1. **Prerequisites**:
   - `qemu-system-arm` installed (via QEMU for Windows or Linux/WSL2).
   - An ARM Linux `zImage` kernel built for `imx_v6_v7_defconfig` or `vexpress-a9` with `devtmpfs`, `fbdev` (640×480), and `virtio` support.
2. **Building an `initramfs` from the Extracted `rootfs`**:
   - The extracted `rootfs` already contains the complete Yocto userspace (`Hasselblad Umbrella Distro 2.0.3`), including `/usr/bin/weston`, `/usr/lib/weston/fbdev-backend.so`, and `/usr/lib/weston/victory-shell.so`.
   - Because QEMU lacks the i.MX6 Vivante GC2000 GPU, change `/usr/bin/weston.sh` from `--use-gal2d=1` to the software Pixman framebuffer backend (`--backend=fbdev-backend.so`) and launch `victory-gui` with:
     ```sh
     export XDG_RUNTIME_DIR=/tmp
     export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
     /usr/bin/victory-gui -platform wayland --wedge
     ```
3. **When to Use QEMU vs. Our Local PC Simulator**:
   - For **99% of menu customizations, unlocking `demo: true` options, and testing QML/JS edits**, `python ui_simulator/run_simulator.py` is much faster because it starts instantaneously without compiling an ARM kernel.
   - QEMU is ideal when debugging binary ARM instruction patches inside `/usr/bin/victory-gui` or `/usr/bin/camera-daemon` with `gdb-multiarch`.
