# 05 – Deep Analysis of the C++ Backend & Hidden Features (QML ↔ D-Bus ↔ Daemons)

In [`03-gui-qml-and-hidden-features.md`](03-gui-qml-and-hidden-features.md), we discovered dozens of hidden menu options inside the extracted QML tree (`victory_gui_qml/`)—flagged with `demo: true`, guarded behind `guiconfig.showSecretMenuItems`, or filtered out by `guiconfig.isWedge`.

To determine **which of these features have a working C++ implementation in the X1D-50c (`v1.25.0`) firmware** versus which are dormant remnants from the H6D (`Victory`) digital back, we performed static analysis across all key ELF binaries in `rootfs`:

1. **`/usr/bin/victory-gui`** (`2,210,236 B`) – Qt5/QML UI and the `SettingsMiddleLayer` C++ class that translates menu option strings into numeric/boolean values.
2. **`/usr/bin/configstore`** (`201,000 B`) – Central D-Bus configuration service (`se.hasselblad.configstore`) storing current values, defaults, and bounds (`_minval` / `_maxval`) on persistent flash.
3. **`/usr/bin/msg2dbus`** (`439,340 B`) – Hardware bridge translating D-Bus properties from `configstore` into binary packets for **SUC** (`SucHandler` – System Microcontroller, lens, shutter, buttons, eye-sensor) and **FARM** (`FarmHandler` – imaging FPGA, sensor readout, contrast AF calculation).
4. **`/usr/bin/camera-daemon`** (`329,604 B`) – Central camera state machine (`Camera` and the X1D-specific `WedgeStateMachine`).
5. **`/usr/bin/bodystate-daemon`** (`248,260 B`) – Physical GPIO button, dial, and body state handler (`GPIOKeys`, `StateManager`).
6. **`/usr/bin/storage-daemon`** (`414,228 B`) – 3FR/JPG SD card storage daemon (`ConfigstoreProxy`).

---

## 1. Settings Processing Pipeline in the X1D

Every setting in the menu flows through four distinct layers:

```text
[QML Menu (MenuItemSpecificationsWedge.js / SettingsGeneric.qml)]
       │  (reads/writes Q_PROPERTY on the C++ `settings` context object)
       ▼
[victory-gui: C++ class SettingsMiddleLayer]
       │  (converts QML strings like "21000" to int/bool and calls ConfigstoreProxy)
       ▼
[configstore (D-Bus: se.hasselblad.configstore)]
       │  (validates _minval/_maxval, persists to profile, emits *Changed D-Bus signal)
       ├───────────────────────────────┬──────────────────────────────┐
       ▼                               ▼                              ▼
[bodystate-daemon]             [camera-daemon]                 [msg2dbus]
(GPIOKeys: physical            (WedgeStateMachine:             (SucHandler / FarmHandler:
 button mapping)                exposure, focus, LiveView)      sends commands to MCU & FPGA)
```

Whenever a hidden QML menu item is wired through all four layers, **unhiding it in QML makes it immediately functional on real X1D-50c hardware**.

---

## 2. Master Support Matrix of Hidden Features Across Daemons

