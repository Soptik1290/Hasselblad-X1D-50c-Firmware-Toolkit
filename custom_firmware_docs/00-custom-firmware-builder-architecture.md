# 00 – Architecture and Specifications of the "X1D Custom Firmware Builder" Application

This document serves as the comprehensive design specification for building a graphical application (desktop or web-based) where users load an official stock firmware container ([`X1D_v1_25_0.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0.cim)), inspect real-time camera storage and memory gauges, select desired modifications (lightweight edition, boot/UI acceleration, battery savings, unlocking hidden features, continuous autofocus), and automatically compile and verify a custom `.cim` firmware image.

---

## 1. Basic Operating Principle of the Application

```
[ Stock X1D_v1_25_0.cim (63.41 MB) ]
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 1. Extraction into Baseline Working Cache                │
│    • rootfs.tar.bz2 -> /usr/bin/victory-gui + system     │
│    • 405 QRC slots (128 QML, 9 JS, 267 PNG)              │
└──────────────────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 2. Module Configurator (User Interface)                  │
│    • [x] MOD-CORE-LITE (Lightweight X1D-only edition)    │
│    • [x] MOD-SPD-01..06 (Boot speed & UI responsiveness) │
│    • [x] MOD-BAT-01..05 (Battery savings & thermals)     │
│    • [x] MOD-FEAT-01..06 (Hidden features & tweaks)      │
│    • Live Memory Gauges (QRC Pool, eMMC, RAM)            │
└──────────────────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 3. Compiler & 5-Stage Anti-Brick Gateway                 │
│    • Apply patches to QML/JS and system files            │
│    • Write QRC slots (zlib-9) into /usr/bin/victory-gui  │
│    • Repack rootfs.tar.bz2 preserving symlinks           │
│    • Encrypt .cim (AES-128-CBC + two-stage MD5 checksum) │
│    • Automated run of verify_firmware_safety.py          │
└──────────────────────────────────────────────────────────┘
                 │
                 ▼
[ Output X1D_v1_25_0_custom.cim + Direct Test in UI Simulator ]
```

---

## 2. Live Memory & Storage Gauges in the Application

The builder application must display **precise memory limits** to the user, because every UI modification must fit within the fixed binary QRC resource slots inside the ELF binary `/usr/bin/victory-gui`.

### 2.1 Main Memory Gauges

| UI Gauge | Hard Limit (Capacity) | Stock `v1.25.0` | After Enabling `X1D Lite` | What the Gauge Monitors |
| :--- | ---: | ---: | ---: | :--- |
| **1. Total QRC Pool (`DATA_BASE`)** | `898,636 B` | `898,634 B` (`99.99%`) | `820,239 B` (`91.28%`, **+78,397 B free**) | Sum of compressed sizes of all 405 QRC resources in `/usr/bin/victory-gui` (`0x0FC7F8..0x1D7E44`). |
| **2. Individual QRC Slots (405×)** | Per neighbor offset | `0 B` headroom in most | **+6 B to +6,254 B** per file | Each of the 137 QML/JS files has its own maximum slot `slot_size(idx)` in the binary. No file may exceed its slot! |
| **3. eMMC Root (`root_a` / `root_b`)** | `536,870,912 B` (512 MB) | `158,250,622 B` (`29.48%`) | `132,113,291 B` (`24.61%`, **−26.14 MB**) | Total uncompressed file size in `rootfs.tar.bz2`. |
| **4. `.cim` Container Size** | ~`100,000,000 B` (RAM `/tmp`) | `63,410,176 B` (`60.47 MB`) | `54,358,016 B` (`51.84 MB`, **−8.63 MB**) | During update, `.cim` is unpacked into RAM/eMMC; smaller `.cim` = faster flashing. |
| **5. Operating Memory (DDR3 RAM)** | `536,870,912 B` (512 MB) | ~`193,986,560 B` (`36.1%`) | ~`180,500,000 B` (`33.6%` with unused daemons off) | Estimated RAM consumption by running daemons, Wayland/Weston framebuffer, and the QML engine. |
| **6. Immutable Critical Partitions (LOCKED)** | `uboot` (`269,312 B`), `hbl-upgrade` (`7,783 B`), `hbl-kks-revisions` (`7,030 B`) | `100% Factory Match` | `100% Factory Match` | Displayed with a green lock **"Anti-Brick Protected"** – the builder never touches these 3 components. |

### 2.2 Critical QRC Slots Monitored in the Detailed Chart

When adding new features to QML/JS, available headroom (`zlib` level 9) must be carefully tracked in these key files:

| QRC File | Fixed Slot Size in ELF | Stock `zlib-9` (Free) | After Enabling `X1D Lite` (Free) | Modules Utilizing This Slot |
| :--- | ---: | ---: | ---: | :--- |
| `common/TouchWindow.qml` | `18,120 B` | `17,056 B` (`+1,064 B`) | `11,866 B` (**`+6,254 B`**) | `MOD-SPD-04`, `MOD-SPD-05`, `MOD-BAT-03` |
| `mainmenu/MainScreen.qml` | `9,128 B` | `7,662 B` (`+1,466 B`) | `5,666 B` (**`+3,462 B`**) | Custom buttons on main screen |
| `main.qml` | `8,676 B` | `7,662 B` (`+1,014 B`) | `5,926 B` (**`+2,750 B`**) | `MOD-SPD-03`, key mappings |
| `settings/SettingsGeneric.qml` | `9,968 B` | `8,958 B` (`+1,010 B`) | `8,075 B` (**`+1,893 B`**) | `MOD-FEAT-01`, `MOD-FEAT-03` |
| `controlscreen/ControlScreen.qml` | `8,157 B` | `7,444 B` (`+713 B`) | `6,889 B` (**`+1,268 B`**) | `MOD-FEAT-04` (temperature display on status screen) |
| `settings/scripts/MenuItemSpecificationsWedge.js` | `6,052 B` | `5,299 B` (`+753 B`) | `4,797 B` (**`+1,255 B`**) | `MOD-FEAT-01`, `MOD-FEAT-02`, `MOD-FEAT-03` |
| `liveview/LiveViewOverlay.qml` | `9,359 B` | `8,602 B` (`+757 B`) | `7,812 B` (**`+1,547 B`**) | `MOD-SPD-06`, `MOD-FEAT-04` |
| `common/GlobalConstants.qml` | `3,740 B` | `3,206 B` (`+534 B`) | `2,595 B` (**`+1,145 B`**) | `MOD-SPD-04`, `MOD-BAT-02`, `MOD-BAT-03`, `MOD-FEAT-05`, `MOD-FEAT-06` |

> [!IMPORTANT]
> **Why `MOD-CORE-LITE` (Lightweight Edition) Should Be the Recommended Foundation in the Builder:**
> Without `MOD-CORE-LITE` (or at least comment-stripping), some files have only a few hundred bytes of headroom. Enabling `MOD-CORE-LITE` unlocks **1,100 to 6,250 bytes of compressed space** in key files (corresponding to **4 to 25 KB of new QML/JS source code** in each file).

---

## 3. Module Data Model for the Builder Application (JSON Schema)

Every toggle or configuration switch in the builder application is defined as a declarative module adhering to the following schema:

```json
{
  "id": "MOD-SPD-01",
  "category": "speed",
  "title": "Fast Touch, Sensors & LiveView Startup",
  "recommended": true,
  "requires": [],
  "summary": "Shortens systemd late.timer from 7 s to 2 s so that the touchscreen, EVF proximity sensor, and LiveView daemon start 5 seconds earlier after powering on.",
  "metrics": {
    "boot_time_delta_sec": -5.0,
    "ui_latency_delta_ms": 0,
    "power_delta_mw": 0,
    "rootfs_uncompressed_delta_bytes": -2,
    "qrc_slot_deltas": {}
  },
  "parameters": [
    {
      "name": "late_timer_sec",
      "label": "late.timer startup delay (s)",
      "type": "select",
      "default": 2,
      "options": [1, 2, 3, 5, 7]
    }
  ],
  "targets": [
    {
      "layer": "rootfs",
      "path": "./lib/systemd/system/late.timer",
      "action": "replace_text",
      "target": "OnStartupSec=7",
      "replacement": "OnStartupSec={{late_timer_sec}}"
    },
    {
      "layer": "rootfs",
      "path": "./etc/systemd/system.conf",
      "action": "replace_text",
      "target": "DefaultTimerAccuracySec=1",
      "replacement": "DefaultTimerAccuracySec=100ms"
    }
  ]
}
```

---

## 4. Critical Technical Rules from Live ARMv7 Execution (Mandatory for Builder)

During debugging and verification of custom firmware in the real ARMv7 Linux emulator ([`run_arm_emulator.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/run_arm_emulator.py) using native `/usr/bin/victory-gui`, `/usr/bin/configstore`, and `libappscommon.so.1.0.0` binaries), we discovered **4 critical low-level behaviors of the Hasselblad Umbrella platform** that any custom firmware builder and its modules must strictly observe. All of these rules are automatically enforced in Stage 1 of [`verify_firmware_safety.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/verify_firmware_safety.py).

### 4.1 Rule 1: Dual Wayland Windows (`TouchWindow.qml` vs. `EVFWindow.qml`)
- **Cause:** After startup, `/usr/bin/victory-gui` creates two separate Wayland `QQuickWindow` surfaces:
  1. `TouchWindow` (`title: "main"`, resolution `640×480` – rear touch LCD).
  2. `EVFWindow` (`title: "overlay"`, resolution `1024×768` – OLED EVF / HDMI output), loaded asynchronously via `Loader { id: evfWindow }` in [`main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml) approximately **2.7 seconds after boot** (`onMainWindowReady` -> `evfWindow.active = true`).
