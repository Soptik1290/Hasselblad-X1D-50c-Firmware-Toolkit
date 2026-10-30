# 07 – Comparison Across All 6 Firmware Releases (`v1.20.0` to `v1.25.0`)

With all 6 official firmware releases for the 1st-generation **Hasselblad X1D-50c** (2017–2020) in [`firmware/`](../firmware/), we were able to:
1. Reverse-engineer and verify the **two-stage `PrivateHeader::Checksum` algorithm** (`0x2d6ac` in `upgrade-daemon`) across 6 independent samples with a **100% match**.
2. Track the exact evolution of the container items (`hbl-upgrade`, `rootfs`, `uboot`, `hbl-kks-revisions`), the Linux kernel, subordinate coprocessor firmwares (`FARM`, `FX3`, `SPC`, `SUC`, `CBM`), and the core camera daemons (`victory-gui`, `camera-daemon`, `msg2dbus`, `configstore`, `bodystate-daemon`).

---

## 1. Summary Table of All 6 `.cim` Containers

| File | Build Timestamp (UTC) | Build # | `.cim` Size (B) | Derived AES `IV` | `PrivateHeader::Checksum` (`0x90..0x9F`) | `rootfs` Size (B) | Files in `rootfs` |
| :--- | :--- | :---: | ---: | :--- | :--- | ---: | :---: |
| **`X1D_v1_20_0.cim`** | `2017-12-13 15:59:09` | `21` (`0x15`) | `59,395,584` | `dc7c152e27d6b180758c448358e08dd8` | `5cdcc27bb0b2202612b17104ab78042a` | `59,108,701` | `1,906` |
| **`X1D_v1_20_1.cim`** | `2018-01-17 11:02:54` | `22` (`0x16`) | `59,372,032` | `781f94b639923a83024271804f1e153f` | `642b8e6426d9562135d0217b7e592684` | `59,085,230` | `1,906` |
| **`X1D_v1_21_0.cim`** | `2018-05-02 12:50:37` | `28` (`0x1C`) | `63,267,328` | `b49093bc46c72243ebbf551be59256ee` | `c85aaac91b64ca5df71065b25951d5cd` | `62,980,509` | `1,982` |
| **`X1D_v1_22_0.cim`** | `2019-01-18 13:15:52` | `33` (`0x21`) | `63,388,672` | `c804487e305fbbf1f0dd12a7e5c35259` | `cb5b29ca3025517e457795c7829e3a81` | `63,101,461` | `1,982` |
| **`X1D_v1_24_0.cim`** | `2020-01-29 14:58:01` | `38` (`0x26`) | `63,393,792` | `1e8c760cb8158ed8e22eb6367da18fd2` | `8db8712994a487bd335e185ca35d73eb` | `63,106,664` | `1,982` |
| **`X1D_v1_25_0.cim`** | `2020-10-22 10:23:09` | `42` (`0x2A`) | `63,410,176` | `74d898a2302518ee02bd6e2e76637206` | `e38bfbaaaad214062f18a08415a02145` | `63,123,278` | `1,982` |

> [!IMPORTANT]
> **Three of the four packaged items never changed across 3 years (`2017`–`2020`)!**
> Across all 6 firmware versions, `hbl-upgrade`, `uboot`, and `hbl-kks-revisions` are **bit-for-bit identical**:
> * **`hbl-upgrade`** (`7,783` B) – salted MD5: `1f2f15a7057ca09c0312abc0f67d1286`
> * **`uboot`** (`269,312` B) – salted MD5: `20aa7676ec112a52f4f5c9b823511cac`
> * **`hbl-kks-revisions`** (`7,030` B) – salted MD5: `29051c03db8772a87c0cbb4a7615fa30`
>
> All changes across releases occurred exclusively inside **`rootfs`** (`rootfs.tar.bz2`).

---

## 2. Evolution of Core Daemons & Libraries in `/usr/bin` and `/usr/lib`

The table below shows the exact file sizes (in bytes) of key camera binaries across releases:

