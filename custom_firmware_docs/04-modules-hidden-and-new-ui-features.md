# 04 – Modules for Unlocking Hidden & New UI Features (`MOD-FEAT-01` to `MOD-FEAT-06`)

Because the **`MOD-CORE-LITE`** module unlocks **+78,397 B of compressed headroom in the QRC table** inside `/usr/bin/victory-gui` (including +1,893 B in `SettingsGeneric.qml`, +1,255 B in `MenuItemSpecificationsWedge.js`, and +1,268 B in `ControlScreen.qml`), the builder application can offer one-click unlocking of hidden factory features as well as brand new custom tools.

---

## Overview of Modules in the Features & UI Extensions Category

| Module ID | Builder Label | What the Module Unlocks / Adds | QRC Slot Delta |
| :--- | :--- | :--- | :--- |
| **`MOD-FEAT-01`** | **Unlock Hidden Quality, Buttons & AF Options (`demo: true`)** | Unlocks `Compressed 3FR`, `JPG Size`, `Noise Filter`, `Eye Sensor Distance`, `AE-L` / `AF-D` button remapping, `Front Wheel in M`, `Hide B/T Mode`, `AE-L when Half-pressed`, and engineering AF debug options. | `SettingsGeneric.qml: −22 B` |
| **`MOD-FEAT-02`** | **Permanently Unlock Secret `Service` Menu (`showSecretMenuItems`)** | Grants direct access to `Scroll Wheel Handling`, `Firmware Update Retry`, and `Deactivate Storage (RAM-Only Mode)` without needing the service gesture. | `SettingsGeneric.qml: −18 B` |
| **`MOD-FEAT-03`** | **FPGA RAW Sensor Maps Diagnostic Screen (`DebugCam.qml`)** | Adds a menu toggle for raw sensor output modes (`Normal`, `Uncalibrated`, `GC Map`, `Offset Map`, `ETC Map`, `Gain Map`, `Blemish Map`). | `MenuItemSpecificationsWedge.js: +65 B` |
| **`MOD-FEAT-04`** | **Shutter Actuation Counter & Diagnostics in `About`** | Displays body and lens shutter actuation counts and detailed coprocessor revisions directly on the first `About` page. | `MenuItemSpecificationsWedge.js: +48 B` |
| **`MOD-FEAT-05`** | **Custom UI Accent Colors / Astro Night Mode (`hblOrange`)** | Allows altering the factory orange `#de4200` to custom accent colors (e.g. deep red `#990000` for dark-adapted astrophotography, gold, or cyan). | `GlobalConstants.qml: 0 B` |
| **`MOD-FEAT-06`** | **Configurable LiveView Framing Grid (3×3, 4×4, 6×6 & 1 px Width)** | Changes the fixed `liveViewGridCount: 3` and reduces line thickness from `2 px` down to `1 px`. | `GlobalConstants.qml: 0 B` |

---

## `MOD-FEAT-01`: Unlock Hidden Quality, Buttons & AF Options (`demo: true`)