- **Trap in Stock Code:** In stock [`liveview/EVFWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/EVFWindow.qml), `visible: true` is hardcoded even when `showContent == false` (i.e. when the user is not looking into the EVF). In stock [`main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml), `Loader { id: evfWindow }` also sets `visible: active`. On a single-screen Wayland compositor (or when focused surface changes), an invisible `1024×768` `EVFWindow` is rendered over the `640×480` touchscreen after 2.7 s, capturing all mouse, touch, and keyboard events (`Event filter installed for EVF`).
- **Mandatory Solution in Every Build:**
  1. In [`victory_gui_qml/liveview/EVFWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/EVFWindow.qml), always enforce:
     ```qml
     visible: showContent
     visibility: showContent ? Window.FullScreen : Window.Hidden
     ```
  2. In [`victory_gui_qml/main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml), set `visible: false` on `Loader { id: evfWindow }` and call `mainWindow.item.requestActivate()` once initialization completes (`if (allLoaded)`).
  3. The `liveview/EVFWindow.qml` patch must be bundled into every standalone module (including `MOD-FEAT-AFC`).

### 4.2 Rule 2: Qt 5.4 `QQmlConnectionsParser` and Uppercase C++ Signals
- **Cause:** In `/usr/lib/libappscommon.so.1.0.0` (compiled against the Qt 5.4 QML parser), several `Q_PROPERTY` members in `CameraProxy` and `ConfigStoreProxy` have their `NOTIFY` signal named with an **uppercase leading letter**:
  - `CameraProxy`: `FocusModeChanged`, `WBModeChanged`, `DriveModeChanged`, `LMModeChanged`, `SVChanged`, `EVADJChanged`, `FLASH_EVADJChanged`, `AEB_EVADJChanged`
  - `ConfigStoreProxy`: `BracketingDelayTimeChanged`, `FocusBracketingStepSizeChanged`
