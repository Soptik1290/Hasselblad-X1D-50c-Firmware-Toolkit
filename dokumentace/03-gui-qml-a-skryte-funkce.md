# 03 – Grafické rozhraní (`victory-gui`), QML a skryté funkce

## 1. Architektura GUI (`victory-gui`)

Hlavní uživatelské rozhraní fotoaparátu tvoří ELF 32-bit ARM binárka `/usr/bin/victory-gui` (`2 210 236` bajtů).
* Běží nad kompozitorem **Weston (Wayland)** se dvěma hlavními okny:
  * **`main`** (`640×480` px) – zadní dotykový displej (`TouchWindow.qml` načítaný z `main.qml`).
  * **`overlay`** (`1024×768` px) – elektronický hledáček EVF / HDMI výstup (`liveview/EVFWindow.qml`).
* Veškerá prezentační logika, obrazovky, menu a mapování tlačítek jsou zkompilované přímo uvnitř binárky `victory-gui` jako **Qt Resource System (`qrc://`)** na těchto offsetech:
  * **Tabulka jmen (`names`):** `0x1D7E44`
  * **Strom adresářů (`tree`):** `0x1DC7F0`
  * **Datové bloky (`data`):** `0x0FC7F8` (jednotlivé soubory jsou komprimované pomocí `zlib`)

Pomocí skriptu [`extract_victory_qrc.py`](../extract_victory_qrc.py) jsme z `victory-gui` vyextrahovali do složky [`victory_gui_qml/`](../victory_gui_qml) celkem **405 souborů**:
* **128× `.qml`** (všechny obrazovky, dialogy, živý náhled, menu)
* **9× `.js`** (definice menu pro jednotlivé modely a mapy kláves)
* **267× `.png`** (ikony a grafické prvky)
* **1× `.ttf`** (písmo)

### Jak `victory-gui` rozlišuje modely fotoaparátů v QML
V souboru [`victory_gui_qml/settings/scripts/MenuItemImporter.js`](../victory_gui_qml/settings/scripts/MenuItemImporter.js) a v jednotlivých QML komponentách se používá C++ objekt `guiconfig`:
* `guiconfig.isWedge` → **`true` na Hasselblad X1D-50c** (načítá [`MenuItemSpecificationsWedge.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js) a [`KeyMapsWedge.js`](../victory_gui_qml/scripts/KeyMapsWedge.js)).
* `guiconfig.isAlbatross` → `true` na H6D-100c / A6D-100c ([`MenuItemSpecificationsA6D.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsA6D.js)).
* CFV stěna používá [`MenuItemSpecificationsCFV.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsCFV.js) a standardní H6D-50c [`MenuItemSpecifications.js`](../victory_gui_qml/settings/scripts/MenuItemSpecifications.js).

---

## 2. Skryté servisní menu přímo ve foťáku (Easter Egg bez úpravy FW)

V souboru [`victory_gui_qml/settings/SettingsGeneric.qml`](../victory_gui_qml/settings/SettingsGeneric.qml) (řádky `944`–`1012`) se nachází vestavěný Easter Egg:

1. V menu **General Settings → About** je položka **`Firmware: 1.25.0`** (`name: "versionID"`) definovaná jako `SettingType.TEXTBUTTON` (nikoliv obyčejný text!).
2. Kliknutí na tento řádek volá C++ metodu:
   ```javascript
   case "versionID":
       guiconfig.wantToSeeFWUpdateRetryClicked();
       break;
   ```
3. Po opakovaném poklepání na řádek **`Firmware: 1.25.0`** se přepne vlastnost `guiconfig.showSecretMenuItems = true` a zobrazí se vyskakovací okno:
   > **"Additional functions now available in Service Menu"**
4. V menu **General Settings → Service** ([`MenuItemSpecificationsWedge.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js), řádky `261`–`265`) se tím zpřístupní 3 skryté položky chráněné podmínkou `validCheck: "guiconfig.showSecretMenuItems"`:
   * **Demo Mode → Deactivate Storage (`farm.ram_only_mode`)** – přepne fotoaparát do režimu focení pouze do RAM bez zápisu na SD kartu.
   * **Additional Functions → Firmware Update Retry (`guiconfig.fwUpdateRetry`)** – vynutí zopakování aktualizace firmwaru.
   * **Additional Functions → Scroll Wheel Handling (`guiconfig.thumbwheel_mode`)** – přepíná způsob vyhodnocování kroků předního a zadního rolovacího kolečka.

