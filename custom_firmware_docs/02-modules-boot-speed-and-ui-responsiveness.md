# 02 – Modules for Boot Acceleration & Instant UI Responsiveness (`MOD-SPD-01` to `MOD-SPD-06`)

This document provides exact technical implementation recipes for 6 modules in the **Speed & Responsiveness** category. Each module identifies the target file, line references, original state, modified state, storage/memory deltas, and observed benefits on physical Hasselblad X1D-50c hardware.

---

## Overview of Modules in the Speed Category

| Module ID | Builder Label | Primary Benefit | Memory / Storage Delta |
| :--- | :--- | :--- | :--- |
| **`MOD-SPD-01`** | **Fast Touch, Sensors & LiveView Startup** | Touchscreen, EVF eye-sensor, and LiveView become operational **4–5 seconds earlier** after powering on. | `rootfs: +2 B` |
| **`MOD-SPD-02`** | **Shortened Weston Compositor Output Delay** | Reduces Weston's display output wait from 3 s to 1 s (**−1.5 to −2.0 s at startup**). | `rootfs: 0 B` |
| **`MOD-SPD-03`** | **Instant LiveView Activation (Remove 200 ms Lag)** | Eliminates the artificial 200 ms `delayed_liveview` timer when pressing the LiveView button or half-pressing the shutter. | `main.qml: −1 B` |
| **`MOD-SPD-04`** | **Accelerated UI Transitions, Popovers & 100% Zoom** | 3× to 4× faster closing of ISO/WB/AF popovers, menu swipe gestures, and 100% zoom animations. | `GlobalConstants.qml: −3 B` |
| **`MOD-SPD-05`** | **Disable Verbose `console.log()` & C++ Focus Reflection** | Removes intensive C++ `QObject` property reflection on every focus shift and eliminates 178 `console.log()` calls. | `TouchWindow.qml: −118 B` (QRC) |
| **`MOD-SPD-06`** | **Remove H-System `HTS` Tilt-Shift Adapter from LiveView** | Purges the inactive `HTS` component (H6D DSLR tilt-shift adapter) from the `LiveViewOverlay.qml` tree. | `LiveViewOverlay.qml: −54 B` (QRC) |

---

## `MOD-SPD-01`: Fast Touch, Sensors & LiveView Startup (`late.timer`)

### Why Is the X1D-50c Touchscreen Unresponsive for So Long After Powering On?
Analyzing systemd service dependencies in `rootfs.tar.bz2` uncovered the root cause of a notorious X1D-50c behavior: after powering on, the LCD lights up, but **the touch panel, battery telemetry, EVF proximity sensor, and LiveView remain unresponsive for another ~5 seconds**:
- The Atmel maXTouch panel driver (`touch-modules.service` -> `/sbin/modprobe atmel_mxt_ts`), battery monitor, EVF sensor, and accelerometer drivers (`bodystate-modules.service` -> `bq28z610_battery`, `sfh7776`, `lis3dsh_acc`), along with the LiveView streaming daemon (`video-daemon.service`), are all bound to `late.target` (or `gui-visible.target`).
- Crucially, `late.target` is not triggered by a signal from the GUI; it is gated by a **hardcoded timer `/lib/systemd/system/late.timer` configured with `OnStartupSec=7`** (plus `DefaultTimerAccuracySec=1` in `/etc/systemd/system.conf`). Systemd deliberately idles for **7 to 8 seconds** before even loading the touchscreen kernel module!

### Implementation Steps

1. **File in `rootfs.tar.bz2`:** `./lib/systemd/system/late.timer`
   - **Original configuration:**
     ```ini
     [Unit]
     Description=Run the late target

     [Timer]
     OnStartupSec=7
     Unit=late.target

     [Install]
     WantedBy=timers.target
     ```
   - **New configuration (configurable in Builder to `2` or `3` seconds):**
     ```ini
     [Unit]
     Description=Run the late target

     [Timer]
     OnStartupSec=2
     Unit=late.target

     [Install]
     WantedBy=timers.target
     ```

2. **File in `rootfs.tar.bz2`:** `./etc/systemd/system.conf` (line 21)
   - **Original configuration:**
     ```ini
     DefaultTimerAccuracySec=1
     ```
   - **New configuration:**
     ```ini
     DefaultTimerAccuracySec=100ms
     ```

---

## `MOD-SPD-02`: Shortened Weston Compositor Output Delay (`weston.sh`)

### Technical Analysis
The startup script `./usr/bin/weston.sh` initializes the Weston Wayland compositor with `--output-delay=3` (a 3-second delay while establishing framebuffers `/dev/fbmain`, `/dev/fbhdmi`, and `/dev/fbevf`). Because udev rules already instantiate the framebuffer symlinks prior to `weston.service` execution, this delay can safely be reduced to `1`.

### Implementation Steps
- **File in `rootfs.tar.bz2`:** `./usr/bin/weston.sh` (line 8)
- **Original configuration:**
  ```sh
  /usr/bin/weston --tty=1 --use-gal2d=1 --use-gl=0 --output-delay=3 --device=${MAIN}${HDMI}${EVF}
  ```
- **New configuration:**
  ```sh
  /usr/bin/weston --tty=1 --use-gal2d=1 --use-gl=0 --output-delay=1 --device=${MAIN}${HDMI}${EVF}
  ```

---