- **Trap in Qt 5.4:** The QML element `Connections { target: Camera; onFocusModeChanged: ... }` in Qt 5.4 requires that the first letter following `on` matches a lowercase signal name. If the C++ signal starts with an uppercase letter (`FocusModeChanged`), `QQmlConnectionsParser` aborts with a fatal syntax error when loading `main.qml`:
  `qrc:///main.qml: QML Connections: Cannot assign to non-existent property "onFocusModeChanged"`.
- **Mandatory Solution:** Never use `on<UppercaseSignal>:` inside a `Connections {}` block. Instead, bind a custom lowercase QML property to the C++ property and listen to its change handler (which connects through `QMetaProperty::notifySignalIndex()` and works 100% reliably):
  ```qml
  property int currentFocusMode: Camera.FocusMode
  onCurrentFocusModeChanged: {
      // Reliably reacts to Camera.FocusMode changes!
  }
  ```

### 4.3 Rule 3: Hard Range Limits in `/usr/bin/configstore` vs. Items in `SettingsMiddleLayer`
- **Cause:** Disassembly of `/usr/bin/configstore` at `0x13d68..0x13de0` shows that the daemon registers a `(default, minval, maxval)` triplet for each numeric property at startup. For the property **`DebugAfSpeed`**, the following constants are hardcoded into `/usr/bin/configstore`:
  - `DebugAfSpeed` default (`[r4, #0x590]`): **`5000`** (`0x1388`)
  - `DebugAfSpeed_minval` (`[r4, #0x594]`): **`3000`** (`0x0bb8`)
  - `DebugAfSpeed_maxval` (`[r4, #0x598]`): **`20000`** (`0x4e20`)