---

## 3. Schované režimy ostření: `Continuous Focus (AF-C)` a `True Focus (AF-T)`

V souboru [`victory_gui_qml/components/popups/PopoverFocusMode.qml`](../victory_gui_qml/components/popups/PopoverFocusMode.qml) (řádky `61`–`142`), který vykresluje výběr režimu ostření (po stisku tlačítka `AF/MF`), zůstal v produkčním firmwaru zapomenutý komentář švédských vývojářů (`OBS!` = švédsky *Observera!*, tedy *Pozor!*):

```qml
// OBS!!!! Temporarily remove items from wedge for demo. Remove "grid_model_wedge" and expression below when done
model: guiconfig.isWedge ? grid_model_wedge : grid_model
```

* **`grid_model`** obsahuje všechny 4 režimy ostření:
  1. `Manual Focus` (`Config.Focus_MAN`)
  2. `Single Focus` (`Config.Focus_AFS`)
  3. **`Continuous Focus` (`Config.Focus_AFC`)**
  4. **`True Focus` (`Config.Focus_AFT`)**
* **`grid_model_wedge`** (který se vybírá na X1D-50c kvůli `guiconfig.isWedge`) obsahuje pouze první dva (`Manual Focus` a `Single Focus`).
* Pouhou změnou řádku `62` v `PopoverFocusMode.qml` na `model: grid_model` se v UI X1D-50c odemknou tlačítka pro **Continuous Focus (`AF-C`)** a **True Focus (`AF-T`)**, které při kliknutí zapisují `Camera.FocusMode = Config.Focus_AFC` / `Config.Focus_AFT`.

---

## 4. Schované položky v nastavení označené `demo: true`

V souboru [`victory_gui_qml/settings/SettingsGeneric.qml`](../victory_gui_qml/settings/SettingsGeneric.qml) (řádek `60`) se při načítání položek menu uplatňuje filtr:
```javascript
var isDemo = (typeof v.demo !== 'undefined') && (v.demo !== undefined) && v.demo;
...
if (isValid && isEnabled && (!isDemo || !guiconfig.hideDemoItems)) {
    listModel.append(...)
}
```
Protože je v produkčním buildu `guiconfig.hideDemoItems == true`, všechny položky v [`MenuItemSpecificationsWedge.js`](../victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js) označené příznakem `demo: true` jsou v menu X1D-50c skryté (a když se zobrazí, vykreslí se u nich červený indikátor `DemoMarker.qml`).

### Přehled všech skrytých (`demo: true`) položek v `MenuItemSpecificationsWedge.js`:

| Sekce v menu | Interní název (`name`) | Text v menu (`text1`) | Proxy objekt | Poznámka |
| :--- | :--- | :--- | :--- | :--- |
| **Camera → Autofocus** | `af_fir` | `AF prefilter` | `configstore` | Ladicí volba AF filtru |
| **Camera → Autofocus** | `af_log` | `Save AF sequence` | `configstore` | Ukládání sekvence ostření do logu |
| **Camera → Autofocus** | `af_full_scan` | `AF debug scan` | `configstore` | Plný debug sken rozsahu ostření |
| **Camera → Autofocus** | `fpga_debug` | `Brenner` | `configstore` | Výběr algoritmu ostření v FPGA (Brenner) |
| **Camera → Autofocus** | `DebugAfSpeedEnable` | `Enable AF Speed` | `configstore` | Povolení vlastní rychlosti AF motoru |
| **Camera → Autofocus** | `DebugAfSpeed` | `AF Speed` | `configstore` | Volba rychlosti krokování AF (obdoba Speed Buffu z X2D!) |
| **Camera → Autofocus** | `DebugAfMode` | `AF Mode` | `configstore` | Ladicí režim AF |
| *(zakomentováno)* | `CustomOption_ZoomOnFocusRing` | `Auto Zoom in MF` | `configstore` | Automatické přiblížení náhledu při otočení ostřicím prstencem! |
| **Camera → Quality** | `jpg_size` | `JPG Size` (`MP`) | `configstore` | Volba rozlišení generovaných JPEGů |
| **Camera → Quality** | `image_noise` | `Noise Filter` | `configstore` | Redukce šumu |
| **Camera → Quality** | `compress_3fr` | `Compressed 3FR` | `configstore` | Komprese RAW souborů `.3FR` |
| **Camera → Custom Buttons** | `Userbutton_AELockFunction` | `AE-L` | `configstore` | Přeprogramování tlačítka `AE-L` |
| **Camera → Custom Buttons** | `Userbutton_AFDriveFunction` | `AF-D` | `configstore` | Přeprogramování tlačítka `AF/MF` |
| **Camera → Configuration** | `CustomOption_RearApertureWheel` | `Front Wheel in M` | `configstore` | Prohození funkce předního/zadního kolečka v režimu M |
| **Camera → Configuration** | `CustomOption_HideBTmode` | `Hide B/T Mode` | `configstore` | Skrytí režimů Bulb / Time |
| **Camera → Configuration** | `CustomOption_AElockAtHalfpress` | `AE-L when Half-pressed` | `configstore` | Uzamčení expozice při namáčknutí spouště |
| **Camera → Live View** | `cameraSettingsLiveView` | `Live View` (`Overlay`) | `configstore` | Celá podsekce Live View v menu Camera |
| **Camera → Image Info** | `textForImage` | `Text` | – | Vkládání vlastního textového štítku k fotkám |
| **Video → Quality** | `video_noise` | `Noise Filter` | `configstore` | Redukce šumu ve videu |
| **Video → Audio** | `audioMode`, `audioLevel` | `Mode`, `Level` | – | Nastavení mikrofonu a úrovně zvuku u videa |
| **General → Display** | `contrast` | `Contrast` | – | Posuvník kontrastu displeje |
| **General → Display** | `Eyesensor_Distance` | `Eye Sensor Distance` | `configstore` | Citlivost / vzdálenost senzoru přiblížení oka u EVF |
| **General → GPS** | `gpsOn` | `GPS` | – | Přepínač GPS |

---

## 5. RAW kalibrační obrazovka (`DebugCam.qml`)

V kořeni QML zdrojů se nachází [`victory_gui_qml/DebugCam.qml`](../victory_gui_qml/DebugCam.qml), která přímo ovládá vlastnost `farm.rawprocessing_mode` na obrazovém FPGA (`FARM`) a umožňuje přepnout výstup senzoru do 7 režimů:
* `0`: `Normal` (běžný zkalibrovaný obraz)
* `1`: `Uncalibrated` (surový nezkalibrovaný výstup ze senzoru)
* `2`: `GC Map`
* `3`: `Offset Map` (mapa temného proudu / offsetů)
* `4`: `ETC Map`
* `5`: `Gain Map` (mapa zesílení pixelů / flat-field)
* `6`: `Blemish Map` (mapa vadných pixelů a sloupců)

---

## 6. Jak lze QML v `victory-gui` bezpečně upravovat a testovat

1. **Patchování QML přímo v binárce `victory-gui`:**
   * Protože jsou QML soubory uvnitř `victory-gui` uložené jako `zlib`-komprimované bloky v sekci `DATA_BASE = 0x0FC7F8`, lze kterýkoliv `.qml` nebo `.js` soubor upravit a zkomprimovat zpět na stejný offset (pokud se nová komprimovaná velikost vejde do slotu původního souboru – případně s `zlib` úrovní komprese `9` a odmazáním komentářů v QML, kterých je tam spousta!).
2. **Spuštění upraveného `victory-gui` z RAM / `/media/data` bez přepisování systému:**
   * Jak dokumentuje projekt `YuHaoyua/hasselblad-x1d-reverse-engineering`, na běžícím fotoaparátu (přes USB diagnostický kanál `sutest-daemon`) není nutné hned přeflashovávat `rootfs`. Stačí nahrát upravenou binárku do `/media/data/victory-gui` (musí se jmenovat `victory-gui`, aby ji Weston správně spároval s oknem), zastavit systémovou službu a spustit ji ručně:
     ```sh
     systemctl stop victory-gui
     XDG_RUNTIME_DIR=/tmp WAYLAND_DISPLAY=wayland-0 QT_QPA_PLATFORM=wayland /media/data/victory-gui -platform wayland
     ```
   * Po restartu fotoaparátu opět naběhne původní nedotčený `/usr/bin/victory-gui` z read-only oddílu.