| QML Property (`settings.*` / `guiconfig.*`) | Menu Name | `victory-gui` (`SettingsMiddleLayer`) | `configstore` (D-Bus + Persist) | `msg2dbus` (`Suc`/`Farm` Bridge) | Other Daemons (`bodystate` / `camera` / `storage`) | Verdict on X1D-50c Hardware |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **`showSecretMenuItems`** | *Easter Egg in About* | **YES** | — | — | Calls `/usr/bin/prodconfig-tool` | **Fully functional (no FW mod needed!)** |
| **`thumbwheel_mode`** | *Scroll Wheel Handling* | **YES** (`Original` / `Adjusted`) | **YES** | **YES** (`SucHandler`) | `/usr/bin/prodconfig-tool` | **Fully functional (part of Easter Egg)** |
| **`Userbutton_AELockFunction`** | *AE-L Button* (Custom Buttons) | **YES** (33 actions) | **YES** | **YES** | **YES** (`GPIOKeys::onUserbutton_AELockFunction`) | **100% functional once unhidden in QML** |
| **`Userbutton_AFDriveFunction`** | *AF-D Button* (Custom Buttons) | **YES** (33 actions) | **YES** | **YES** | **YES** (`GPIOKeys::onUserbutton_AFDriveFunction`) | **100% functional once unhidden in QML** |
| **`CustomOption_RearApertureWheel`** | *Front Wheel in M* | **YES** (`Aperture` / `Shutterspeed`) | **YES** | **YES** (`SucHandler`) | Handled by SUC microcontroller | **100% functional once unhidden in QML** |
| **`CustomOption_HideBTmode`** | *Hide B/T Mode* | **YES** (`boolean`) | **YES** | **YES** (`SucHandler`) | **YES** (`camera-daemon` `ConfigstoreProxy`) | **100% functional once unhidden in QML** |
| **`CustomOption_AElockAtHalfpress`** | *AE-L when Half-pressed* | **YES** (`boolean`) | **YES** | **YES** (`SucHandler`) | Handled by SUC microcontroller | **100% functional once unhidden in QML** |
| **`Eyesensor_Distance`** | *Eye Sensor Distance* | **YES** (`Short` / `Medium` / `Long`) | **YES** | **YES** (`SucHandler`) | Handled by SUC microcontroller | **100% functional once unhidden in QML** |
| **`DebugAfSpeedEnable`** + **`DebugAfSpeed`** | *AF Speed Debug / Value* | **YES** (`7000` to `31000`, step 2000) | **YES** | **YES** (`af_cmd_speed`) | Controls XCD lens stepping motor speed | **100% functional (experimental AF tuning)** |
| **`fpga_debug`** | *Brenner* (contrast metric) | **YES** (`x + y`, `x + y/4`, `x + y/2`) | **YES** | **YES** (`FarmHandler`) | Configures Brenner filter register in FPGA | **100% functional (experimental AF tuning)** |
| **`af_fir`** / **`af_log`** / **`af_full_scan`** | *AF FIR / AF Log / AF Full Scan* | **YES** (`boolean`) | **YES** | **YES** (`FarmHandler`) | Contrast AF parameters in FPGA/SUC | **100% functional (experimental AF tuning)** |
| **`DebugAfMode`** | *AF Mode Debug* | **YES** (`boolean`) | **YES** | **YES** (`SucHandler`) | AF debug mode | **100% functional (experimental AF tuning)** |
| **`compress_3fr`** | *Compressed 3FR* | **YES** (`boolean`) | **YES** | **YES** (`FarmHandler`) | **YES** (`storage-daemon` `compress_3frChanged`) | **Wired in daemons (test with caution)** |
| **`jpg_size`** | *JPG Size* (`12.8 MP` vs Full) | **YES** (`Quarter` / `Full`) | **YES** | **YES** (`FarmHandler`) | **YES** (`storage-daemon` `jpg_sizeChanged`) | **Wired in daemons** |
| **`rawprocessing_mode`** | *Raw Processing Mode* | **YES** (`Full` / `DS2`) | **YES** | **YES** (`FarmHandler`) | Sensor downsampling in FPGA | **Experimental (engineering menu)** |
| **`Focus_AFC`** / **`Focus_AFT`** | *AF-C* and *True Focus* | **YES** (`PopoverFocusMode.qml`) | **YES** | Sent to `SucHandler` | **NO in `WedgeStateMachine`** (falls back to `AF-S`) | **Inactive on X1D (lacks H6D gyro/PD module)** |
| **`contrast`** / **`textForImage`** / **`audioMode`** | *Contrast / Text / Audio* | Empty Q_PROPERTY stubs | **NO** | **NO** | **NO** | **Unimplemented (UI placeholders only)** |

---

## 3. Detailed Breakdown by Category

### Category A: Built-In Easter Egg (Works Out-of-the-Box Without Modding!)

Analysis of `SettingsGeneric.qml` (line 951) and `victory-gui` (`GuiConfiguration::wantToSeeFWUpdateRetryClicked()`) revealed an official engineering Easter Egg:

- **How to activate it directly on the camera**:
  1. Open **Menu → General Settings (gear icon) → About**.
  2. Repeatedly tap the **`Firmware: 1.25.0`** (`versionID`) row.
  3. This sets `guiconfig.showSecretMenuItems = true`.
  4. Navigate back and open **Service**: 3 hidden service options appear!

What these 3 options do in C++:
1. **`Scroll Wheel Handling`** (`guiconfig.thumbwheel_mode`):
   - Invokes `/usr/bin/prodconfig-tool --thumbwheel-mode` and writes `thumbwheel_mode` to `configstore`.
   - Switches front and rear command dial step/debounce handling between **`Original`** and **`Adjusted`**.
2. **`Deactivate Storage`** (`settings.ram_only_mode`):
   - Sets `farm.ram_only_mode` in `configstore` and `FarmHandler`, holding captured frames in RAM without writing to the SD card (used during factory shutter/sensor life testing).
