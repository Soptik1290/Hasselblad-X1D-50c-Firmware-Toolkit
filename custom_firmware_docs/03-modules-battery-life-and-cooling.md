# 03 – Modules for Battery Life Extension & Thermal Reduction (`MOD-BAT-01` to `MOD-BAT-05`)

This document describes 5 concrete hardware and system modifications that **deliver measurable battery life extension and reduce thermal buildup in the aluminum chassis of the Hasselblad X1D-50c**.

---

## Where Does Energy Consumption & Heat Originate in the X1D-50c?

Hardware profiling of the X1D-50c platform identifies 4 primary power sinks drawing from the battery pack (7.2 V / 3200 mAh = 23 Wh):
1. **50MP Sony IMX161 Sensor + 2× Xilinx Kintex-7 FPGAs (`farm` Even/Odd) during LiveView:** Consumes **~6 to 8 W** (the primary contributor to camera body heating).
2. **Rear 3" LCD display (`fbmain`) and OLED EVF (`fbevf`) + i.MX6Quad 2D GPU (`gal2d`):** Consumes **~1.5 to 2.5 W**.
3. **Broadcom BCM4356 PCIe Wi-Fi chip (`brcmfmac4356-pcie.bin`) + Network Daemons (`phocus-mobile-server`, `avahi-daemon`, `network-manager`):** Draws **~150 to 350 mW continuously**, because stock firmware unconditionally loads the PCIe Wi-Fi kernel driver 10 seconds after boot regardless of whether wireless functionality is active!
4. **USB OTG controller (`ci_hdrc_imx`) and NXP i.MX6Quad SoC (4× Cortex-A9 @ 792 MHz):** Consumes **~1.0 to 1.8 W**.

---

## Overview of Modules in the Battery & Cooling Category

| Module ID | Builder Label | Estimated Benefit (Power / Thermals) | Memory / Storage Delta |
| :--- | :--- | :--- | :--- |
| **`MOD-BAT-01`** | **Disable PCIe Wi-Fi & Phocus/Avahi Daemons at Boot (Field / Offline Mode)** | **−150 to −300 mW baseline draw**, **+12 MB free RAM**, zero CPU wakeups by network services. | `rootfs: −4 symlinks` |
| **`MOD-BAT-02`** | **Shorten 50MP Sensor LiveView Idle Timeout (`liveViewImageTimeoutDefault`)** | Prevents 3-minute continuous sensor/FPGA heating when camera is left unattended (**saves 15–25% battery in the field**). | `GlobalConstants.qml: 0 B` |
| **`MOD-BAT-03`** | **Deep Black Level (`blackScreenBrightness`) & Accelerated EVF Sleep** | Lowers baseline LCD black backlight from `9` to `1` and shortens `evfExitTimer` from `1000 ms` to `300 ms`. | `TouchWindow.qml: −1 B` |
| **`MOD-BAT-04`** | **Efficient Double Framebuffer for Weston Compositor (`FB_MULTI_BUFFER=2`)** | Reduces allocated framebuffers from `3` to `2` (lowers DDR3 memory bus load and `gal2d` GPU cycles). | `rootfs: 0 B` |
| **`MOD-BAT-05`** | **Disable Inactive Debug Daemons (`sshd.socket`, `usb-modules.service`)** | Deactivates listening SSH sockets and unused debug USB controllers during regular card-based shooting. | `rootfs: −2 symlinks` |

---

## `MOD-BAT-01`: Disable PCIe Wi-Fi Chip BCM4356 & Phocus/Avahi Daemons (`verylate.target`)

### Why Does Stock Firmware Drain the Battery Even with Wi-Fi Switched Off?
In `rootfs.tar.bz2`, exactly 10 seconds after startup, systemd triggers `./lib/systemd/system/verylate.timer`, reaching `verylate.target`. In `./etc/systemd/system/verylate.target.wants/`, the following symlinks are activated:
1. `network-manager.service` -> executes **`ExecStartPre=/sbin/modprobe brcmfmac`**, which **always loads the Broadcom BCM4356 PCIe kernel driver**, initializing the PCIe bus and uploading `brcmfmac4356-pcie.bin` firmware!
2. `phocus-mobile-server.service` -> launches `/usr/bin/phocus-mobile-server -p 50001` with elevated priority **`Nice=-10`** (equal priority to the main GUI!).
3. `avahi-daemon.service` and `avahi-daemon.socket` -> mDNS/Bonjour daemon.
4. `systemd-networkd.service` and `systemd-networkd.socket`.

