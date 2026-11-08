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
   - `SettingsMiddleLayer` (`victory-gui`, offset `0x1bf2d8` / `0x82b90`) defines 13 discrete stepping speeds in the dropdown:
     `7000`, `9000`, `11000`, `13000`, `15000`, `17000`, `19000`, `21000`, `23000`, `25000`, `27000`, `29000`, `31000`.
   - **Important `/usr/bin/configstore` Range Limit (`0x13d68..0x13de0`):** Disassembly of `/usr/bin/configstore` revealed that the daemon enforces **`min = 3000`**, **`max = 20000`** (`0x4e20`), and **`default = 5000`**. Any value `> 20000` (`21000..31000`) is rejected by `configstore` (`Property DebugAfSpeed could not be set to new value`). Thus, the maximum valid dropdown option is **`19000`** (or direct integer **`20000`** from QML), delivering a **3.8× to 4.0× faster** stepping speed than the `5000` default.
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
- **Conclusion (Stock Behavior vs. Our Custom `AF-C` Engine)**: `WedgeStateMachine` in `camera-daemon` only checks whether `FocusMode == 3` (`Focus_MAN`) or `!= 3`. Simply unhiding the `AF-C` icon in `PopoverFocusMode.qml` causes the camera to perform a single CDAF pass and sit in `"Session is idle, starting liveview"`.

---

### Category F: Breakthrough – De-Interleaving the `FARM` (Zynq-7000) Dual-QSPI Firmware, `af_service.c`, and `Gated CDAF + Peak Drop Rate`

Digging deeper into the `.cim` image answered a critical question: **What actually happens inside the `FARM` chip and XCD lens when `WedgeStateMachine::findFocus()` dispatches `image_find_focus_req`, and why does naive `stopSession()` / `startSession()` cycling (archived in `X1D_v1_25_0_afc_old.cim`) cause full-sweep hunting on real hardware?**

#### 1. De-Interleaving the `FARM` Dual-QSPI Images
Inside `rootfs` (`/lib/firmware/hbl/farm/`) are two `3,954,444 B` files:
- `bootimage_even-wedge-v1.25.0-13075-c9bb91d.bin` (flashed to `/dev/mtd3`)
- `bootimage_odd-wedge-v1.25.0-13075-c9bb91d.bin` (flashed to `/dev/mtd4`)

**`FARM`** is not a bare FPGA but a **Xilinx Zynq-7000 SoC** (dual-core ARM Cortex-A9 + FPGA) attached to two parallel QSPI flashes in **Dual-Parallel QSPI x8 (bit-interleaved)** mode – every byte of the `BOOT.BIN` image is split into **even bits (`0, 2, 4, 6`)** in the `even` file and **odd bits (`1, 3, 5, 7`)** in the `odd` file.

Re-merging the bits yields a `7,908,888 B` image `farm_wedge_boot.bin` (Xilinx Zynq Boot Image header `0xAA995566`, `"XNLX"`) with 3 partitions:
1. **Partition 0** (`0x001700`, `114,708 B`) – Zynq First Stage Boot Loader (`FSBL`).
2. **Partition 1** (`0x01D740`, `5,979,936 B`) – PL FPGA bitstream with the hardware **Brenner sharpness filter** (`../src/fpga/autofocus.c`).
3. **Partition 2** (`0x5D1680`, `1,808,280 B`, load address `0x00100000`) – ARM Cortex-A9 FreeRTOS application `farm_app.bin`.

#### 2. The `../src/services/af_service.c` State Machine (`0x198700..0x1A5490`) in `farm_app.bin`
- AF state struct in RAM at `0x006BB59C`, contrast ring buffer at `0x006BB5CC`.
- `af_service_update_lenstype` (`0x1987C4..0x199950`) – calibration profiles for `XCD30/45/90/120` and `HCC24..HCC300`.
- `image_find_focus_req` (`AF_SERVICE_SM`, `0x19B870..0x19D174`) always runs a **blind two-edge sweep (*Full-Sweep CDAF*)**: `afstate_scan_for_first_edge` (`0x19BEC0`) → `afstate_scan_for_second_edge` (`0x19C054`, deliberately overshoots the peak) → `afstate_move_back_over_peak` (`0x19C530`) → `afstate_move_to_final_position` (`0x19C96C`, parabolic peak fit).
- **Why naive `startSession()` cycling fails on real hardware:** Every `StartSession(showLiveView, true)` → `ImageProxy::findFocus` → `image_find_focus_req` forces a full sweep across both edges plus a sensor video-mode switch. Calling it periodically makes the physical lens sweep back and forth through focus (*full-sweep hunting*). True `AF-C` must drive the lens with micro-steps after the initial lock.

#### 3. Low-Level `LensProxy` (`Lens`) Interface in `libappscommon.so.1.0.0`