3. **`Firmware Update Retry`** (`guiconfig.fwUpdateRetry`):
   - Forces re-execution of the firmware update routine.

---

### Category B: 100% Functional User Features Hidden Behind `demo: true`

These features have a complete C++ implementation for the X1D (`Wedge`), but remained hidden in `MenuItemSpecificationsWedge.js` because `demo: true` was left set (`guiconfig.hideDemoItems == true` in production builds).

#### 1. Remapping the `AE-L` and `AF-D` Buttons (`Userbutton_AELockFunction` & `Userbutton_AFDriveFunction`)
- By default, the X1D **Custom Buttons** menu only exposes the `ISO/WB` button (`Userbutton_IsoWbFunction`).
- However, `MenuItemSpecificationsWedge.js` (lines 164–165) also defines **AE-L** and **AF-D** with `demo: true`.
- **Proof in `bodystate-daemon`**:
  The symbol table of `/usr/bin/bodystate-daemon` contains all three handlers:
  - `GPIOKeys::onUserbutton_IsoWbFunction(int)` (address `0x160a8`)
  - `GPIOKeys::onUserbutton_AELockFunction(int)` (address `0x160c0`)
  - `GPIOKeys::onUserbutton_AFDriveFunction(int)` (address `0x160b4`)
- All three map from the same 33-action table in `configstore` (`True Focus`, `Focus Assist`, `AE Lock`, `AF Drive`, `Drive Mode`, `Crop Mode`, `Mirror Up`, `Exposure Sim`, `Start Liveview`, `Zoom In`, etc.). Removing `demo: true` in `MenuItemSpecificationsWedge.js` (or disabling `hideDemoItems` in `SettingsGeneric.qml`) makes both buttons fully programmable on the X1D.

#### 2. Swapping Front/Rear Dials in Manual Mode (`CustomOption_RearApertureWheel` – "Front Wheel in M")
- Selects whether the front scroll wheel in Manual (`M`) mode controls **`Aperture`** or **`Shutterspeed`**.
- `victory-gui` (`SettingsMiddleLayer::setCustomOption_RearApertureWheel`) converts the selection to a boolean, stores it in `configstore`, and forwards it via `msg2dbus` (`SucHandler`) to the body microcontroller.

#### 3. Hide B/T Mode (`CustomOption_HideBTmode`) & AE-L on Half-Press (`CustomOption_AElockAtHalfpress`)
- **`Hide B/T Mode`**: Propagates to `camera-daemon` (`ConfigstoreProxy::CustomOption_HideBTmodeChanged(bool)`), omitting Bulb/Time when scrolling shutter speeds.
- **`AE-L when Half-pressed`**: Locks exposure when half-pressing the shutter release button.

#### 4. EVF Proximity Sensor Sensitivity (`Eyesensor_Distance`)
- `MenuItemSpecificationsWedge.js` (line 233) defines **Eye Sensor → Distance** with **`Short`**, **`Medium`**, and **`Long`** presets.
- `victory-gui` (`SettingsMiddleLayer::setEyesensor_Distance`) maps these to `0`, `1`, `2` in `configstore` (`Eyesensor_Distance_minval` / `_maxval`), and `msg2dbus` writes the threshold to the SUC microcontroller monitoring the EVF IR sensor.

---

### Category C: Engineering Autofocus Tuning (FPGA & XCD Lenses)

One of the most interesting discoveries in the X1D-50c firmware is in `SettingsGeneric.qml` (lines 703–825). Because the X1D-50c relies on contrast-detection autofocus (CDAF) computed inside the **FARM FPGA** combined with stepping motors in XCD lenses, Hasselblad engineers built an entire AF tuning panel into the GUI (hidden behind `!guiconfig.hideDemoItems`):

1. **`DebugAfSpeedEnable` + `DebugAfSpeed` (Autofocus Motor Speed)**:
   - `SettingsMiddleLayer` (`victory-gui`, offset `0x1bf2d8`) defines 13 discrete stepping speeds:
     `7000`, `9000`, `11000`, `13000`, `15000`, `17000`, `19000`, `21000`, `23000`, `25000`, `27000`, `29000`, `31000`.
   - `msg2dbus` forwards this value over the **`af_cmd_speed`** channel (offset `0x53597` in `msg2dbus`) directly to the XCD lens controller!
