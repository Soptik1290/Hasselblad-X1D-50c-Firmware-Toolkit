# 04 – Moduly pro odemknutí skrytých a nových funkcí UI (`MOD-FEAT-01` až `MOD-FEAT-06`)

Díky tomu, že modul **`MOD-CORE-LITE`** uvolnil **+78 397 B komprimovaného prostoru v QRC tabulce** binárky `/usr/bin/victory-gui` (včetně +1 893 B v `SettingsGeneric.qml`, +1 255 B v `MenuItemSpecificationsWedge.js` a +1 268 B v `ControlScreen.qml`), můžeme v budoucí aplikaci nabídnout jedním kliknutím odemknutí skrytých továrních funkcí i přidání zcela nových nástrojů.

---

## Přehled modulů v kategorii Funkce & Rozšíření UI

| ID Modulu | Název v budoucí aplikaci | Co modul odemkne / přidá | Spotřeba QRC slotu |
| :--- | :--- | :--- | :--- |
| **`MOD-FEAT-01`** | **Odemknutí skrytých voleb kvality, tlačítek a AF (`demo: true`)** | Odemkne `Compressed 3FR`, `JPG Size`, `Noise Filter`, `Eye Sensor Distance`, mapování tlačítek `AE-L` / `AF-D`, `Front Wheel in M`, `Hide B/T Mode`, `AE-L when Half-pressed` a inženýrské ladění AF. | `SettingsGeneric.qml: −22 B` |
| **`MOD-FEAT-02`** | **Trvalé odemknutí tajného `Service` menu (`showSecretMenuItems`)** | Bez nutnosti zadávat servisní gesto zpřístupní `Scroll Wheel Handling`, `Firmware Update Retry` a `Deactivate Storage (RAM-Only Mode)`. | `SettingsGeneric.qml: −18 B` |
| **`MOD-FEAT-03`** | **Diagnostický panel FPGA RAW map (`DebugCam.qml`) v menu Service** | Přidá do menu přepínač výstupu senzoru/FPGA (`Normal`, `Uncalibrated`, `GC Map`, `Offset Map`, `ETC Map`, `Gain Map`, `Blemish Map`). | `MenuItemSpecificationsWedge.js: +65 B` |
| **`MOD-FEAT-04`** | **Čítač závěrky těla a telemetrie přímo v menu `About`** | Zobrazí celkový počet expozic těla i objektivu a detailní revize koprocesorů přímo na první stránce `About`. | `MenuItemSpecificationsWedge.js: +48 B` |
| **`MOD-FEAT-05`** | **Vlastní akcentová barva rozhraní / Noční Astro režim (`hblOrange`)** | Umožní změnit tovární oranžovou `#de4200` na libovolnou barvu (např. tmavě červenou `#990000` pro noční astrofotografii, zlatou nebo azurovou). | `GlobalConstants.qml: 0 B` |
| **`MOD-FEAT-06`** | **Volitelná kompoziční mřížka v LiveView (3×3, 4×4, 6×6 a tloušťka 1 px)** | Umožní změnit pevnou mřížku `liveViewGridCount: 3` a zjemnit linku z `2 px` na `1 px`. | `GlobalConstants.qml: 0 B` |

---

## `MOD-FEAT-01`: Odemknutí skrytých voleb kvality, tlačítek a AF (`demo: true`)