| Component | `v1.20.0` | `v1.20.1` | `v1.21.0` | `v1.22.0` | `v1.24.0` | `v1.25.0` |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **`/usr/bin/victory-gui`** (Qt5/QML UI) | `1,959,360` | `1,959,360` | `2,111,012` | `2,206,028` | `2,210,236` | `2,210,236` |
| **`/usr/bin/camera-daemon`** (exposure, AF) | `304,800` | `306,788` | `321,764` | `325,776` | `329,604` | `329,604` |
| **`/usr/bin/msg2dbus`** (SUC ↔ D-Bus bridge) | `431,432` | `431,432` | `432,748` | `437,708` | `438,460` | `439,340` |
| **`/usr/bin/configstore`** (persisted config) | `176,204` | `176,204` | `196,904` | `198,768` | `201,000` | `201,000` |
| **`/usr/bin/bodystate-daemon`** (buttons, state) | `240,136` | `240,136` | `244,040` | `244,040` | `248,260` | `248,260` |
| **`/usr/bin/phocus-daemon`** (USB/Wi-Fi Phocus) | `504,268` | `504,268` | `514,800` | `515,160` | `516,408` | `516,408` |
| **`/usr/bin/metadata-daemon`** (EXIF/3FR tags) | `272,152` | `272,152` | `272,936` | `274,912` | `275,536` | `275,536` |
| **`/usr/bin/storage-daemon`** (SD cards) | `412,540` | `412,540` | `414,228` | `414,228` | `414,228` | `414,228` |
| **`/usr/lib/libappscommon.so.1.0.0`** | `643,552` | `643,552` | `680,804` | `703,480` | `705,704` | `705,704` |
| **`/usr/lib/libAppsMessaging.so`** | `90,904` | `90,904` | `95,332` | `99,620` | `99,648` | `99,648` |
| **Uncompressed `rootfs` total** | `152,279,384` | `152,289,780` | `158,067,276` | `158,209,668` | `158,249,458` | `158,250,622` |

---

## 3. Evolution of the Linux Kernel & Coprocessor Firmwares (`/lib/firmware/hbl/`)

Each `.cim` version bundles firmware images in `/lib/firmware/hbl/` for the internal FPGA and microcontrollers, flashed during upgrades by `/usr/bin/program_nodes.sh`:

