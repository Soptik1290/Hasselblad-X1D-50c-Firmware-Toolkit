# 00 – Architektura a specifikace budoucí aplikace „X1D Custom Firmware Builder“

Tento dokument slouží jako kompletní návrhová specifikace pro stavbu grafické aplikace (webové nebo desktopové), ve které si uživatel načte výchozí tovární firmware [`X1D_v1_25_0.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0.cim), v reálném čase uvidí stav všech pamětí fotoaparátu a nakliká si požadované úpravy (odlehčená verze, zrychlení startu a UI, úspora baterie, odemknutí skrytých funkcí), ze kterých aplikace automaticky sestaví a ověří vlastní `.cim` firmware.

---

## 1. Základní princip fungování aplikace

```
[ Výchozí X1D_v1_25_0.cim (63,41 MB) ]
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 1. Rozbalení do pracovní mezipaměti (Baseline Cache)     │
│    • rootfs.tar.bz2 -> /usr/bin/victory-gui + systém     │
│    • 405 QRC slotů (128 QML, 9 JS, 267 PNG)              │
└──────────────────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 2. Konfigurátor modulů (Uživatelské rozhraní)            │
│    • [x] MOD-CORE-LITE (Odlehčená X1D-only verze)        │
│    • [x] MOD-SPD-01..06 (Zrychlení startu a odezvy UI)   │
│    • [x] MOD-BAT-01..05 (Úspora baterie a snížení tepla) │
│    • [x] MOD-FEAT-01..06 (Odemknutí skrytých funkcí)     │
│    • Živé ukazatele paměti (QRC Pool, eMMC, RAM)         │
└──────────────────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────┐
│ 3. Kompilátor & 5stupňová Anti-Brick brána               │
│    • Aplikace patchů na QML/JS a systémové soubory       │
│    • Zápis QRC slotů (zlib-9) do /usr/bin/victory-gui    │
│    • Přebalení rootfs.tar.bz2 se zachováním symlinků     │
│    • Zašifrování .cim (AES-128-CBC + dvou-fázové MD5)    │
│    • Automatický běh verify_firmware_safety.py           │
└──────────────────────────────────────────────────────────┘
                 │
                 ▼
[ Výstupní X1D_v1_25_0_custom.cim + Přímý test v UI Simulátoru ]
```

---

## 2. Živé ukazatele paměti v aplikaci (Memory & Storage Gauges)

Aplikace musí uživateli zobrazovat **přesné limity pamětí**, protože každá úprava v GUI se musí vejít do pevně daných binárních QRC slotů uvnitř ELF binárky `/usr/bin/victory-gui`.

### 2.1 Hlavní paměťové ukazatele (Gauges)

| Ukazatel v UI | Pevný limit (Kapacita) | Tovární `v1.25.0` | Po zapnutí `X1D Lite` | Co ukazatel hlídá |
| :--- | ---: | ---: | ---: | :--- |
| **1. Celkový QRC Pool (`DATA_BASE`)** | `898 636 B` | `898 634 B` (`99,99 %`) | `820 239 B` (`91,28 %`, **+78 397 B volných**) | Součet komprimovaných velikostí všech 405 QRC zdrojů v `/usr/bin/victory-gui` (`0x0FC7F8..0x1D7E44`). |
| **2. Jednotlivé QRC sloty (405×)** | Dle offsetu souseda | `0 B` rezerva u většiny | **+6 B až +6 254 B** na soubor | Každý z 137 QML/JS souborů má v binárce svůj vlastní maximální slot `slot_size(idx)`. Žádný soubor nesmí přetéct svůj slot! |
| **3. eMMC Root (`root_a` / `root_b`)** | `536 870 912 B` (512 MB) | `158 250 622 B` (`29,48 %`) | `132 113 291 B` (`24,61 %`, **−26,14 MB**) | Celková nekomprimovaná velikost souborů v `rootfs.tar.bz2`. |
| **4. Velikost `.cim` kontejneru** | ~`100 000 000 B` (RAM `/tmp`) | `63 410 176 B` (`60,47 MB`) | `54 358 016 B` (`51,84 MB`, **−8,63 MB**) | Během aktualizace se `.cim` rozbaluje do RAM/eMMC; menší `.cim` = rychlejší flashování. |
| **5. Operační paměť DDR3 RAM** | `536 870 912 B` (512 MB) | ~`193 986 560 B` (`36,1 %`) | ~`180 500 000 B` (`33,6 %` s vypnutými démony) | Odhad obsazení RAM běžícími démony, Wayland/Weston framebufferem a QML enginem. |
| **6. Neměnné kritické oddíly (LOCKED)** | `uboot` (`269 312 B`), `hbl-upgrade` (`7 783 B`), `hbl-kks-revisions` (`7 030 B`) | `100 % Factory Match` | `100 % Factory Match` | V UI svítí zeleným zámkem **"Anti-Brick Protected"** – builder na tyto 3 komponenty nikdy nesahá. |

### 2.2 Kritické QRC sloty, které musí aplikace sledovat v detailním grafu

Při přidávání nových funkcí do QML/JS je nutné hlídat volné bajty (`zlib` level 9) v těchto klíčových souborech:

| QRC Soubor | Pevná velikost slotu v ELF | Tovární `zlib-9` (Volno) | Po zapnutí `X1D Lite` (Volno) | Které moduly tento slot využívají |
| :--- | ---: | ---: | ---: | :--- |
| `common/TouchWindow.qml` | `18 120 B` | `17 056 B` (`+1 064 B`) | `11 866 B` (**`+6 254 B`**) | `MOD-SPD-04`, `MOD-SPD-05`, `MOD-BAT-03` |
| `mainmenu/MainScreen.qml` | `9 128 B` | `7 662 B` (`+1 466 B`) | `5 666 B` (**`+3 462 B`**) | Vlastní tlačítka na hlavní obrazovce |
| `main.qml` | `8 676 B` | `7 662 B` (`+1 014 B`) | `5 926 B` (**`+2 750 B`**) | `MOD-SPD-03`, mapování kláves |
| `settings/SettingsGeneric.qml` | `9 968 B` | `8 958 B` (`+1 010 B`) | `8 075 B` (**`+1 893 B`**) | `MOD-FEAT-01`, `MOD-FEAT-03` |
| `controlscreen/ControlScreen.qml` | `8 157 B` | `7 444 B` (`+713 B`) | `6 889 B` (**`+1 268 B`**) | `MOD-FEAT-04` (teplota na stavové obrazovce) |
| `settings/scripts/MenuItemSpecificationsWedge.js` | `6 052 B` | `5 299 B` (`+753 B`) | `4 797 B` (**`+1 255 B`**) | `MOD-FEAT-01`, `MOD-FEAT-02`, `MOD-FEAT-03` |
| `liveview/LiveViewOverlay.qml` | `9 359 B` | `8 602 B` (`+757 B`) | `7 812 B` (**`+1 547 B`**) | `MOD-SPD-06`, `MOD-FEAT-04` |
| `common/GlobalConstants.qml` | `3 740 B` | `3 206 B` (`+534 B`) | `2 595 B` (**`+1 145 B`**) | `MOD-SPD-04`, `MOD-BAT-02`, `MOD-BAT-03`, `MOD-FEAT-05`, `MOD-FEAT-06` |

> [!IMPORTANT]
> **Proč musí být `MOD-CORE-LITE` (Odlehčená verze) doporučeným základem v aplikaci?**
> Bez zapnutí `MOD-CORE-LITE` (nebo alespoň odstranění komentářů) mají některé soubory jen pár stovek bajtů rezervy. Zapnutím `MOD-CORE-LITE` se v hlavních souborech uvolní **1 100 až 6 250 bajtů komprimovaného místa** (což odpovídá **4 až 25 KB nového zdrojového kódu QML/JS** v každém souboru).

---

## 3. Datový model modulu pro budoucí aplikaci (JSON Schema)

Každé „tlačítko / přepínač“ v budoucí aplikaci bude definováno jako samostatný deklarativní modul s tímto schématem:

```json
{
  "id": "MOD-SPD-01",
  "category": "speed",
  "title": "Rychlý start dotyku, senzorů a LiveView po zapnutí",
  "recommended": true,
  "requires": [],
  "summary": "Zkrátí časovač systemd late.timer ze 7 s na 2 s, takže dotykový displej, senzor přiblížení EVF a LiveView démon naskočí o 5 sekund dříve po zapnutí fotoaparátu.",
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
      "label": "Prodleva spuštění late.timer po startu (s)",
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

## 4. Kritická technická pravidla z reálného ARMv7 běhu (Povinné pro Builder)

Při ladění a ověřování custom firmwaru v reálném ARMv7 Linux emulátoru ([`run_arm_emulator.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/run_arm_emulator.py) s nativními binárkami `/usr/bin/victory-gui`, `/usr/bin/configstore` a `libappscommon.so.1.0.0`) jsme odhalili **4 zásadní nízkoúrovňové vlastnosti platformy Hasselblad Umbrella**, které musí budoucí aplikace **Custom Firmware Builder** (a všechny její moduly) striktně dodržovat. Všechna tato pravidla jsou zároveň automaticky hlídána v 1. fázi testu [`verify_firmware_safety.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/verify_firmware_safety.py).

### 4.1 Pravidlo 1: Duální Wayland okna (`TouchWindow.qml` vs. `EVFWindow.qml`)
- **Příčina:** Binárka `/usr/bin/victory-gui` vytváří po startu dvě samostatné Wayland `QQuickWindow` plochy:
  1. `TouchWindow` (`title: "main"`, rozlišení `640×480` – zadní dotykový LCD displej).
  2. `EVFWindow` (`title: "overlay"`, rozlišení `1024×768` – OLED hledáček / HDMI výstup), načítané asynchronně přes `Loader { id: evfWindow }` v [`main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml) přibližně **2,7 sekundy po startu** (`onMainWindowReady` -> `evfWindow.active = true`).
- **Past v továrním kódu:** V továrním [`liveview/EVFWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/EVFWindow.qml) je nastaveno `visible: true` i ve chvíli, kdy `showContent == false` (tj. když se uživatel nedívá do EVF). V továrním [`main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml) má navíc `Loader { id: evfWindow }` nastaveno `visible: active`. Na jednoobrazovkovém Wayland kompozitoru (nebo při přepnutí fokusované plochy) se tak po 2,7 s přes `640×480` dotykovou obrazovku vykreslí neviditelné `1024×768` okno `EVFWindow`, které zachytává veškeré události myši, dotyku a klávesnice (`Event filter installed for EVF`).
- **Povinné řešení v každém buildu:**
  1. V [`victory_gui_qml/liveview/EVFWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/EVFWindow.qml) vždy nastavit:
     ```qml
     visible: showContent
     visibility: showContent ? Window.FullScreen : Window.Hidden
     ```
  2. V [`victory_gui_qml/main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml) nastavit u `Loader { id: evfWindow }` vlastnost `visible: false` a po dokončení inicializace (`if (allLoaded)`) zavolat `mainWindow.item.requestActivate()`.
  3. Soubor `liveview/EVFWindow.qml` musí být zahrnut v každém samostatném modulu (včetně `MOD-FEAT-AFC`).

### 4.2 Pravidlo 2: Qt 5.4 `QQmlConnectionsParser` a C++ signály s velkým počátečním písmenem
- **Příčina:** V knihovně `/usr/lib/libappscommon.so.1.0.0` (kompilované proti Qt 5.4 QML parseru) mají některé `Q_PROPERTY` ve třídách `CameraProxy` a `ConfigStoreProxy` svůj `NOTIFY` signál pojmenovaný **s velkým počátečním písmenem**:
  - `CameraProxy`: `FocusModeChanged`, `WBModeChanged`, `DriveModeChanged`, `LMModeChanged`, `SVChanged`, `EVADJChanged`, `FLASH_EVADJChanged`, `AEB_EVADJChanged`
  - `ConfigStoreProxy`: `BracketingDelayTimeChanged`, `FocusBracketingStepSizeChanged`
- **Past v Qt 5.4:** Prvek `Connections { target: Camera; onFocusModeChanged: ... }` v Qt 5.4 vyžaduje, aby první znak po prefixu `on` odpovídal signálu s malým počátečním písmenem. Pokud C++ signál začíná velkým písmenem (`FocusModeChanged`), `QQmlConnectionsParser` vyhodí fatální chybu při načítání `main.qml`:
  `qrc:///main.qml: QML Connections: Cannot assign to non-existent property "onFocusModeChanged"`.
- **Povinné řešení:** Nikdy nepoužívat `on<UppercaseSignal>:` uvnitř bloku `Connections {}`. Místo toho v QML komponentě vytvořit vlastnost s malým počátečním písmenem navázanou na C++ property a reagovat na její změnu (ta se připojuje přes `QMetaProperty::notifySignalIndex()` a funguje 100% spolehlivě):
  ```qml
  property int currentFocusMode: Camera.FocusMode
  onCurrentFocusModeChanged: {
      // Spolehlivě reaguje na změnu Camera.FocusMode!
  }
  ```

### 4.3 Pravidlo 3: Tvrdé limity v `/usr/bin/configstore` vs. položky v `SettingsMiddleLayer`
- **Příčina:** Disassembling binárky `/usr/bin/configstore` na adresách `0x13d68..0x13de0` ukázal, že démon při startu registruje u každé číselné vlastnosti trojici `(default, minval, maxval)`. U vlastnosti **`DebugAfSpeed`** jsou v binárce `/usr/bin/configstore` pevně zakódovány tyto hodnoty:
  - `DebugAfSpeed` výchozí hodnota (`[r4, #0x590]`): **`5000`** (`0x1388`)
  - `DebugAfSpeed_minval` (`[r4, #0x594]`): **`3000`** (`0x0bb8`)
  - `DebugAfSpeed_maxval` (`[r4, #0x598]`): **`20000`** (`0x4e20`)
- **Past v továrním GUI:** V `/usr/bin/victory-gui` (`SettingsMiddleLayer` na `0x82b90`) vývojáři v Göteborgu vypsali do textového dropdownu řadu `7000, 9000, 11000, 13000, 15000, 17000, 19000, 21000, 23000, 25000, 27000, 29000, 31000`. Jakoukoliv hodnotu **`> 20000`** však `/usr/bin/configstore` odmítne s varováním:
  `"Property DebugAfSpeed could not be set to new value: 27000. Using current value 5000"`!
- **Povinné řešení:** V QML kódu i v budoucí aplikaci Builder nabízet pro `DebugAfSpeed` výhradně hodnoty v intervalu **`3000` až `20000`**. Nejvyšší platná hodnota z továrního dropdownu je **`19000`** (případně přímý integer **`20000`**), což zrychlí krokový motor XCD objektivů **3,8× až 4,0×** oproti výchozím `5000`.

### 4.4 Pravidlo 4: Přesné D-Bus signatury démonů `com.hasselblad.*`
- Při emulaci nebo volání D-Bus metod z vlastních skriptů je nutné dodržet přesné signatury z `libappscommon.so.1.0.0`:
  - `com.hasselblad.camera.setLiveViewState` má signaturu **`"bs"`** (`bool state, QString receiver`), nikoliv `"b"`.
  - `com.hasselblad.camera.StartSession` má signaturu **`"bb"`** (`bool showLiveViewWhenFinished, bool forceFindFocus`).
  - `com.hasselblad.cambody` exportuje kromě objektu `/cambody` také objekt `/spiritlevel` (rozhraní `com.hasselblad.spiritlevel`, metoda `do_spiritlevel(ib)`) a na `/cambody` metodu `do_hts_polling(b)`.
  - `com.hasselblad.lens` (`/lens`) musí pro `MOD-FEAT-AFC` exportovat `video_focus_pos_state`, `af_cmd_relative_position_4um`, `af_cmd_position` a `af_cmd_speed` (volané z QML přes `Lens.focusUpdateState`, `Lens.moveRelativePos4um`, `Lens.moveAbsolutePos`, `Lens.moveAtSpeed`).

### 4.5 Pravidlo 5: Nikdy neřídit kontinuální ostření opakovaným `startSession()`
- **Příčina:** Každé `Camera.startSession(showLiveView, true)` vede přes `ImageProxy::findFocus` na `image_find_focus_req` v `af_service.c` čipu `FARM`, který vždy provede **slepý dvouhranový průjezd** celého AF rozsahu.
- **Past:** V emulátoru to vypadá funkčně, ale na reálném těle objektiv neustále přejíždí přes ostrost (*full-sweep hunting*) – viz archivovaný [`X1D_v1_25_0_afc_old.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0_afc_old.cim).
- **Povinné řešení:** Po úvodním zámku řídit objektiv mikrokroky `Lens.moveRelativePos4um()` s hradlováním (`GATE_HOLD`, práh poklesu `4,5 %`) a porovnáním rychlosti poklesu levé/pravé strany (*Peak Drop Rate*). [`verify_firmware_safety.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/verify_firmware_safety.py) v 1. fázi kontroluje přítomnost tokenů `Lens.moveRelativePos4um`, `Lens.focusUpdateState`, `onMoveRelativePos4umResult`, `rLeft`, `rRight`, `afcTargetPos`.

> [!WARNING]
> **Emulátor nedokazuje funkčnost na reálném fotoaparátu.** [`mock_hardware_dbus.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/arm_emulator/mock_hardware_dbus.py) simuluje kontrast fyzikálním modelem (`OpticalCdafSimulator`); skutečné chování `FARM` / XCD objektivu (zejména zda odpověď `af_cmd_relative_position_4um` nese hodnotu kontrastu) je nutné ověřit na hardwaru.

---

## 5. Přehled všech dokumentů v této složce

1. **[`01-modul-odlehcena-verze-x1d-lite.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/01-modul-odlehcena-verze-x1d-lite.md)**
   Detailní rozbor základního modulu **`MOD-CORE-LITE`** (odstranění komentářů a cizích modelů H6D/A6D/CFV) a realistické zhodnocení jeho přínosů.
2. **[`02-moduly-rychlost-boot-a-odezva-ui.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/02-moduly-rychlost-boot-a-odezva-ui.md)**
   Katalog 6 modulů (**`MOD-SPD-01`** až **`MOD-SPD-06`**) pro zrychlení náběhu fotoaparátu, okamžité zapnutí dotykového displeje, odstranění 200ms prodlevy LiveView, zrychlení animací a vypnutí debug logování.
3. **[`03-moduly-vydrz-baterie-a-chlazeni.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/03-moduly-vydrz-baterie-a-chlazeni.md)**
   Katalog 5 modulů (**`MOD-BAT-01`** až **`MOD-BAT-05`**) pro reálné prodloužení výdrže baterie a snížení zahřívání těla X1D-50c (odpojení Wi-Fi čipu BCM4356 a démonů na pozadí, zkrácení timeoutu 50MP senzoru v LiveView, úsporné podsvícení a redukce framebufferů).
4. **[`04-moduly-skryte-a-nove-funkce-ui.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/04-moduly-skryte-a-nove-funkce-ui.md)**
   Katalog 6 modulů (**`MOD-FEAT-01`** až **`MOD-FEAT-06`**) pro odemknutí skrytých továrních funkcí (`Compressed 3FR`, `Noise Filter`, `JPG Size`, `Eye Sensor Distance`, `AF Debug/Speed`, `RAM-Only Demo Mode`, `DebugCam` RAW mapy FPGA, čtení teplot a vlastní barevná témata UI).
5. **[`05-modul-continuous-autofocus-afc.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/05-modul-continuous-autofocus-afc.md)**
   Samostatný modul **`MOD-FEAT-AFC`** (**Continuous Autofocus `AF-C` + Touch-to-Track**), postavený přímo nad výchozím továrním firmwarem `1.25.0` ([`firmware/X1D_v1_25_0_afc.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0_afc.cim)). Obsahuje rešerši X2D 100C toolkitů (*HRAP*), disassembling `WedgeStateMachine` v `/usr/bin/camera-daemon`, rozpletení Dual-QSPI firmwaru čipu `FARM` (Zynq-7000, `af_service.c`), rozhraní `LensProxy` (`Lens.moveRelativePos4um`) a 5stavový **Gated CDAF + Peak Drop Rate** engine (`63 270 912 B`). Starý prototyp s cyklováním `stopSession/startSession` je archivován jako [`firmware/X1D_v1_25_0_afc_old.cim`](file:///d:/Plocha/projekty/X1D_FirmwareDump/firmware/X1D_v1_25_0_afc_old.cim) (na reálném těle způsobuje *full-sweep hunting*).
