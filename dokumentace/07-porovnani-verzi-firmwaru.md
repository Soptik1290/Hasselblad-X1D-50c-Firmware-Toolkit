# 07 – Porovnání všech 6 verzí firmwaru (`v1.20.0` až `v1.25.0`)

Ve složce [`firmware/`](../firmware/) máme k dispozici všech 6 oficiálně vydaných verzí firmwaru pro 1. generaci **Hasselblad X1D-50c** z let 2017–2020. Díky kompletní sadě obrazů jsme mohli:
1. Zpětně ověřit **dvoufázový algoritmus `PrivateHeader::Checksum`** (`0x2d6ac` v `upgrade-daemon`) na 6 nezávislých vzorcích se **100% shodou**.
2. Porovnat vývoj jednotlivých komponent (`hbl-upgrade`, `rootfs`, `uboot`, `hbl-kks-revisions`), linuxového jádra, podřízených mikrokontrolérů (`FARM`, `FX3`, `SPC`, `SUC`, `CBM`) i hlavních démonů (`victory-gui`, `camera-daemon`, `msg2dbus`, `configstore`, `bodystate-daemon`).

---

## 1. Souhrnná tabulka všech 6 kontejnerů `.cim`

| Soubor | Datum a čas sestavení (UTC) | Build # | Velikost `.cim` (B) | Odvozené AES `IV` | `PrivateHeader::Checksum` (`0x90..0x9F`) | Velikost `rootfs` (B) | Souborů v `rootfs` |
| :--- | :--- | :---: | ---: | :--- | :--- | ---: | :---: |
| **`X1D_v1_20_0.cim`** | `2017-12-13 15:59:09` | `21` (`0x15`) | `59 395 584` | `dc7c152e27d6b180758c448358e08dd8` | `5cdcc27bb0b2202612b17104ab78042a` | `59 108 701` | `1 906` |
| **`X1D_v1_20_1.cim`** | `2018-01-17 11:02:54` | `22` (`0x16`) | `59 372 032` | `781f94b639923a83024271804f1e153f` | `642b8e6426d9562135d0217b7e592684` | `59 085 230` | `1 906` |
| **`X1D_v1_21_0.cim`** | `2018-05-02 12:50:37` | `28` (`0x1C`) | `63 267 328` | `b49093bc46c72243ebbf551be59256ee` | `c85aaac91b64ca5df71065b25951d5cd` | `62 980 509` | `1 982` |
| **`X1D_v1_22_0.cim`** | `2019-01-18 13:15:52` | `33` (`0x21`) | `63 388 672` | `c804487e305fbbf1f0dd12a7e5c35259` | `cb5b29ca3025517e457795c7829e3a81` | `63 101 461` | `1 982` |
| **`X1D_v1_24_0.cim`** | `2020-01-29 14:58:01` | `38` (`0x26`) | `63 393 792` | `1e8c760cb8158ed8e22eb6367da18fd2` | `8db8712994a487bd335e185ca35d73eb` | `63 106 664` | `1 982` |
| **`X1D_v1_25_0.cim`** | `2020-10-22 10:23:09` | `42` (`0x2A`) | `63 410 176` | `74d898a2302518ee02bd6e2e76637206` | `e38bfbaaaad214062f18a08415a02145` | `63 123 278` | `1 982` |

> [!IMPORTANT]
> **Tři ze čtyř zabalených položek se za celé 3 roky (`2017`–`2020`) vůbec nezměnily!**
> Ve všech 6 verzích firmwaru jsou soubory `hbl-upgrade`, `uboot` a `hbl-kks-revisions` **bit-po-bitu identické**:
> * **`hbl-upgrade`** (`7 783` B) – solený MD5: `1f2f15a7057ca09c0312abc0f67d1286`
> * **`uboot`** (`269 312` B) – solený MD5: `20aa7676ec112a52f4f5c9b823511cac`
> * **`hbl-kks-revisions`** (`7 030` B) – solený MD5: `29051c03db8772a87c0cbb4a7615fa30`
>
> Veškeré změny napříč verzemi se odehrávaly výhradně uvnitř **`rootfs`** (`rootfs.tar.bz2`).