| `.cim` Version | Kernel (`zImage-3.14.28-1.0.0_ga+yocto+...`) | FPGA `FARM` (`wedge`) | USB 3.0 `FX3` (`wedge`) | Power `SPC` (`power-control`) | Main MCU `SUC` (`camera-control`) | H6 Body (`CBM_1601450`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`v1.20.0`** | `g1b67c6d` | `v1.20.0-10362-5d8dfe8` (`3,938,060` B) | `v0.0-11564-c9b598c` (`159,668` B) | `v1.20.0-12005-dfa6068` (`47,903` B) | `v1.20.0-12199-1a36e7c` (`229,940` B) | `PVF-10.1.25.hex` (`251,790` B) |
| **`v1.20.1`** | `gd7b0c67` | `v1.20.1-11028-5d8dfe8` (`3,938,060` B) | `v0.0-12230-c9b598c` (`159,668` B) | `v1.20.1-12671-dfa6068` (`47,903` B) | `v1.20.1-12866-cb6bc7e` (`229,940` B) | `PVF-10.1.25.hex` (`251,790` B) |
| **`v1.21.0`** | `gccd2bfe` | `v1.21.0-12791-7fe179c` (`3,954,444` B) | `v0.0-13997-a2fd843` (`159,968` B) | `v1.21.0-14434-3e3093c` (`48,235` B) | `v1.21.0-14632-539bea7` (`237,724` B) | `PVF-10.1.25.hex` (`251,790` B) |
| **`v1.22.0`** | `gfd90cea` | `v1.22.0-12991-4e2988a` (`3,954,444` B) | `v0.0-14186-03b4b80` (`160,160` B) | `v1.22.0-14621-92d0c2f` (`48,427` B) | `v1.22.0-14821-e75cc87` (`240,744` B) | `PVF-10.1.25.hex` (`251,790` B) |
| **`v1.24.0`** | `gf7d0ab5` | `v1.24.0-13062-c3532e4` (`3,954,444` B) | `v0.0-14255-3e63462` (`160,188` B) | `v1.24.0-14690-a065c86` (`48,455` B) | `v1.24.0-14890-d681156` (`241,424` B) | `PVF-10.1.43.hex` (`269,520` B) |
| **`v1.25.0`** | `gf7d0ab5` | `v1.25.0-13075-c9bb91d` (`3,954,444` B) | `v0.0-14268-e0ef6ae` (`160,188` B) | `v1.25.0-14703-9b140c9` (`48,455` B) | `v1.25.0-14903-666e0d4` (`241,708` B) | `PVF-10.1.43.hex` (`269,520` B) |

---

## 4. Detailed Release-by-Release Changelog

### A) `v1.20.0` → `v1.20.1` (`2018-01-17`, Build 21 → 22)
* **Quick hotfix** released one month after `v1.20.0`.
* `victory-gui`, `configstore`, `msg2dbus`, and `bodystate-daemon` did not change at all.
* Only **`camera-daemon`** (`304,800` → `306,788` B), diagnostic `sutest-daemon` (`491,932` → `500,476` B), the **`SUC`** microcontroller (`1a36e7c` → `cb6bc7e`), and the kernel revision (`g1b67c6d` → `gd7b0c67`) were updated.

### B) `v1.20.1` → `v1.21.0` (`2018-05-02`, Build 22 → 28) – **Largest Feature Leap**
* Total file count in `rootfs` grew from `1,906` to `1,982` (`+76` files, `+5.8 MB` uncompressed).
* **Audio Feedback & ALSA Subsystem Enabled:**
  * Added kernel modules for the NXP **TFA9882** audio amplifier (`snd-soc-tfa9882.ko` and `snd-soc-hbl-tfa9882.ko`) and `snd-soc-fsl-sai.ko`.
  * Added `/usr/bin/aplay`, `amixer`, `alsaloop`, `alsaucm`, `speaker-test`, and libraries `libsndfile.so.1.0.25` + `libsamplerate.so.0.1.8`.
  * Added **46 system WAV sound effects** in `/usr/share/sounds/system-sound/` (`AF_focus_found.wav`, `AF_focus_not_found.wav`, `KeyClick.wav`, `SelfTimer_count.wav`, `low_batt.wav`, `media_full.wav`, `overexp.wav`, `tethered_connect.wav`, etc.).
* **New Photography Features in `camera-daemon`, `configstore`, and `victory-gui`:**
  * **Interval Timer:** `Interval timer`, `IntervalTimerCountDown`, `intervalTimerElapsed()`.
  * **Exposure Bracketing (AEB):** `AEB_EVADJ`, `AEB out of range`, `SequenceMode`.
  * **Star Rating in Playback (Image Rating):** `ImageRatingPopup`, `ContentModel.setImageRating(path, rating)`.
  * **Expanded User Profiles (Profiles 4–7):** presets `Full Auto`, `Studio`, `Fill Flash`, `Default`.
  * **CPU Frequency Scaling:** `camera-daemon` added dynamic `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` control.
  * Added hidden `DebugAfMode` (`DebugAfMode_minval`, `DebugAfMode_maxval`) in `configstore`.

### C) `v1.21.0` → `v1.22.0` (`2019-01-18`, Build 28 → 33) – **Focus Bracketing & Lens Diagnostics**
* **`victory-gui`** grew by `95 KB` (`2,111,012` → `2,206,028` B).
* **Focus Bracketing:**
  * Added `FocusBracketingNumberOfFrames`, `FocusBracketingStepSize`, `FocusBracketingDelayTime`, `FocusBracketingIntervalTime`, `FocusBracketingStrategy`, `FocusBracketingExitOption`, and `BracketingDelayTime` across `configstore`, `msg2dbus`, `camera-daemon`, and `victory-gui`.
* **New Lens Stepping & Jam Diagnostics in `camera-daemon` and `msg2dbus`:**
  * Added `Initial step lens av:`, `Step lens av:`, `Lens has driven into FAR wall`, `Lens has driven into NEAR wall`, `Lens is JAMMED, counter:`, `HasLongFocusTime`, and `HasMicrofocusAdjust`.
* **OpenGL Overexposure Warning Shader in `victory-gui`:**
  * Added GLSL fragment shader checking `bool overexposed = tex.r > 0.994 || tex.g > 0.994 || tex.b > 0.994;`.

### D) `v1.22.0` → `v1.24.0` (`2020-01-29`, Build 33 → 38) – **New XCD Lens Support**
* Version `v1.23.0` was skipped publicly (internal builds 34–37 were not released).
* **Fine 4 µm Relative Focus Stepping (`onMoveRelativePos4umFailed`, `Step lens distance:`):**
  * Added in `camera-daemon` and `msg2dbus` to support newer XCD lenses (such as the XCD 45P and XCD 35-75).
* **New `video_framerate` Parameter** (`video_framerate_minval`, `video_framerate_maxval`) in `configstore`.
* Updated H6 body firmware (`CBM_1601450_PVF-10.1.25.hex` → `CBM_1601450_PVF-10.1.43.hex`).

### E) `v1.24.0` → `v1.25.0` (`2020-10-22`, Build 38 → 42) – **Final Maintenance Release**
* Final firmware release for the 1st-generation X1D-50c.
* **The Linux kernel (`gf7d0ab5`), `victory-gui` (`2,210,236` B), `camera-daemon` (`329,604` B), `configstore` (`201,000` B), `bodystate-daemon` (`248,260` B), and `phocus-daemon` (`516,408` B) have the exact same size as in `v1.24.0`!** Not a single line of QML UI changed between `v1.24.0` and `v1.25.0`.
* **What actually changed in `v1.25.0`:**
  1. **`SUC` Microcontroller Firmware (`camera-control`):** grew from `241,424` B (`d681156`) to `241,708` B (`666e0d4`).
  2. **`msg2dbus` Bridge:** grew by `880` bytes (`438,460` B → `439,340` B, git commit `6786840` → `89fe624`) to communicate with the updated `SUC` firmware and newer lenses.
  3. **FPGA (`FARM`), USB (`FX3`), and Power (`SPC`) Builds:** bumped to `v1.25.0` build tags.