- **Trap in Stock GUI:** In `/usr/bin/victory-gui` (`SettingsMiddleLayer` at `0x82b90`), developers populated the text dropdown with values `7000, 9000, 11000, 13000, 15000, 17000, 19000, 21000, 23000, 25000, 27000, 29000, 31000`. Any value **`> 20000`** is rejected by `/usr/bin/configstore` with the warning:
  `"Property DebugAfSpeed could not be set to new value: 27000. Using current value 5000"`!
- **Mandatory Solution:** In QML code and the builder UI, only present values in the range **`3000` to `20000`** for `DebugAfSpeed`. The highest valid stock dropdown value is **`19000`** (or a direct integer **`20000`**), accelerating the XCD lens stepping motor by **3.8× to 4.0×** compared to the stock `5000` setting.

### 4.4 Rule 4: Strict D-Bus Signatures of `com.hasselblad.*` Daemons
- When emulating or invoking D-Bus methods from custom scripts, exact signatures from `libappscommon.so.1.0.0` must be observed:
  - `com.hasselblad.camera.setLiveViewState` takes signature **`"bs"`** (`bool state, QString receiver`), not `"b"`.
  - `com.hasselblad.camera.StartSession` takes signature **`"bb"`** (`bool showLiveViewWhenFinished, bool forceFindFocus`).
  - `com.hasselblad.cambody` exports both `/cambody` and `/spiritlevel` (interface `com.hasselblad.spiritlevel`, method `do_spiritlevel(ib)`), and on `/cambody` the method `do_hts_polling(b)`.
  - `com.hasselblad.lens` (`/lens`) must export `video_focus_pos_state`, `af_cmd_relative_position_4um`, `af_cmd_position`, and `af_cmd_speed` for `MOD-FEAT-AFC` (invoked from QML via `Lens.focusUpdateState`, `Lens.moveRelativePos4um`, `Lens.moveAbsolutePos`, `Lens.moveAtSpeed`).