---

## 2. Vývoj hlavních démonů a knihoven v `/usr/bin` a `/usr/lib`

Následující tabulka ukazuje velikosti (v bajtech) klíčových binárek fotoaparátu v jednotlivých verzích:

| Komponenta | `v1.20.0` | `v1.20.1` | `v1.21.0` | `v1.22.0` | `v1.24.0` | `v1.25.0` |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **`/usr/bin/victory-gui`** (Qt5/QML UI) | `1 959 360` | `1 959 360` | `2 111 012` | `2 206 028` | `2 210 236` | `2 210 236` |
| **`/usr/bin/camera-daemon`** (expozice, AF) | `304 800` | `306 788` | `321 764` | `325 776` | `329 604` | `329 604` |
| **`/usr/bin/msg2dbus`** (SUC ↔ D-Bus most) | `431 432` | `431 432` | `432 748` | `437 708` | `438 460` | `439 340` |
| **`/usr/bin/configstore`** (persisted config) | `176 204` | `176 204` | `196 904` | `198 768` | `201 000` | `201 000` |
| **`/usr/bin/bodystate-daemon`** (tlačítka, stav) | `240 136` | `240 136` | `244 040` | `244 040` | `248 260` | `248 260` |
| **`/usr/bin/phocus-daemon`** (USB/Wi-Fi Phocus) | `504 268` | `504 268` | `514 800` | `515 160` | `516 408` | `516 408` |
| **`/usr/bin/metadata-daemon`** (EXIF/3FR tagy) | `272 152` | `272 152` | `272 936` | `274 912` | `275 536` | `275 536` |
| **`/usr/bin/storage-daemon`** (SD karty) | `412 540` | `412 540` | `414 228` | `414 228` | `414 228` | `414 228` |
| **`/usr/lib/libappscommon.so.1.0.0`** | `643 552` | `643 552` | `680 804` | `703 480` | `705 704` | `705 704` |
| **`/usr/lib/libAppsMessaging.so`** | `90 904` | `90 904` | `95 332` | `99 620` | `99 648` | `99 648` |
| **Rozbalený `rootfs` celkem** | `152 279 384` | `152 289 780` | `158 067 276` | `158 209 668` | `158 249 458` | `158 250 622` |

---

## 3. Vývoj jádra Linuxu a firmwarů koprocesorů (`/lib/firmware/hbl/`)

Každá verze `.cim` obsahuje v `/lib/firmware/hbl/` obrazy pro interní FPGA a mikrokontroléry fotoaparátu, které při aktualizaci přepisuje skript `/usr/bin/program_nodes.sh`:

| Verze `.cim` | Kernel (`zImage-3.14.28-1.0.0_ga+yocto+...`) | FPGA `FARM` (`wedge`) | USB 3.0 `FX3` (`wedge`) | Napájení `SPC` (`power-control`) | Hlavní MCU `SUC` (`camera-control`) | H6 tělo (`CBM_1601450`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`v1.20.0`** | `g1b67c6d` | `v1.20.0-10362-5d8dfe8` (`3 938 060` B) | `v0.0-11564-c9b598c` (`159 668` B) | `v1.20.0-12005-dfa6068` (`47 903` B) | `v1.20.0-12199-1a36e7c` (`229 940` B) | `PVF-10.1.25.hex` (`251 790` B) |
| **`v1.20.1`** | `gd7b0c67` | `v1.20.1-11028-5d8dfe8` (`3 938 060` B) | `v0.0-12230-c9b598c` (`159 668` B) | `v1.20.1-12671-dfa6068` (`47 903` B) | `v1.20.1-12866-cb6bc7e` (`229 940` B) | `PVF-10.1.25.hex` (`251 790` B) |
| **`v1.21.0`** | `gccd2bfe` | `v1.21.0-12791-7fe179c` (`3 954 444` B) | `v0.0-13997-a2fd843` (`159 968` B) | `v1.21.0-14434-3e3093c` (`48 235` B) | `v1.21.0-14632-539bea7` (`237 724` B) | `PVF-10.1.25.hex` (`251 790` B) |
| **`v1.22.0`** | `gfd90cea` | `v1.22.0-12991-4e2988a` (`3 954 444` B) | `v0.0-14186-03b4b80` (`160 160` B) | `v1.22.0-14621-92d0c2f` (`48 427` B) | `v1.22.0-14821-e75cc87` (`240 744` B) | `PVF-10.1.25.hex` (`251 790` B) |
| **`v1.24.0`** | `gf7d0ab5` | `v1.24.0-13062-c3532e4` (`3 954 444` B) | `v0.0-14255-3e63462` (`160 188` B) | `v1.24.0-14690-a065c86` (`48 455` B) | `v1.24.0-14890-d681156` (`241 424` B) | `PVF-10.1.43.hex` (`269 520` B) |
| **`v1.25.0`** | `gf7d0ab5` | `v1.25.0-13075-c9bb91d` (`3 954 444` B) | `v0.0-14268-e0ef6ae` (`160 188` B) | `v1.25.0-14703-9b140c9` (`48 455` B) | `v1.25.0-14903-666e0d4` (`241 708` B) | `PVF-10.1.43.hex` (`269 520` B) |

---

## 4. Detailní chronologie změn mezi jednotlivými verzemi

### A) `v1.20.0` → `v1.20.1` (`2018-01-17`, Build 21 → 22)
* **Rychlý hotfix** vydaný měsíc po `v1.20.0`.
* UI (`victory-gui`), `configstore`, `msg2dbus` ani `bodystate-daemon` se vůbec nezměnily.
* Upraven byl pouze **`camera-daemon`** (`304 800` → `306 788` B), diagnostický `sutest-daemon` (`491 932` → `500 476` B), mikrokontrolér **`SUC`** (`1a36e7c` → `cb6bc7e`) a revize jádra (`g1b67c6d` → `gd7b0c67`).

### B) `v1.20.1` → `v1.21.0` (`2018-05-02`, Build 22 → 28) – **Největší funkční skok**
* Počet souborů v `rootfs` vzrostl z `1 906` na `1 982` (`+76` souborů, `+5,8 MB` nekomprimovaně).
* **Zprovoznění zvukové odezvy (Audio / ALSA):**
  * V jádře přibyl ovladač zvukového zesilovače NXP **TFA9882** (`snd-soc-tfa9882.ko` a `snd-soc-hbl-tfa9882.ko`) a zvukového rozhraní `snd-soc-fsl-sai.ko`.
  * V `/usr/bin/` přibyly nástroje `aplay`, `amixer`, `alsaloop`, `alsaucm`, `speaker-test` a knihovny `libsndfile.so.1.0.25` + `libsamplerate.so.0.1.8`.
  * V `/usr/share/sounds/system-sound/` přibylo **46 systémových WAV zvuků** (např. `AF_focus_found.wav`, `AF_focus_not_found.wav`, `KeyClick.wav`, `SelfTimer_count.wav`, `low_batt.wav`, `media_full.wav`, `overexp.wav`, `tethered_connect.wav`).
* **Nové fotografické funkce v `camera-daemon`, `configstore` a `victory-gui`:**
  * **Interval Timer (Časosběr):** `Interval timer`, `IntervalTimerCountDown`, `intervalTimerElapsed()`.
  * **Exposure Bracketing (AEB):** `AEB_EVADJ`, `AEB out of range`, `SequenceMode`.
  * **Hodnocení snímků hvězdičkami (Image Rating):** `ImageRatingPopup`, `ContentModel.setImageRating(path, rating)`.
  * **Rozšíření uživatelských profilů (Profiles 4–7):** předvolby `Full Auto`, `Studio`, `Fill Flash`, `Default`.
  * **Řízení frekvence CPU:** `camera-daemon` začal dynamicky přepínat `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`.
  * V `configstore` přibyl skrytý klíč `DebugAfMode` (`DebugAfMode_minval`, `DebugAfMode_maxval`).

### C) `v1.21.0` → `v1.22.0` (`2019-01-18`, Build 28 → 33) – **Focus Bracketing a diagnostika objektivů**
* **`victory-gui`** narostlo o dalších `95 KB` (`2 111 012` → `2 206 028` B).
* **Focus Bracketing (skládání ostrosti):**
  * V `configstore`, `msg2dbus`, `camera-daemon` a `victory-gui` přibyly vlastnosti `FocusBracketingNumberOfFrames`, `FocusBracketingStepSize`, `FocusBracketingDelayTime`, `FocusBracketingIntervalTime`, `FocusBracketingStrategy`, `FocusBracketingExitOption` a `BracketingDelayTime`.
* **Nová diagnostika krokování clony a ostření objektivů v `camera-daemon` a `msg2dbus`:**
  * Přibyly zprávy `Initial step lens av:`, `Step lens av:`, `Lens has driven into FAR wall`, `Lens has driven into NEAR wall`, `Lens is JAMMED, counter:` a vlastnosti `HasLongFocusTime`, `HasMicrofocusAdjust`.
* **OpenGL shader pro indikaci přepalů (Overexposure warning) v `victory-gui`:**
  * Přibyl GLSL fragment shader vyhodnocující `bool overexposed = tex.r > 0.994 || tex.g > 0.994 || tex.b > 0.994;`.

### D) `v1.22.0` → `v1.24.0` (`2020-01-29`, Build 33 → 38) – **Podpora nových objektivů XCD**
* Verze `v1.23.0` byla přeskočena (interní sestavení 34–37 nebyla veřejně vydána).
* **Podpora jemného krokování ostření po 4 µm (`onMoveRelativePos4umFailed`, `Step lens distance:`):**
  * V `camera-daemon` a `msg2dbus` přibyla podpora pro novější objektivy XCD (např. XCD 45P / XCD 35-75).
* **Nový parametr `video_framerate`** (`video_framerate_minval`, `video_framerate_maxval`) v `configstore`.
* Aktualizován firmware středoformátového těla H6 (`CBM_1601450_PVF-10.1.25.hex` → `CBM_1601450_PVF-10.1.43.hex`).

### E) `v1.24.0` → `v1.25.0` (`2020-10-22`, Build 38 → 42) – **Finální údržbové vydání**
* Poslední vydaný firmware pro první generaci X1D-50c.
* **Linuxový kernel (`gf7d0ab5`), `victory-gui` (`2 210 236` B), `camera-daemon` (`329 604` B), `configstore` (`201 000` B), `bodystate-daemon` (`248 260` B) i `phocus-daemon` (`516 408` B) mají identickou velikost jako ve `v1.24.0`!** V QML uživatelském rozhraní se mezi `v1.24.0` a `v1.25.0` nezměnil ani jediný řádek.
* **Co se ve `v1.25.0` skutečně změnilo:**
  1. **Firmware koprocesoru `SUC` (`camera-control`):** narostl z `241 424` B (`d681156`) na `241 708` B (`666e0d4`).
  2. **Most `msg2dbus`:** narostl o `880` bajtů (`438 460` B → `439 340` B, revize `6786840` → `89fe624`) pro komunikaci s aktualizovaným `SUC` a novými objektivy.
  3. **Sestavení FPGA (`FARM`), USB (`FX3`) a napájení (`SPC`):** povýšeny na build tagy `v1.25.0`.
