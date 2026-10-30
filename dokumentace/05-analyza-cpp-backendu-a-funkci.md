# 05 – Hloubková analýza C++ backendu a skrytých funkcí (QML ↔ D-Bus ↔ Daemony)

V kapitole `03-gui-qml-a-skryte-funkce.md` jsme v rozbaleném QML rozhraní (`victory_gui_qml/`) objevili desítky skrytých položek menu (označených příznakem `demo: true`, schovaných za vlastností `guiconfig.showSecretMenuItems` nebo odfiltrovaných podmínkou `guiconfig.isWedge`).

Abychom zjistili, **které z těchto funkcí mají ve firmwaru X1D-50c (`v1.25.0`) skutečnou funkční implementaci v C++** a které jsou pouze neaktivní pozůstatky ze zrcadlovky H6D (`Victory`), provedli jsme statickou analýzu všech klíčových ELF binárek z `rootfs`:

1. **`/usr/bin/victory-gui`** (`2 210 236 B`) – Qt5/QML grafické rozhraní a C++ třída `SettingsMiddleLayer`, která překládá textové volby v menu na číselné a boolean hodnoty.
2. **`/usr/bin/configstore`** (`243 600 B`) – centrální D-Bus úložiště (`se.hasselblad.configstore`), které drží aktuální stav, výchozí hodnoty a limity (`_minval` / `_maxval`) všech parametrů a ukládá je na flash.
3. **`/usr/bin/msg2dbus`** (`536 052 B`) – hardwarový most, který překládá D-Bus vlastnosti z `configstore` do binárních paketů pro **SUC** (`SucHandler` – System Microcontroller, objektiv, závěrka, tlačítka, eye-sensor) a **FARM** (`FarmHandler` – snímací FPGA, čtení senzoru, výpočet kontrastu ostření).
4. **`/usr/bin/camera-daemon`** (`457 436 B`) – hlavní stavový automat fotoaparátu (`Camera` a pro X1D specifická třída `WedgeStateMachine`).
5. **`/usr/bin/bodystate-daemon`** (`227 572 B`) – obsluha fyzických GPIO tlačítek, koleček a stavů těla (`GPIOKeys`, `StateManager`).
6. **`/usr/bin/storage-daemon`** (`568 188 B`) – ukládání snímků 3FR/JPG na SD karty (`ConfigstoreProxy`).

---

## 1. Jak funguje řetězec zpracování nastavení v X1D

Každé nastavení v menu prochází přesně čtyřmi vrstvami:

```
[QML Menu (MenuItemSpecificationsWedge.js / SettingsGeneric.qml)]
       │  (čte/zapisuje Q_PROPERTY na C++ objektu `settings`)
       ▼
[victory-gui: C++ třída SettingsMiddleLayer]
       │  (převádí text z QML, např. "21000", na int/bool a volá ConfigstoreProxy)
       ▼
[configstore (D-Bus: se.hasselblad.configstore)]
       │  (kontroluje _minval/_maxval, ukládá do profilu a vysílá D-Bus signál *Changed)
       ├───────────────────────────────┬──────────────────────────────┐
       ▼                               ▼                              ▼
[bodystate-daemon]             [camera-daemon]                 [msg2dbus]
(GPIOKeys: mapování            (WedgeStateMachine:             (SucHandler / FarmHandler:
 fyzických tlačítek)            expozice, ostření, LV)          posílá příkazy do MCU a FPGA)
```

Pokud má skrytá položka v QML kompletní implementaci ve všech čtyřech vrstvách, **její odemknutí v QML okamžitě funguje na reálném hardwaru**.

---

## 2. Souhrnná matice všech skrytých funkcí podle binárek