### Technical Analysis
In [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js), 17 fully programmed menu items are tagged with `demo: true`. In [`victory_gui_qml/settings/SettingsGeneric.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/SettingsGeneric.qml#L50-L53), line 53 enforces the visibility guard:
```javascript
if (isValid && isEnabled && (!isDemo || !guiconfig.hideDemoItems))
```
Because the C++ property `guiconfig.hideDemoItems` returns `true` in production builds, these items remain completely hidden from the user!

### Which Items in `MenuItemSpecificationsWedge.js` Are Flagged with `demo: true`?
1. **Quality Menu (`cameraSettingsQuality`, lines 226–229):**
   - `compress_3fr` (**Compressed 3FR** – losslessly compressed RAW files!)
   - `image_noise` (**Noise Filter** – noise reduction level)
   - `jpg_size` (**JPG Size [MP]** – preview/embedded JPEG resolution)
2. **Custom Buttons Menu (`cameraSettingsCustomButtons`, lines 100–101):**
   - `Userbutton_AELockFunction` (reprogramming physical **AE-L** button)
   - `Userbutton_AFDriveFunction` (reprogramming physical **AF-D** button)
3. **Configuration Menu (`cameraSettingsConfiguration`, lines 107–109):**
   - `CustomOption_RearApertureWheel` (**Front Wheel in M** – swap front and rear dials in Manual mode)
   - `CustomOption_HideBTmode` (**Hide B/T Mode** – hide Bulb/Time stops when scrolling shutter speeds)
   - `CustomOption_AElockAtHalfpress` (**AE-L when Half-pressed** – lock exposure on shutter half-press)
4. **Display Menu (`generalSettingsDisplay`, line 141):**
   - `Eyesensor_Distance` (**Eye Sensor Distance** – proximity threshold for EVF auto-switching)
5. **Video Quality Menu (`videoSettingsVideoQuality`, line 124):**
   - `video_noise` (**Noise Filter** for video recording)
6. **Autofocus Menu (`cameraSettingsAutofocus`, lines 52–58 – optional as "AF Engineering Debug"):**
   - `af_fir` (`AF prefilter`), `af_log` (`Save AF sequence`), `af_full_scan` (`AF debug scan`), `fpga_debug` (`Brenner`), `DebugAfSpeedEnable` (`Enable AF Speed`), `DebugAfSpeed` (`AF Speed`), `DebugAfMode` (`AF Mode`).

> [!WARNING]
> **Hardware Limit for `DebugAfSpeed` in `/usr/bin/configstore` (`3000 .. 20000`):**
> Although the dropdown in `SettingsMiddleLayer` (`/usr/bin/victory-gui` at `0x82b90`) lists values from `7000` up to `31000`, disassembly of `/usr/bin/configstore` (`0x13d68..0x13de0`) proves that the daemon enforces a strict range of `DebugAfSpeed_minval = 3000` and `DebugAfSpeed_maxval = 20000` (default `5000`). Any selection from `21000..31000` will be rejected by `configstore`, maintaining the previous setting. The maximum valid value is **`19000`** (or a direct integer write of **`20000`**), accelerating XCD lens stepping motors by **3.8× to 4.0×**.

### Implementation Steps
In the Builder application, two approaches can be supported:
- **Approach A (Global Unlock):** In [`victory_gui_qml/settings/SettingsGeneric.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/SettingsGeneric.qml#L53), change line 53:
  ```javascript
  // Original:
  if (isValid && isEnabled && (!isDemo || !guiconfig.hideDemoItems)) {
  // New:
  if (isValid && isEnabled) {
  ```
  and in [`victory_gui_qml/components/controls/FavoriteAddSelector.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/components/controls/FavoriteAddSelector.qml#L46), change line 46:
  ```javascript
  if((v.settingsList !== "") && !favoriteModel.isInList(v.settingsList))
  ```
- **Approach B (Selective Granular Unlock):** In [`MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js), toggle `demo: true` -> `demo: false` only for the specific items selected by the user.

---

## `MOD-FEAT-02`: Permanently Unlock Secret `Service` Menu (`showSecretMenuItems`)

### Technical Analysis
In [`MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L177-L181), 4 items in `generalSettingsService` are guarded by `validCheck: "guiconfig.showSecretMenuItems"`:
- `ram_only_mode` (**Deactivate Storage** – testing mode without SD card writes)
- `fwUpdateRetry` (**Firmware Update Retry** – force firmware flashing retry)
- `thumbwheel_mode` (**Scroll Wheel Handling** – adjustment of dial direction/behavior)

### Implementation Steps
In [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L177-L181), remove `, validCheck: "guiconfig.showSecretMenuItems"` from lines 177, 178, 180, and 181.

---

## `MOD-FEAT-03`: FPGA RAW Sensor Maps Diagnostic Screen (`DebugCam.qml`)

### Technical Analysis
The QRC tree of `/usr/bin/victory-gui` contains a complete diagnostic view: [`victory_gui_qml/DebugCam.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/DebugCam.qml). This view directly manipulates C++ property `farm.rawprocessing_mode` on the Xilinx Kintex-7 FPGA, allowing raw sensor output to be switched across 7 modes:
- `0`: `Normal` (standard image processing pipeline)
- `1`: `Uncalibrated` (raw uncalibrated sensor stream from Sony IMX161)
- `2`: `GC Map`
- `3`: `Offset Map` (dark current offset map)
- `4`: `ETC Map`
- `5`: `Gain Map` (channel gain normalization map)
- `6`: `Blemish Map` (defective pixel map stored in factory calibration!)

### Implementation Steps
In [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L208-L222), append to array `settingsMenuItems`:
```javascript
{settingsList: "generalSettingsDebugCam", itemText: "RAW Sensor Maps", itemFile: "qrc:///DebugCam.qml", largeIcon: "LargeIconService"},
```

---

## `MOD-FEAT-04`: Shutter Actuation Counter & Diagnostics in `About`

### Technical Analysis
In [`MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L183-L194), the lens exposure counter `lensCounter` (`proxy: suc`) is hidden within the `Usage` sub-menu. Moving it directly into `generalSettingsAbout` along with properties from `prodinfo`, `system`, and `suc` gives photographers immediate access on a single view.

### Implementation Steps
- **File:** [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L183-L190)
- Add entry `{editType: SettingType.TEXT, name: "lensCounter", text1: qsTranslate("MENUS", "Lens: "), proxy: suc}` directly into the `generalSettingsAbout` array.

---

## `MOD-FEAT-05`: Custom UI Accent Colors / Astro Night Mode (`hblOrange`)

### Technical Analysis
All active accent colors, highlight boxes, sliders, and focused icons across the entire X1D-50c UI inherit from two constants in [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L14-L15):
```qml
readonly property color hblOrange: "#de4200"
readonly property color hblOrangeDark: "#852800"
```
The Builder can expose a color picker or presets:
- **Hasselblad Orange (Stock):** `#de4200` / `#852800`
- **Astro Deep Red (Preserves night dark-adapted vision):** `#991100` / `#550800`
- **Monochrome Silver / White:** `#d0d0d0` / `#707070`
- **Cyan Tech:** `#0099cc` / `#005577`

---

## `MOD-FEAT-06`: Configurable LiveView Framing Grid (`liveViewGridCount` & `liveViewGridLineWidth`)

### Technical Analysis
In [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L130-L131) and [`GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L43), the framing grid in LiveView is hardcoded to a 3×3 rule-of-thirds layout with a 2 px thick white line:
```qml
readonly property color liveViewGridColor : "white"
readonly property int liveViewGridCount : 3
readonly property int liveViewGridLineWidth : 2
```

### Implementation Steps
In the Builder application, configure options:
- **Grid Subdivisions (`liveViewGridCount`):** `3` (Thirds), `4` (Quarters + Center Cross), `6` (Architectural 6×6 grid).
- **Line Width (`liveViewGridLineWidth`):** `1` (subtle 1 px line that does not obstruct focus inspection) or `2` (stock).
- **Grid Color (`liveViewGridColor`):** `"#80ffffff"` (semi-transparent white) instead of opaque `"white"`.