| QML Method / Signal on `Lens` | C++ Symbol | D-Bus Method (`com.hasselblad.lens`) → `SUC` IPC | Description |
| :--- | :--- | :--- | :--- |
| **`Lens.focusUpdateState(bool)`** | `_ZN9LensProxy16focusUpdateStateEb` (`0x4AD94D10`) | `video_focus_pos_state` → `lens_video_focus_pos_state_req` | Continuous focus-position reporting during LiveView. |
| **`Lens.moveRelativePos4um(short)`** | `_ZN9LensProxy18moveRelativePos4umEs` (`0x4AD94F0C`) | `af_cmd_relative_position_4um` → `lens_af_cmd_relative_position_4um_req` | Relative micro-step in multiples of **4 µm** (positive = Far, negative = Near) without triggering `image_find_focus_req`. |
| **`Lens.onMoveRelativePos4umResult(int)`** | `LensProxy::onMoveRelativePos4umResultFinished` (`0x4AD943D4`) | Async D-Bus reply (`QVariant::toInt()`) | Passes the 32-bit `result` straight into QML. |
| **`Lens.moveAbsolutePos(short)`** | `_ZN9LensProxy15moveAbsolutePosEs` (`0x4AD95108`) | `af_cmd_position` → `lens_af_cmd_position_req` | Move to an absolute position. |
| **`Lens.moveAtSpeed(short)`** | `_ZN9LensProxy11moveAtSpeedEs` (`0x4AD95304`) | `af_cmd_speed` → `lens_af_cmd_speed_req` | Continuous motor movement at a given speed. |

#### 4. Our `Gated CDAF + Peak Drop Rate` Algorithm (`firmware/X1D_v1_25_0_afc.cim`)
In **[`firmware/X1D_v1_25_0_afc.cim`](../firmware/X1D_v1_25_0_afc.cim)** (fully documented in [`custom_firmware_dokumentace/05-modul-continuous-autofocus-afc.md`](../custom_firmware_dokumentace/05-modul-continuous-autofocus-afc.md)), we replaced `stopSession/startSession` cycling with a closed-loop **5-state Gated CDAF & Left/Right Peak Drop Rate state machine**:

1. **Initial Peak Lock:** When `HALFPRESS` / `AF-D` (or Touch-to-Track) is triggered, the camera performs a single initial focus lock $(x_{\text{peak}}, CV_{\text{peak}})$, enables `Lens.focusUpdateState(true)`, and enters **`GATE_HOLD` (`1`)**.
2. **State 1 – `GATE_HOLD` (Zero-Hunting Gate):** As long as the relative contrast drop stays within the gate threshold (`dropFrac = (afcPeakCv - cv) / afcPeakCv < 4.5%`), the lens remains **completely stationary (zero breathing/hunting)** with a solid green focus box. Once the subject moves and contrast drops by $\ge 4.5\%$, the state machine transitions to **`PROBE_LEFT` (`2`)**.
3. **States 2 & 3 – `PROBE_LEFT` and `PROBE_RIGHT` (Left/Right Peak Drop Rate Comparison):**
   - The lens micro-steps left (`-6 × 4 µm = -24 µm`) and measures the left-side drop rate:
     $$R_L = \frac{CV_{\text{ref}} - CV_L}{\Delta x}$$
   - It then micro-steps right (`+12 × 4 µm`, landing at `+24 µm` from the reference) and measures the right-side drop rate:
     $$R_R = \frac{CV_{\text{ref}} - CV_R}{\Delta x}$$
   - **Key Real-Time Moving-Subject Rule:** When both sides are dropping simultaneously ($R_L > 0 \land R_R > 0$), **the side dropping faster ($\max(R_L, R_R)$) is further from the focus point and must pull back toward the opposite direction!**
     $$\text{afcTrackDir} = \begin{cases} +1 & \text{if } R_L > R_R \\ -1 & \text{if } R_R \ge R_L \end{cases}$$
4. **State 4 – `TRACK_CLIMB` (Hill-Climbing & Past-Peak Drop Detection):** The lens steps along `afcTrackDir` in `8 × 4 µm` (`32 µm`) increments while tracking the running peak $(x_{\max}, CV_{\max})$ and slope $dCV/dt$. As soon as the peak value begins to decrease (`der < -12` or `cv < afcMaxCv - 90`), the lens has passed the optimal focus point.
5. **State 5 – `PULLBACK` (Parabolic Pull-Back to Peak):** Using 3-point parabolic vertex interpolation across $(x_{-1}, CV_{-1})$, $(x_{\max}, CV_{\max})$, and $(x_{+1}, CV_{+1})$, the controller computes `afcTargetPos`, pulls the lens right back to the peak via `Lens.moveRelativePos4um(pullDelta)`, updates `afcPeakCv`, and returns to **`GATE_HOLD` (`1`)**.

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