| QML vlastnost (`settings.*` / `guiconfig.*`) | Název v menu | `victory-gui` (`SettingsMiddleLayer`) | `configstore` (D-Bus + uložení) | `msg2dbus` (`Suc`/`Farm` HW most) | Ostatní daemony (`bodystate` / `camera` / `storage`) | Verdikt na X1D-50c |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **`showSecretMenuItems`** | *Easter Egg v About* | **ANO** | — | — | Volá `/usr/bin/prodconfig-tool` | **Plně funkční (bez úpravy FW!)** |
| **`thumbwheel_mode`** | *Scroll Wheel Handling* | **ANO** (`Original` / `Adjusted`) | **ANO** | **ANO** (`SucHandler`) | `/usr/bin/prodconfig-tool` | **Plně funkční (součást Easter Eggu)** |
| **`Userbutton_AELockFunction`** | *AE-L Button* (Custom Buttons) | **ANO** (33 funkcí) | **ANO** | **ANO** | **ANO** (`GPIOKeys::onUserbutton_AELockFunction`) | **100% funkční po odemknutí v QML** |
| **`Userbutton_AFDriveFunction`** | *AF-D Button* (Custom Buttons) | **ANO** (33 funkcí) | **ANO** | **ANO** | **ANO** (`GPIOKeys::onUserbutton_AFDriveFunction`) | **100% funkční po odemknutí v QML** |
| **`CustomOption_RearApertureWheel`** | *Front Wheel in M* | **ANO** (`Aperture` / `Shutterspeed`) | **ANO** | **ANO** (`SucHandler`) | Řeší SUC mikrokontrolér | **100% funkční po odemknutí v QML** |
| **`CustomOption_HideBTmode`** | *Hide B/T Mode* | **ANO** (`boolean`) | **ANO** | **ANO** (`SucHandler`) | **ANO** (`camera-daemon` `ConfigstoreProxy`) | **100% funkční po odemknutí v QML** |
| **`CustomOption_AElockAtHalfpress`** | *AE-L when Half-pressed* | **ANO** (`boolean`) | **ANO** | **ANO** (`SucHandler`) | Řeší SUC mikrokontrolér | **100% funkční po odemknutí v QML** |
| **`Eyesensor_Distance`** | *Eye Sensor Distance* | **ANO** (`Short` / `Medium` / `Long`) | **ANO** | **ANO** (`SucHandler`) | Řeší SUC mikrokontrolér | **100% funkční po odemknutí v QML** |
| **`DebugAfSpeedEnable`** + **`DebugAfSpeed`** | *AF Speed Debug / Value* | **ANO** (`7000` až `31000`, krok 2000) | **ANO** | **ANO** (`af_cmd_speed`) | Řídí rychlost krokového motoru XCD objektivu | **100% funkční (experimentální ladění AF)** |
| **`fpga_debug`** | *Brenner* (algoritmus kontrastu) | **ANO** (`x + y`, `x + y/4`, `x + y/2`) | **ANO** | **ANO** (`FarmHandler`) | Nastavuje registr Brennerova filtru v FPGA | **100% funkční (experimentální ladění AF)** |
| **`af_fir`** / **`af_log`** / **`af_full_scan`** | *AF FIR / AF Log / AF Full Scan* | **ANO** (`boolean`) | **ANO** | **ANO** (`FarmHandler`) | Parametry kontrastního AF v FPGA/SUC | **100% funkční (experimentální ladění AF)** |
| **`DebugAfMode`** | *AF Mode Debug* | **ANO** (`boolean`) | **ANO** | **ANO** (`SucHandler`) | Ladicí režim AF | **100% funkční (experimentální ladění AF)** |
| **`compress_3fr`** | *Compressed 3FR* | **ANO** (`boolean`) | **ANO** | **ANO** (`FarmHandler`) | **ANO** (`storage-daemon` `compress_3frChanged`) | **Funkční v daemonech (testovat opatrně)** |
| **`jpg_size`** | *JPG Size* (`12.8 MP` vs plné) | **ANO** (`Quarter` / `Full`) | **ANO** | **ANO** (`FarmHandler`) | **ANO** (`storage-daemon` `jpg_sizeChanged`) | **Funkční v daemonech** |
| **`rawprocessing_mode`** | *Raw Processing Mode* | **ANO** (`Full` / `DS2`) | **ANO** | **ANO** (`FarmHandler`) | Downsampling senzoru v FPGA | **Experimentální (inženýrské menu)** |
| **`Focus_AFC`** / **`Focus_AFT`** | *AF-C* a *True Focus* | **ANO** (`PopoverFocusMode.qml`) | **ANO** | Posílá do `SucHandler` | **NE v `WedgeStateMachine`** (chová se jako `AF-S`) | **Neaktivní na X1D (chybí H6D gyro/PD modul)** |
| **`contrast`** / **`textForImage`** / **`audioMode`** | *Contrast / Text / Audio* | Jen prázdné Q_PROPERTY | **NE** | **NE** | **NE** | **Neimplementováno (čisté UI placeholdery)** |

