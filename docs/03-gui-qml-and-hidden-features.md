# 03 – Graphical User Interface (`victory-gui`), QML & Hidden Features

## 1. `victory-gui` Architecture

The camera's primary user interface is a 32-bit ARM ELF binary `/usr/bin/victory-gui` (`2,210,236` bytes in `v1.24.0` / `v1.25.0`).
* It runs on top of the **Weston (Wayland)** compositor with two main windows:
  * **`main`** (`640×480` px) – Rear touch LCD (`TouchWindow.qml` loaded from `main.qml`).
  * **`overlay`** (`1024×768` px) – OLED Electronic Viewfinder (EVF) / HDMI output (`liveview/EVFWindow.qml`).
* All UI presentation logic, screens, menus, and key mappings are compiled directly inside `/usr/bin/victory-gui` using the **Qt Resource System (`qrc://`)** at the following file offsets:
  * **Name Table (`names`):** `0x1D7E44`
  * **Directory Tree (`tree`):** `0x1DC7F0`
  * **Data Payload (`data`):** `0x0FC7F8` (individual files compressed with `zlib`)

Using [`extract_victory_qrc.py`](../extract_victory_qrc.py), we extracted all **405 embedded files** from `victory-gui` into [`victory_gui_qml/`](../victory_gui_qml):
* **128× `.qml`** (all screens, popups, live view overlays, menus)
* **9× `.js`** (model-specific menu definitions and keymaps)
* **267× `.png`** (UI icons and graphical assets)
* **1× `.ttf`** (embedded font)

### How `victory-gui` Distinguishes Camera Models in QML
In [`victory_gui_qml/settings/scripts/MenuItemImporter.js`](../victory_gui_qml/settings/scripts/MenuItemImporter.js) and individual QML components, the C++ context object `guiconfig` selects the active camera personality:
* `guiconfig.isWedge` → **`true` on Hasselblad X1D-50c** (loads [`MenuItemSpecificationsWedge.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js) and [`KeyMapsWedge.js`](../victory_gui_qml/scripts/KeyMapsWedge.js)).
* `guiconfig.isAlbatross` → `true` on H6D-100c / A6D-100c ([`MenuItemSpecificationsA6D.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsA6D.js)).
* The CFV digital back uses [`MenuItemSpecificationsCFV.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsCFV.js) and the standard H6D-50c uses [`MenuItemSpecifications.js`](../victory_gui_qml/settings/scripts/MenuItemSpecifications.js).

---

## 2. Built-In Secret Service Menu (Easter Egg Without Firmware Modification)

In [`victory_gui_qml/settings/SettingsGeneric.qml`](../victory_gui_qml/settings/SettingsGeneric.qml) (lines `944`–`1012`), there is a built-in engineering Easter Egg:

1. In **General Settings → About**, the **`Firmware: 1.25.0`** row (`name: "versionID"`) is defined as a clickable `SettingType.TEXTBUTTON` rather than a static label.
2. Tapping this row invokes the C++ method:
   ```javascript
   case "versionID":
       guiconfig.wantToSeeFWUpdateRetryClicked();
       break;
   ```
3. Repeatedly tapping **`Firmware: 1.25.0`** sets `guiconfig.showSecretMenuItems = true` and displays a toast popup:
   > **"Additional functions now available in Service Menu"**
4. In **General Settings → Service** ([`MenuItemSpecificationsWedge.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js), lines `261`–`265`), this unlocks 3 hidden options guarded by `validCheck: "guiconfig.showSecretMenuItems"`:
   * **Demo Mode → Deactivate Storage (`farm.ram_only_mode`)** – Captures images to RAM only without writing to the SD card.
   * **Additional Functions → Firmware Update Retry (`guiconfig.fwUpdateRetry`)** – Forces a repeat of the firmware update routine.
   * **Additional Functions → Scroll Wheel Handling (`guiconfig.thumbwheel_mode`)** – Switches front/rear dial debouncing between `Original` and `Adjusted`.