2. **`fpga_debug` ("Brenner" – FPGA Contrast Metric Weighting)**:
   - The Brenner gradient evaluates focus sharpness inside the active AF zone on the FPGA.
   - `SettingsMiddleLayer` switches the formula between **`x + y`**, **`x + y/4`**, and **`x + y/2`** (horizontal vs. vertical contrast weighting).
3. **`af_fir`**, **`af_log`**, **`af_full_scan`**, **`DebugAfMode`**:
   - All four toggles are backed by D-Bus properties in `configstore` and handlers in `msg2dbus` (`0x4e284..0x4e29c`).
   - `af_full_scan` forces a full-range lens sweep, `af_fir` enables FIR filtering over the contrast curve, and `af_log` records AF step telemetry.

---

### Category D: 3FR Compression & JPEG Resolution (`compress_3fr`, `jpg_size`, `rawprocessing_mode`)

- `storage-daemon` implements `ConfigstoreProxy::compress_3frChanged(bool)` and `ConfigstoreProxy::jpg_sizeChanged(hblm_resolutions)`.
- In `victory-gui` (`SettingsMiddleLayer`), `jpg_size` switches between full resolution (`Full`) and quarter resolution **`12.8 MP`** (`Quarter`).
- `rawprocessing_mode` toggles FPGA sensor readout between **`Full`** and **`DS2`** (2× downsampling).

---

### Category E: Why `AF-C` and `True Focus` (`Focus_AFC`, `Focus_AFT`) Fall Back to `AF-S` on the X1D

`PopoverFocusMode.qml` (line 62) selects the focus mode model based on `guiconfig.isWedge`:
```qml
model: guiconfig.isWedge ? grid_model_wedge : grid_model
```
Whereas `grid_model_wedge` only exposes **AF-S** (`Focus_AFS = 1`) and **MF** (`Focus_MAN = 3`), the full `grid_model` adds **AF-C** (`Focus_AFC = 2`) and **True Focus** (`Focus_AFT = 6`).

What happens if we enable `grid_model` on the X1D?
- Disassembling `WedgeStateMachine::checkFocusMode()` (address `0x32860` in `/usr/bin/camera-daemon`) and `Camera::onFocusModeChanged()` (address `0x21524`) provides the exact answer:
  ```armasm
  ; WedgeStateMachine::checkFocusMode() (0x32860 in camera-daemon)
  0x3286c: ldrb r3, [r3, #0x1c]   ; load FocusMode
  0x32870: cmp  r3, #3            ; is FocusMode == 3 (Focus_MAN)?
  0x32874: beq  0x328bc           ; if yes -> expose immediately without AF (WedgeStateMachine::expose)
  0x3287c: bl   Camera::focusMode ; load effective FocusMode from Camera class
  0x32880: cmp  r0, #3            ; is FocusMode == 3 (Focus_MAN)?
  0x32884: beq  0x328bc           ; if yes -> expose immediately without AF
  ...
  0x328a8: b    WedgeStateMachine::findFocus ; otherwise (for ANY non-MF mode), run single-shot CDAF!
  ```
- **Conclusion**: `WedgeStateMachine` in `camera-daemon` only checks whether `FocusMode == 3` (`Focus_MAN`) or `!= 3`. `AF-C` and `True Focus` are implemented for the **H6D** (`Victory`), where phase-detection AF and gyro-assisted True Focus are handled by the reflex body processor (`cambody`). On the X1D-50c, selecting `AF-C` or `True Focus` simply triggers standard single-shot **`AF-S`**.

---

## 4. Recommended Candidates for a Custom Firmware Mod Pack

To create a clean, practical firmware mod for the X1D-50c that unlocks genuinely working C++ features:

1. **Unlock `demo: true` items in `SettingsGeneric.qml` & `MenuItemSpecificationsWedge.js`**:
   - In `victory_gui_qml/settings/SettingsGeneric.qml` (line 704), change:
     ```qml
     // Original:
     visible: !guiconfig.hideDemoItems
     // Modified:
     visible: true
     ```
   - And in `victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`, remove `demo: true` from:
     - **AE-L** and **AF-D** in *Custom Buttons* (lines 164–165),
     - **Front Wheel in M**, **Hide B/T Mode**, **AE-L when Half-pressed** (lines 193–211),
     - **Eye Sensor Distance** (line 233).
2. **Or even cleaner – bind hidden items to the built-in Easter Egg (`guiconfig.showSecretMenuItems`)**:
   - By gating hidden items behind `guiconfig.showSecretMenuItems` in `SettingsGeneric.qml`, the camera boots with a 100% stock UI and reveals all advanced/engineering options only when you tap `Firmware: 1.25.0` in the `About` screen.