---

## 3. Detailní rozbor jednotlivých kategorií

### Kategorie A: Vestavěný Easter Egg (funguje ihned bez úpravy firmwaru!)

Při analýze `SettingsGeneric.qml` (řádek 951) a binárky `victory-gui` (`GuiConfiguration::wantToSeeFWUpdateRetryClicked()`) jsme narazili na oficiální inženýrský Easter Egg:

- **Jak ho aktivovat přímo na foťáku**:
  1. Otevři **Menu → General Settings (ozubené kolečko) → About**.
  2. Opakovaně klepej prstem na řádek **`Firmware: 1.25.0`** (`versionID`).
  3. Po naklepání se nastaví `guiconfig.showSecretMenuItems = true`.
  4. Vrať se o úroveň výš a otevři **Service**: objeví se 3 nové skryté položky!

Co tyto 3 položky v C++ dělají:
1. **`Scroll Wheel Handling`** (`guiconfig.thumbwheel_mode`):
   - V `victory-gui` volá externí systémový nástroj `/usr/bin/prodconfig-tool --thumbwheel-mode` a zapisuje do `configstore` (`thumbwheel_mode`).
   - Přepíná odezvu předního a zadního příkazového kolečka mezi **`Original`** a **`Adjusted`** (upravený debouncing/krok koleček).
2. **`Deactivate Storage`** (`settings.ram_only_mode`):
   - Nastavuje v `configstore` a `FarmHandler` vlastnost `farm.ram_only_mode`, kdy fotoaparát při focení neukládá soubory na SD kartu, ale drží je pouze v RAM (používáno při továrním testování závěrky/senzoru).
3. **`Firmware Update Retry`** (`guiconfig.fwUpdateRetry`):
   - Umožňuje vynutit opakování instalace firmwaru.

---

### Kategorie B: 100% funkční uživatelské funkce skryté příznakem `demo: true`

Tyto položky mají v C++ daemonech kompletně dokončenou implementaci pro X1D (`Wedge`), ale v souboru `MenuItemSpecificationsWedge.js` u nich vývojáři nechali příznak `demo: true` (protože v produkčním buildu je `guiconfig.hideDemoItems == true`).

#### 1. Přeprogramování tlačítek `AE-L` a `AF-D` (`Userbutton_AELockFunction` & `Userbutton_AFDriveFunction`)
- Ve výchozím stavu umožňuje X1D v sekci **Custom Buttons** měnit pouze tlačítko `ISO/WB` (`Userbutton_IsoWbFunction`).
- V `MenuItemSpecificationsWedge.js` (řádky 164–165) jsou však definována i tlačítka **AE-L** a **AF-D**, pouze mají `demo: true`.
- **Důkaz z `bodystate-daemon`**:
  V tabulce symbolů `/usr/bin/bodystate-daemon` existují metody:
  - `GPIOKeys::onUserbutton_IsoWbFunction(int)` (adresa `0x160a8`)
  - `GPIOKeys::onUserbutton_AELockFunction(int)` (adresa `0x160c0`)
  - `GPIOKeys::onUserbutton_AFDriveFunction(int)` (adresa `0x160b4`)
- Všechny tři čtou z `configstore` stejný číselník 33 akcí (`True Focus`, `Focus Assist`, `AE Lock`, `AF Drive`, `Drive Mode`, `Crop Mode`, `Mirror Up`, `Exposure Sim`, `Start Liveview`, `Zoom In` atd.). Stačí v `MenuItemSpecificationsWedge.js` smazat `demo: true` (nebo v `SettingsGeneric.qml` vypnout `hideDemoItems`) a obě tlačítka lze na X1D plně přeprogramovat.