---

## 3. Hidden Focus Modes: `Continuous Focus (AF-C)` and `True Focus (AF-T)`

In [`victory_gui_qml/components/popups/PopoverFocusMode.qml`](../victory_gui_qml/components/popups/PopoverFocusMode.qml) (lines `61`–`142`), which renders the focus mode selector popup (when pressing the `AF/MF` button), Swedish developers left a comment (`OBS!` = Swedish *Observera!*, i.e. *Note!*):

```qml
// OBS!!!! Temporarily remove items from wedge for demo. Remove "grid_model_wedge" and expression below when done
model: guiconfig.isWedge ? grid_model_wedge : grid_model
```

* **`grid_model`** contains all 4 focus modes:
  1. `Manual Focus` (`Config.Focus_MAN`)
  2. `Single Focus` (`Config.Focus_AFS`)
  3. **`Continuous Focus` (`Config.Focus_AFC`)**
  4. **`True Focus` (`Config.Focus_AFT`)**
* **`grid_model_wedge`** (selected on the X1D-50c when `guiconfig.isWedge` is true) only includes the first two (`Manual Focus` and `Single Focus`).
* Changing line `62` in `PopoverFocusMode.qml` to `model: grid_model` unlocks the **Continuous Focus (`AF-C`)** and **True Focus (`AF-T`)** buttons in the X1D-50c UI (see [`docs/05-cpp-backend-and-feature-analysis.md`](05-cpp-backend-and-feature-analysis.md) for how `camera-daemon` handles them).

---

## 4. Hidden Menu Items Flagged with `demo: true`