### Technický rozbor
V souboru [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js) je 17 plně naprogramovaných položek označeno příznakem `demo: true`. V [`victory_gui_qml/settings/SettingsGeneric.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/SettingsGeneric.qml#L50-L53) je na řádku 53 podmínka:
```javascript
if (isValid && isEnabled && (!isDemo || !guiconfig.hideDemoItems))
```
Protože C++ vlastnost `guiconfig.hideDemoItems` vrací v produkčním režimu `true`, jsou tyto položky před uživatelem skryté!

### Jaké položky jsou v `MenuItemSpecificationsWedge.js` skryté pod `demo: true`?
1. **Menu Quality (`cameraSettingsQuality`, řádky 226–229):**
   - `compress_3fr` (**Compressed 3FR** – bezztrátově komprimovaný RAW!)
   - `image_noise` (**Noise Filter** – úroveň redukce šumu)
   - `jpg_size` (**JPG Size [MP]** – rozlišení generovaného JPEG)
2. **Menu Custom Buttons (`cameraSettingsCustomButtons`, řádky 100–101):**
   - `Userbutton_AELockFunction` (přeprogramování fyzického tlačítka **AE-L**)
   - `Userbutton_AFDriveFunction` (přeprogramování tlačítka **AF-D**)
3. **Menu Configuration (`cameraSettingsConfiguration`, řádky 107–109):**
   - `CustomOption_RearApertureWheel` (**Front Wheel in M** – prohození předního a zadního rolleru v režimu M)
   - `CustomOption_HideBTmode` (**Hide B/T Mode** – skrytí režimů Bulb/Time při točení kolečkem času)
   - `CustomOption_AElockAtHalfpress` (**AE-L when Half-pressed** – uzamčení expozice při namáčknutí spouště)
4. **Menu Display (`generalSettingsDisplay`, řádek 141):**
   - `Eyesensor_Distance` (**Eye Sensor Distance** – citlivost senzoru přiblížení oka u EVF hledáčku)
5. **Menu Video Quality (`videoSettingsVideoQuality`, řádek 124):**
   - `video_noise` (**Noise Filter** pro video)
6. **Menu Autofocus (`cameraSettingsAutofocus`, řádky 52–58 – volitelné jako samostatný pod-přepínač „AF Engineering Debug“):**
   - `af_fir` (`AF prefilter`), `af_log` (`Save AF sequence`), `af_full_scan` (`AF debug scan`), `fpga_debug` (`Brenner`), `DebugAfSpeedEnable` (`Enable AF Speed`), `DebugAfSpeed` (`AF Speed`), `DebugAfMode` (`AF Mode`).

> [!WARNING]
> **Hardwarový limit `DebugAfSpeed` v `/usr/bin/configstore` (`3000 .. 20000`):**
> Ačkoliv rozbalovací seznam v `SettingsMiddleLayer` (`/usr/bin/victory-gui` na `0x82b90`) vypisuje hodnoty `7000` až `31000`, disassembling binárky `/usr/bin/configstore` (`0x13d68..0x13de0`) prokázal, že démon kontroluje přísný rozsah `DebugAfSpeed_minval = 3000` a `DebugAfSpeed_maxval = 20000` (výchozí hodnota `5000`). Jakýkoliv výběr `21000..31000` v menu `configstore` odmítne a ponechá předchozí hodnotu. Nejvyšší platná volba v menu je proto **`19000`** (nebo přímý zápis `20000` z QML), což zrychlí krokový motor XCD objektivů **3,8× až 4,0×**.

### Co je třeba změnit
V aplikaci Builder lze buď:
- **Varianta A (Globální odemknutí):** V [`victory_gui_qml/settings/SettingsGeneric.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/SettingsGeneric.qml#L53) změnit řádek 53:
  ```javascript
  // Původní:
  if (isValid && isEnabled && (!isDemo || !guiconfig.hideDemoItems)) {
  // Nový:
  if (isValid && isEnabled) {
  ```
  a v [`victory_gui_qml/components/controls/FavoriteAddSelector.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/components/controls/FavoriteAddSelector.qml#L46) změnit řádek 46:
  ```javascript
  if((v.settingsList !== "") && !favoriteModel.isInList(v.settingsList))
  ```
- **Varianta B (Výběrové odemknutí jednotlivých položek v Builderu):** V [`MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js) změnit `demo: true` -> `demo: false` pouze u těch položek, které si uživatel v aplikaci zaškrtne.

---

## `MOD-FEAT-02`: Trvalé odemknutí tajného `Service` menu (`showSecretMenuItems`)

### Technický rozbor
V [`MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L177-L181) jsou v sekci `generalSettingsService` 4 položky chráněné podmínkou `validCheck: "guiconfig.showSecretMenuItems"`:
- `ram_only_mode` (**Deactivate Storage** – testovací režim bez zápisu na SD kartu)
- `fwUpdateRetry` (**Firmware Update Retry** – vynucení opakování aktualizace firmwaru)
- `thumbwheel_mode` (**Scroll Wheel Handling** – nastavení chování a směru otáčení koleček)

### Co je třeba změnit
V [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L177-L181) odstranit atribut `, validCheck: "guiconfig.showSecretMenuItems"` z řádků 177, 178, 180 a 181.

---

## `MOD-FEAT-03`: Diagnostický panel FPGA RAW map (`DebugCam.qml`)

### Technický rozbor
V QRC stromu binárky `/usr/bin/victory-gui` se nachází hotová obrazovka [`victory_gui_qml/DebugCam.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/DebugCam.qml), která přímo ovládá C++ vlastnost `farm.rawprocessing_mode` (FPGA čip Kintex-7) a umožňuje přepínat surový výstup senzoru mezi 7 režimy:
- `0`: `Normal` (standardní vyvolávání)
- `1`: `Uncalibrated` (nekalibrovaná surová data ze senzoru IMX161)
- `2`: `GC Map`
- `3`: `Offset Map` (mapa temného proudu / offsetů)
- `4`: `ETC Map`
- `5`: `Gain Map` (mapa zesílení kanálů)
- `6`: `Blemish Map` (mapa vadných pixelů senzoru uložená v kalibraci!)

### Co je třeba změnit
V [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L208-L222) přidat do pole `settingsMenuItems` novou položku:
```javascript
{settingsList: "generalSettingsDebugCam", itemText: "RAW Sensor Maps", itemFile: "qrc:///DebugCam.qml", largeIcon: "LargeIconService"},
```

---

## `MOD-FEAT-04`: Přímé zobrazení počtu expozic a diagnostiky v `About`

### Technický rozbor
V [`MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L183-L194) je čítač expozic `lensCounter` (`proxy: suc`) schovaný v podmenu `Usage`. Přesunutím přímo do `generalSettingsAbout` a doplněním dalších vlastností objektů `prodinfo`, `system` a `suc` uvidí fotograf všechny informace na jediné obrazovce bez proklikávání.

### Co je třeba změnit
- **Soubor:** [`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js#L183-L190)
- Přidat řádek `{editType: SettingType.TEXT, name: "lensCounter", text1: qsTranslate("MENUS", "Lens: "), proxy: suc}` přímo do pole `generalSettingsAbout`.

---

## `MOD-FEAT-05`: Vlastní akcentová barva rozhraní / Noční Astro režim (`hblOrange`)

### Technický rozbor
Veškeré zvýrazněné prvky, aktivní ikony, rámečky, posuvníky a tlačítka v celém rozhraní X1D-50c přebírají barvu z jediné konstanty v [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L14-L15):
```qml
readonly property color hblOrange: "#de4200"
readonly property color hblOrangeDark: "#852800"
```
V budoucí aplikaci si tak uživatel může pomocí Color Pickeru nebo předvoleb zvolit:
- **Hasselblad Orange (Výchozí):** `#de4200` / `#852800`
- **Astro Deep Red (Pro noční focení bez oslnění očí):** `#991100` / `#550800`
- **Monochrome Silver / White:** `#d0d0d0` / `#707070`
- **Cyan Tech:** `#0099cc` / `#005577`

---

## `MOD-FEAT-06`: Volitelná kompoziční mřížka v LiveView (`liveViewGridCount` & `liveViewGridLineWidth`)

### Technický rozbor
V [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L130-L131) a [` GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L43) je kompoziční mřížka v LiveView nastavena natvrdo na třetiny s tlustou 2px čárou:
```qml
readonly property color liveViewGridColor : "white"
readonly property int liveViewGridCount : 3
readonly property int liveViewGridLineWidth : 2
```

### Co je třeba změnit
V aplikaci Builder nabídnout přepínače:
- **Hustota mřížky (`liveViewGridCount`):** `3` (Třetiny), `4` (Čtvrtiny + středový kříž), `6` (Architektonická mřížka 6×6).
- **Tloušťka linky (`liveViewGridLineWidth`):** `1` (jemná 1px linka, která neruší při ostření) nebo `2` (tovární).
- **Barva mřížky (`liveViewGridColor`):** `"#80ffffff"` (poloprůhledná bílá) místo plné `"white"`.