#### 2. Prohození koleček v režimu M (`CustomOption_RearApertureWheel` – „Front Wheel in M“)
- Umožňuje vybrat, zda přední kolečko v manuálním režimu `M` ovládá **`Aperture`** (clonu) nebo **`Shutterspeed`** (čas závěrky).
- V `victory-gui` (`SettingsMiddleLayer::setCustomOption_RearApertureWheel`) se hodnota převádí na boolean, ukládá do `configstore` a přes `msg2dbus` (`SucHandler`) posílá přímo do mikrokontroléru těla.

#### 3. Skrytí režimu B/T (`CustomOption_HideBTmode`) a AE-L při namáčknutí (`CustomOption_AElockAtHalfpress`)
- **`Hide B/T Mode`**: propisuje se až do `camera-daemon` (`ConfigstoreProxy::CustomOption_HideBTmodeChanged(bool)`), kde vyřadí Bulb/Time z běžného vytáčení časů závěrky.
- **`AE-L when Half-pressed`**: uzamkne expozici při namáčknutí spouště (standardní funkce, kterou uživatelé X1D často postrádali).

#### 4. Citlivost senzoru přiblížení u hledáčku (`Eyesensor_Distance`)
- V `MenuItemSpecificationsWedge.js` (řádek 233) je schovaná položka **Eye Sensor → Distance** s volbami **`Short`**, **`Medium`**, **`Long`**.
- V `victory-gui` (`SettingsMiddleLayer::setEyesensor_Distance`) se překládá na hodnoty `0`, `1`, `2`, ukládá se v `configstore` (`Eyesensor_Distance_minval` / `_maxval`) a `msg2dbus` ji zapisuje do SUC mikrokontroléru, který čte IR senzor u EVF hledáčku.

---

### Kategorie C: Inženýrské ladění autofokusu (FPGA & XCD objektivy)

Nejunikátnější nález v celém firmwaru X1D-50c se skrývá v `SettingsGeneric.qml` (řádky 703–825). Protože X1D-50c používá kontrastní ostření (CDAF) počítané v čipu **FARM FPGA** a krokový motor v objektivech řady XCD, vývojáři si v GUI nechali kompletní ladicí panel autofokusu (skrytý za `!guiconfig.hideDemoItems`):

1. **`DebugAfSpeedEnable` + `DebugAfSpeed` (Rychlost motoru autofokusu)**:
   - V `SettingsMiddleLayer` (`victory-gui`, offset `0x1bf2d8`) je definováno 13 diskrétních rychlostí:
     `7000`, `9000`, `11000`, `13000`, `15000`, `17000`, `19000`, `21000`, `23000`, `25000`, `27000`, `29000`, `31000`.
   - `msg2dbus` tuto hodnotu posílá přes kanál **`af_cmd_speed`** (offset `0x53597` v `msg2dbus`) přímo do řadiče objektivu XCD!
2. **`fpga_debug` („Brenner“ – vážení kontrastní metriky v FPGA)**:
   - Brennerův gradient je matematická funkce, podle které FPGA vyhodnocuje ostrost obrazu v ostřícím bodě.
   - `SettingsMiddleLayer` umožňuje přepínat vzorec mezi **`x + y`**, **`x + y/4`** a **`x + y/2`** (kombinace horizontálního a vertikálního kontrastu).
3. **`af_fir`**, **`af_log`**, **`af_full_scan`**, **`DebugAfMode`**:
   - Všechny čtyři přepínače mají své D-Bus vlastnosti v `configstore` i obsluhu v `msg2dbus` (`0x4e284..0x4e29c`).
   - `af_full_scan` vynutí projetí celého rozsahu objektivu, `af_fir` zapíná FIR filtr nad křivkou kontrastu a `af_log` zapíná logování průběhu ostření.

---

### Kategorie D: Komprese 3FR a velikost JPG (`compress_3fr`, `jpg_size`, `rawprocessing_mode`)