In [`victory_gui_qml/settings/SettingsGeneric.qml`](../victory_gui_qml/settings/SettingsGeneric.qml) (line `60`), menu items are filtered at load time:
```javascript
var isDemo = (typeof v.demo !== 'undefined') && (v.demo !== undefined) && v.demo;
...
if (isValid && isEnabled && (!isDemo || !guiconfig.hideDemoItems)) {
    listModel.append(...)
}
```
Because `guiconfig.hideDemoItems == true` in production builds, all entries in [`MenuItemSpecificationsWedge.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js) marked with `demo: true` are hidden from the X1D-50c settings menu (and when unhidden, a translucent red `DemoMarker.qml` badge is rendered over them unless disabled).

### Complete Table of Hidden (`demo: true`) Items in `MenuItemSpecificationsWedge.js`:

| Menu Section | Internal Name (`name`) | Menu Label (`text1`) | Proxy Object | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Camera → Autofocus** | `af_fir` | `AF prefilter` | `configstore` | Enables FIR filtering on the AF contrast curve |
| **Camera → Autofocus** | `af_log` | `Save AF sequence` | `configstore` | Saves autofocus step logs |
| **Camera → Autofocus** | `af_full_scan` | `AF debug scan` | `configstore` | Forces a full-range lens AF scan |
| **Camera → Autofocus** | `fpga_debug` | `Brenner` | `configstore` | Selects FPGA Brenner focus metric weighting (`x+y`, `x+y/4`, `x+y/2`) |
| **Camera → Autofocus** | `DebugAfSpeedEnable` | `Enable AF Speed` | `configstore` | Enables custom XCD lens AF motor stepping speed |
| **Camera → Autofocus** | `DebugAfSpeed` | `AF Speed` | `configstore` | Sets AF motor speed (`7000`–`31000` steps) |
| **Camera → Autofocus** | `DebugAfMode` | `AF Mode` | `configstore` | AF debug mode toggle |
| *(commented out)* | `CustomOption_ZoomOnFocusRing` | `Auto Zoom in MF` | `configstore` | Auto-magnify LiveView when turning the manual focus ring |
| **Camera → Quality** | `jpg_size` | `JPG Size` (`MP`) | `configstore` | Switches JPEG output resolution (`Full` vs `12.8 MP`) |
| **Camera → Quality** | `image_noise` | `Noise Filter` | `configstore` | Image noise reduction filter |
| **Camera → Quality** | `compress_3fr` | `Compressed 3FR` | `configstore` | Lossless `.3FR` RAW compression toggle |
| **Camera → Custom Buttons** | `Userbutton_AELockFunction` | `AE-L` | `configstore` | Remaps the physical `AE-L` button (33 actions) |
| **Camera → Custom Buttons** | `Userbutton_AFDriveFunction` | `AF-D` | `configstore` | Remaps the physical `AF-D` (`AF/MF`) button (33 actions) |
| **Camera → Configuration** | `CustomOption_RearApertureWheel` | `Front Wheel in M` | `configstore` | Swaps front/rear dial roles in Manual (`M`) mode |
| **Camera → Configuration** | `CustomOption_HideBTmode` | `Hide B/T Mode` | `configstore` | Hides Bulb / Time modes when scrolling shutter speeds |
| **Camera → Configuration** | `CustomOption_AElockAtHalfpress` | `AE-L when Half-pressed` | `configstore` | Locks exposure when half-pressing the shutter button |
| **Camera → Live View** | `cameraSettingsLiveView` | `Live View` (`Overlay`) | `configstore` | Entire Live View overlay subsection in Camera settings |
| **Camera → Image Info** | `textForImage` | `Text` | – | Custom text tag embedded into image metadata |
| **Video → Quality** | `video_noise` | `Noise Filter` | `configstore` | Video noise reduction filter |
| **Video → Audio** | `audioMode`, `audioLevel` | `Mode`, `Level` | – | Microphone mode and audio recording level |
| **General → Display** | `contrast` | `Contrast` | – | Display contrast slider |
| **General → Display** | `Eyesensor_Distance` | `Eye Sensor Distance` | `configstore` | EVF proximity sensor sensitivity (`Short` / `Medium` / `Long`) |
| **General → GPS** | `gpsOn` | `GPS` | – | GPS toggle |

---

## 5. RAW Sensor Calibration Screen (`DebugCam.qml`)

In the root of the QML tree lies [`victory_gui_qml/DebugCam.qml`](../victory_gui_qml/DebugCam.qml), which directly controls `farm.rawprocessing_mode` on the imaging FPGA (`FARM`) and switches sensor output between 7 diagnostic modes:
* `0`: `Normal` (standard calibrated image)
* `1`: `Uncalibrated` (raw uncalibrated sensor readout)
* `2`: `GC Map`
* `3`: `Offset Map` (dark current / offset map)
* `4`: `ETC Map`
* `5`: `Gain Map` (flat-field pixel gain map)
* `6`: `Blemish Map` (defective pixel and column map)

---

## 6. Safe QML Modification & Testing Workflow

1. **In-Place QML Patching in `victory-gui`:**
   * Because QML files inside `victory-gui` are stored as `zlib`-compressed blobs in `DATA_BASE = 0x0FC7F8`, any `.qml` or `.js` file can be modified and recompressed in place using [`patch_victory_qrc_file.py`](../patch_victory_qrc_file.py) as long as the new compressed stream fits within the original slot (recompressing with `zlib` level `9` and stripping developer comments yields hundreds of spare bytes).
2. **Running a Modified `victory-gui` from `/media/data` Without Flashing eMMC:**
   * As documented by `YuHaoyua/hasselblad-x1d-reverse-engineering`, over the `sutest-daemon` USB diagnostic shell you can upload a patched binary to `/media/data/victory-gui` (it must be named `victory-gui` so Weston binds the window surface), stop the systemd service, and launch it manually:
     ```sh
     systemctl stop victory-gui
     XDG_RUNTIME_DIR=/tmp WAYLAND_DISPLAY=wayland-0 QT_QPA_PLATFORM=wayland /media/data/victory-gui -platform wayland
     ```
   * Rebooting the camera cleanly restores the untouched `/usr/bin/victory-gui` from the read-only root partition.