### 4.5 Rule 5: Never Drive Continuous Autofocus with Repeated `startSession()`
- **Cause:** Every call to `Camera.startSession(showLiveView, true)` routes through `ImageProxy::findFocus` to `image_find_focus_req` in `af_service.c` on the `FARM` FPGA, which executes a **blind two-edge sweep** of the entire AF range.
- **Trap:** While this appears to work in an emulator without optical dynamics, on physical hardware it causes relentless focus hunting across the full focal throw (*full-sweep hunting*) – as seen in the archived [`X1D_v1_25_0_afc_old.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0_afc_old.cim).
- **Mandatory Solution:** After initial focus lock, drive the lens using micro-steps via `Lens.moveRelativePos4um()` with deadzone gating (`GATE_HOLD`, drop threshold `4.5%`) and left/right peak drop rate comparison (*Peak Drop Rate*). [`verify_firmware_safety.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/verify_firmware_safety.py) verifies the presence of tokens `Lens.moveRelativePos4um`, `Lens.focusUpdateState`, `onMoveRelativePos4umResult`, `rLeft`, `rRight`, and `afcTargetPos` in Stage 1.

> [!WARNING]
> **Emulation does not guarantee on-hardware execution.** [`mock_hardware_dbus.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/arm_emulator/mock_hardware_dbus.py) models contrast synthetically via `OpticalCdafSimulator`; physical behavior of the `FARM` / XCD lens (especially whether `af_cmd_relative_position_4um` responses include real-time contrast metrics) must be verified on hardware.

---

## 5. Overview of All Documents in This Directory

1. **[`01-module-x1d-lite-edition.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_docs/01-module-x1d-lite-edition.md)**
   Detailed analysis of the foundation module **`MOD-CORE-LITE`** (stripping comments and non-X1D H6D/A6D/CFV models) and realistic assessment of its benefits.
2. **[`02-modules-boot-speed-and-ui-responsiveness.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_docs/02-modules-boot-speed-and-ui-responsiveness.md)**
   Catalog of 6 modules (**`MOD-SPD-01`** to **`MOD-SPD-06`**) to accelerate camera boot, activate the touchscreen immediately, remove the 200 ms LiveView lag, smooth UI animations, and disable debug logging.
3. **[`03-modules-battery-life-and-cooling.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_docs/03-modules-battery-life-and-cooling.md)**
   Catalog of 5 modules (**`MOD-BAT-01`** to **`MOD-BAT-05`**) for tangible battery life extension and camera body thermal reduction (powering down BCM4356 Wi-Fi and idle background daemons, shortening 50MP sensor idle timeouts, backlight optimizations, and framebuffer reduction).
4. **[`04-modules-hidden-and-new-ui-features.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_docs/04-modules-hidden-and-new-ui-features.md)**
   Catalog of 6 modules (**`MOD-FEAT-01`** to **`MOD-FEAT-06`**) unlocking hidden stock features (`Compressed 3FR`, `Noise Filter`, `JPG Size`, `Eye Sensor Distance`, `AF Debug/Speed`, `RAM-Only Demo Mode`, `DebugCam` FPGA RAW maps, temperature readouts, and custom UI accent themes).
5. **[`05-module-continuous-autofocus-afc.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_docs/05-module-continuous-autofocus-afc.md)**
   Standalone module **`MOD-FEAT-AFC`** (**Continuous Autofocus `AF-C` + Touch-to-Track**), built directly on top of stock firmware `1.25.0` ([`firmware/X1D_v1_25_0_afc.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0_afc.cim)). Features X2D 100C research (*HRAP*), disassembly of `WedgeStateMachine` in `/usr/bin/camera-daemon`, de-interleaving of `FARM` Dual-QSPI FPGA code (Zynq-7000, `af_service.c`), low-level `LensProxy` (`Lens.moveRelativePos4um`) stepping, and the closed-loop 5-state **Gated CDAF + Peak Drop Rate** engine (`63,270,912 B`). The earlier session-cycling prototype is archived as [`firmware/X1D_v1_25_0_afc_old.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0_afc_old.cim) (full-sweep hunting on physical hardware).