- V `storage-daemon` existují metody `ConfigstoreProxy::compress_3frChanged(bool)` a `ConfigstoreProxy::jpg_sizeChanged(hblm_resolutions)`.
- V `victory-gui` (`SettingsMiddleLayer`) se `jpg_size` překládá mezi plným rozlišením (`Full`) a čtvrtinovým **`12.8 MP`** (`Quarter`).
- `rawprocessing_mode` přepíná čtení senzoru mezi **`Full`** a **`DS2`** (downsampling v FPGA).

---

### Kategorie E: Proč na X1D nefunguje `AF-C` a `True Focus` (`Focus_AFC`, `Focus_AFT`)

V souboru `PopoverFocusMode.qml` (řádek 62) je přepínání modelů:
```qml
model: guiconfig.isWedge ? grid_model_wedge : grid_model
```
Zatímco `grid_model_wedge` obsahuje pouze **AF-S** (`Focus_AFS = 1`) a **MF** (`Focus_MAN = 3`), plný `grid_model` obsahuje navíc **AF-C** (`Focus_AFC = 2`) a **True Focus** (`Focus_AFT = 6`).

Co se stane, když v QML povolíme `grid_model` i pro X1D?
- Zde nám dala přesnou odpověď dekompilace metod `WedgeStateMachine::checkFocusMode()` (adresa `0x32860` v `/usr/bin/camera-daemon`) a `Camera::onFocusModeChanged()` (adresa `0x21524`):
  ```armasm
  ; WedgeStateMachine::checkFocusMode() (0x32860 v camera-daemon)
  0x3286c: ldrb r3, [r3, #0x1c]   ; načti FocusMode
  0x32870: cmp  r3, #3            ; je FocusMode == 3 (Focus_MAN)?
  0x32874: beq  0x328bc           ; pokud ano -> rovnou exponuj bez AF (WedgeStateMachine::expose)
  0x3287c: bl   Camera::focusMode ; načti efektivní FocusMode z třídy Camera
  0x32880: cmp  r0, #3            ; je FocusMode == 3 (Focus_MAN)?
  0x32884: beq  0x328bc           ; pokud ano -> rovnou exponuj bez AF
  ...
  0x328a8: b    WedgeStateMachine::findFocus ; jinak (pro JAKÝKOLIV jiný režim) spusť jednorázové CDAF ostření!
  ```
- **Závěr**: Třída `WedgeStateMachine` v `camera-daemon` testuje pouze to, zda je `FocusMode == 3` (`Focus_MAN`) nebo `!= 3`. Režimy `AF-C` a `True Focus` jsou určeny pro zrcadlovku **H6D** (`Victory`), kde fázové ostření a gyroskopický výpočet True Focusu provádí procesor v těle zrcadlovky (`cambody`). Na X1D-50c se proto po odemknutí ikonek `AF-C` a `True Focus` v menu oba režimy při focení chovají identicky jako běžné jednorázové ostření **`AF-S`**.

---

## 4. Nejlepší kandidáti na první vlastní modifikaci (Mod Pack)

Pokud chceš vytvořit čistou a praktickou úpravu firmwaru pro svůj X1D-50c, největší přínos mají tyto dvě úpravy, které odemknou reálně fungující C++ funkce:

1. **Odemknutí všech `demo: true` položek v `SettingsGeneric.qml`**:
   - V souboru `victory_gui_qml/SettingsGeneric.qml` na řádku 704 změnit:
     ```qml
     // Původní:
     visible: !guiconfig.hideDemoItems
     // Upravené:
     visible: true
     ```
   - A v `victory_gui_qml/MenuItemSpecificationsWedge.js` odstranit příznak `demo: true` u položek:
     - **AE-L** a **AF-D** v sekci *Custom Buttons* (řádky 164–165),
     - **Front Wheel in M**, **Hide B/T Mode**, **AE-L when Half-pressed** (řádky 193–211),
     - **Eye Sensor Distance** (řádek 233).
2. **Nebo ještě jednodušeji**:
   - V `SettingsGeneric.qml` připnout viditelnost skrytých položek na vestavěný Easter Egg (`guiconfig.showSecretMenuItems`)! Díky tomu zůstane menu po zapnutí fotoaparátu 100% originální a inženýrské/skryté volby se v menu objeví až ve chvíli, kdy v `About` naklikáš na verzi firmwaru `1.25.0`.