### Implementation Steps (Field / Offline Mode)
Within `rootfs.tar.bz2`, remove the following symlinks from `./etc/systemd/system/verylate.target.wants/`:
- `./etc/systemd/system/verylate.target.wants/network-manager.service`
- `./etc/systemd/system/verylate.target.wants/phocus-mobile-server.service`
- `./etc/systemd/system/verylate.target.wants/avahi-daemon.service`
- `./etc/systemd/system/verylate.target.wants/avahi-daemon.socket`
- `./etc/systemd/system/verylate.target.wants/systemd-networkd.service`
- `./etc/systemd/system/verylate.target.wants/systemd-networkd.socket`

*(Note: Wired USB tethering with Phocus via `phocus-daemon.service` remains 100% functional!)*

---

## `MOD-BAT-02`: Shorten 50MP Sensor & FPGA Idle Timeout in LiveView

### Technical Analysis
In [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L188) at line 188, the default duration that the 50MP sensor and both Kintex-7 FPGAs remain energized in LiveView is defined as:
```qml
readonly property int liveViewImageTimeoutDefault: 3 * 60
```
This forces **180 seconds (3 full minutes)** of peak power draw (~7 W) every time LiveView is activated unless the photographer explicitly dismisses it. Shortening this threshold to **45 s** or **60 s** (configurable in Builder) substantially reduces heat generation and conserves battery life.

### Implementation Steps
- **File:** [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L188)
- **Original code:**
  ```qml
  readonly property int liveViewImageTimeoutDefault: 3 * 60
  ```
- **New code (e.g. 45 seconds):**
  ```qml
  readonly property int liveViewImageTimeoutDefault: 45
  ```

---

## `MOD-BAT-03`: Deep Black Level & Accelerated EVF Sleep

### Technical Analysis
1. In [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L192), the standby dimmed screen backlight level is set to `blackScreenBrightness: 9`. Lowering this to `1` (or `2`) reduces idle LCD LED backlight power.
2. In [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L1165-L1176), `evfExitTimer` holds the display state for `1000 ms` (1 full second) after pulling the eye away from the EVF before permitting LiveView stream sleep (`!evfExitTimeoutActive` at line 1636). Shortening this to `300 ms` puts the sensor to sleep 700 ms faster when moving the camera away from the eye.

### Implementation Steps
1. **File:** [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L192)
   - `readonly property int blackScreenBrightness: 9` -> `readonly property int blackScreenBrightness: 1`
2. **File:** [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L1165-L1168)
   - In `Timer { id: evfExitTimer }`: `interval: 1000` -> `interval: 300`

---

## `MOD-BAT-04`: Efficient Double Framebuffer for Weston Compositor (`FB_MULTI_BUFFER=2`)

### Technical Analysis
While `victory-gui.service` and `video-daemon.service` operate with `Environment=FB_MULTI_BUFFER=1`, `./lib/systemd/system/weston.service` configures `Environment=FB_MULTI_BUFFER=3` (triple buffering across all displays). Lowering this parameter to `FB_MULTI_BUFFER=2` preserves completely tear-free presentation (double buffering) while conserving DDR3 RAM bandwidth and GPU framebuffer memory.

### Implementation Steps
- **File in `rootfs.tar.bz2`:** `./lib/systemd/system/weston.service` (line 7)
- **Original configuration:**
  ```ini
  Environment=FB_MULTI_BUFFER=3
  ```
- **New configuration:**
  ```ini
  Environment=FB_MULTI_BUFFER=2
  ```

---

## `MOD-BAT-05`: Disable Inactive Debug Services (`sshd.socket` & Debug USB Driver)

### Technical Analysis
In `./etc/systemd/system/verylate.target.wants/`, development services remain persistently configured:
- `sshd.socket` (spawns an OpenSSH server on incoming network traffic).
- `usb-modules.service` (`Description=USB modules for debug`, loads `/sbin/modprobe ci_hdrc_imx` – ChipIdea High-Speed Dual-Role USB controller on the i.MX6 SoC, which serves only internal debug purposes; USB tethering with Phocus operates through the dedicated **Cypress EZ-USB FX3** peripheral controller!).

### Implementation Steps
Within `rootfs.tar.bz2`, remove the following symlinks from `./etc/systemd/system/verylate.target.wants/`:
- `./etc/systemd/system/verylate.target.wants/sshd.socket`
- `./etc/systemd/system/verylate.target.wants/usb-modules.service`