## `MOD-SPD-03`: Instant LiveView Activation (Remove 200 ms Lag) (`delayed_liveview`)

### Technical Analysis
In [`victory_gui_qml/main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml#L486-L496), pressing the physical LiveView button or half-pressing the shutter (`HALFPRESS`) does not invoke `Camera.setLiveViewState(true)` directly. Instead, it triggers a `delayed_liveview` timer with an interval of **`200 ms`**. Reducing this interval to `20 ms` preserves button switch debounce while activating LiveView practically instantaneously (**−180 ms latency reduction**).

### Implementation Steps
- **File:** [`victory_gui_qml/main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml#L486-L490)
- **Original code:**
  ```qml
  Timer {
      id: delayed_liveview
      interval: 200
      repeat: false
  ```
- **New code:**
  ```qml
  Timer {
      id: delayed_liveview
      interval: 20
      repeat: false
  ```

---

## `MOD-SPD-04`: Accelerated UI Transitions, Popovers & 100% Zoom

### Technical Analysis
Default UI timing constants in [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml) specify excessively sluggish animation durations:
- `fadeOutDuration: 500` (half a second to dismiss any ISO, WB, AF, or Exposure Mode popover in [`Popover.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/components/popups/Popover.qml#L157)).
- `zoomFullAnimateTime: 500` and `zoomAnimateTime: 200` (half a second to animate 100% zoom transitions in LiveView and image review).
- `menuSwipeDuration: 200` and `afSelectionLongPressThreshold: 350` (350 ms long-press required before dragging the AF focus point).

### Implementation Steps
1. **File:** [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml)
   - Line 63: `readonly property int fadeOutDuration : 500` -> `120`
   - Line 121: `readonly property int highlightMoveDuration : 50` -> `25`
   - Line 162: `readonly property int menuSwipeDuration : 200` -> `90`
   - Line 169: `readonly property int zoomAnimateTime: 200` -> `70`
   - Line 171: `readonly property int zoomFullAnimateTime: 500` -> `120`
   - Line 190: `readonly property int afSelectionLongPressThreshold: 350` -> `180`
2. **File:** [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L1645-L1674)
   - Lines 1645, 1665, 1673: `duration: 100` -> `duration: 40`

---

## `MOD-SPD-05`: Disable Verbose `console.log()` & C++ Focus Reflection

### Technical Analysis
1. In [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L208-L216) at line 210, a leftover development log command persists:
   ```qml
   console.log("ActiveFocusItem changed:", activeFocusItem, guiconfig.itemProperties(activeFocusItem, false, true, 0))
   ```
   On **every single focus shift in the entire GUI**, it invokes the C++ method `guiconfig.itemProperties(...)`, which iterates through all properties of the target QML object using `QMetaObject` runtime reflection, serializes them into a massive string, and logs it via `console.log` into `systemd-journald`!
2. Across all 137 QML/JS files, a total of **178 `console.log(...)` invocations** continuously pipe debugging noise into system journals.
3. In `./etc/systemd/journald.conf`, `RateLimitBurst=0` and `ForwardToSyslog=yes` are enabled (originally left for FPGA `FARM` trace debugging), causing `systemd-journald` on the i.MX6 CPU to process an unrestricted stream of debug messages.

### Implementation Steps
1. **File:** [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L208-L216)
   - **Original code:**
     ```qml
     onActiveFocusItemChanged: {
         if(null != activeFocusItem) {
             console.log("ActiveFocusItem changed:", activeFocusItem, guiconfig.itemProperties(activeFocusItem, false, true, 0))
             var itemStr = activeFocusItem.toString()
             if (itemStr.search(/QQuickRootItem/) === 0) {
                 focusRestoreTimer.restart()
             }
         }
     }
     ```
   - **New code:**
     ```qml
     onActiveFocusItemChanged: {
         if(null != activeFocusItem) {
             var itemStr = activeFocusItem.toString()
             if (itemStr.search(/QQuickRootItem/) === 0) {
                 focusRestoreTimer.restart()
             }
         }
     }
     ```
2. **All QML/JS Files (Builder Toggle):** Automatically prune standalone `console.log(...);` statements (saving an additional **~4.5 KB** in the QRC pool).
3. **File in `rootfs.tar.bz2`:** `./etc/systemd/journald.conf`
   - Adjust `RateLimitBurst=0` -> `RateLimitBurst=200`, `ForwardToSyslog=yes` -> `ForwardToSyslog=no`, and append `MaxLevelStore=warning` + `RuntimeMaxUse=8M`.

---

## `MOD-SPD-06`: Remove H-System `HTS` Tilt-Shift Adapter from `LiveViewOverlay.qml`

### Technical Analysis
In [`victory_gui_qml/liveview/LiveViewOverlay.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/LiveViewOverlay.qml#L791-L797), every LiveView instantiation creates an `HTS` component (Hasselblad Tilt-Shift 1.5X adapter for H6D DSLRs) and attaches an event handler `onHts_attachedChanged: checkOverlay()`. This accessory physically cannot attach to the mirrorless X1D-50c lens mount.

### Implementation Steps
- **File:** [`victory_gui_qml/liveview/LiveViewOverlay.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/LiveViewOverlay.qml)
- Remove `HTS { id: hts ... }` (lines 791–797) and replace checks for `hts.hts_attached` (lines 179, 862, 875, 1020) with constant `false`.
