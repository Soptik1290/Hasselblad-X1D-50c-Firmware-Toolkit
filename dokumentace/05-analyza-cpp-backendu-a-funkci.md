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
   - V `SettingsMiddleLayer` (`victory-gui`, offset `0x1bf2d8` / `0x82b90`) je v rozbalovacím seznamu definováno 13 diskrétních rychlostí:
     `7000`, `9000`, `11000`, `13000`, `15000`, `17000`, `19000`, `21000`, `23000`, `25000`, `27000`, `29000`, `31000`.
   - **Důležitý nález z `/usr/bin/configstore` (`0x13d68..0x13de0`):** Démon `configstore` má pro `DebugAfSpeed` natvrdo zakódovaný rozsah **`min = 3000`**, **`max = 20000`** (`0x4e20`) a **`default = 5000`**. Hodnoty `21000..31000` démon odmítne (`Property DebugAfSpeed could not be set to new value`). Nejvyšší platná hodnota z menu je proto **`19000`** (nebo přímý integer **`20000`** z QML), což představuje **3,8× až 4,0× zrychlení** oproti výchozím `5000`.
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
- **Závěr (tovární chování vs. náš vlastní `AF-C` engine)**: Třída `WedgeStateMachine` v `camera-daemon` testuje pouze to, zda je `FocusMode == 3` (`Focus_MAN`) nebo `!= 3`. Pokud by se pouze odemkla ikonka `AF-C` v `PopoverFocusMode.qml`, fotoaparát provede jen jedno zaostření a zůstane čekat ve stavu `"Session is idle, starting liveview"`.

---

### Kategorie F: Průlom – Rozpletení Dual-QSPI firmwaru `FARM` (Zynq-7000), `af_service.c` a `Gated CDAF + Peak Drop Rate`

Při hlubším zkoumání `.cim` obrazu jsme narazili na zásadní otázku: **Co přesně se děje uvnitř čipu `FARM` a objektivu XCD, když `WedgeStateMachine::findFocus()` odešle požadavek na ostření (`image_find_focus_req`), a proč prosté opakování `stopSession()` / `startSession()` (archivované v `X1D_v1_25_0_afc_old.cim`) na reálném fotoaparátu způsobuje nepřetržité přeostřování („hunting“)?**

#### 1. Rozpletení Dual-QSPI obrazů čipu `FARM`
V `rootfs` (`/lib/firmware/hbl/farm/`) jsou dva soubory po `3 954 444 B`:
- `bootimage_even-wedge-v1.25.0-13075-c9bb91d.bin` (flashovaný do `/dev/mtd3`)
- `bootimage_odd-wedge-v1.25.0-13075-c9bb91d.bin` (flashovaný do `/dev/mtd4`)

Čip **`FARM`** není jen FPGA, ale **Xilinx Zynq-7000 SoC** (dvoujádrový ARM Cortex-A9 + FPGA) připojený ke dvěma paralelním QSPI flash pamětem v režimu **Dual-Parallel QSPI x8 (bit-interleaved)** – každý bajt obrazu `BOOT.BIN` je rozdělen na **sudé bity (`0, 2, 4, 6`)** v `even` souboru a **liché bity (`1, 3, 5, 7`)** v `odd` souboru.

Po složení vznikne `7 908 888 B` obraz `farm_wedge_boot.bin` (hlavička Xilinx Zynq Boot Image `0xAA995566`, `"XNLX"`) se 3 oddíly:
1. **Partition 0** (`0x001700`, `114 708 B`) – Zynq First Stage Boot Loader (`FSBL`).
2. **Partition 1** (`0x01D740`, `5 979 936 B`) – PL FPGA bitstream s hardwarovým **Brennerovým filtrem ostrosti** (`../src/fpga/autofocus.c`).
3. **Partition 2** (`0x5D1680`, `1 808 280 B`, load adresa `0x00100000`) – ARM Cortex-A9 FreeRTOS aplikace `farm_app.bin`.

#### 2. Stavový automat `../src/services/af_service.c` (`0x198700..0x1A5490`) v `farm_app.bin`
- Stavová struktura AF v RAM na `0x006BB59C`, kruhový buffer kontrastu na `0x006BB5CC`.
- `af_service_update_lenstype` (`0x1987C4..0x199950`) – kalibrační profily objektivů `XCD30/45/90/120` a `HCC24..HCC300`.
- Příkaz `image_find_focus_req` (`AF_SERVICE_SM`, `0x19B870..0x19D174`) provede vždy **slepý dvouhranový průjezd (*Full-Sweep CDAF*)**: `afstate_scan_for_first_edge` (`0x19BEC0`) → `afstate_scan_for_second_edge` (`0x19C054`, úmyslně přejede za vrchol) → `afstate_move_back_over_peak` (`0x19C530`) → `afstate_move_to_final_position` (`0x19C96C`, parabolický fit vrcholu).
- **Proč naivní cyklování `startSession()` na reálném těle selhává:** Každé `StartSession(showLiveView, true)` → `ImageProxy::findFocus` → `image_find_focus_req` vynutí kompletní průjezd přes obě hrany a přepnutí video režimu senzoru. Periodické volání tedy na fyzickém objektivu způsobí neustálé přejíždění přes ostrost tam a zpět (*full-sweep hunting*). Skutečné `AF-C` musí po úvodním zámku řídit čočku mikrokroky.

#### 3. Nízkoúrovňové rozhraní `LensProxy` (`Lens`) v `libappscommon.so.1.0.0`

| QML metoda / signál na `Lens` | C++ symbol | D-Bus metoda (`com.hasselblad.lens`) → IPC do `SUC` | Popis |
| :--- | :--- | :--- | :--- |
| **`Lens.focusUpdateState(bool)`** | `_ZN9LensProxy16focusUpdateStateEb` (`0x4AD94D10`) | `video_focus_pos_state` → `lens_video_focus_pos_state_req` | Kontinuální hlášení pozice ostřící čočky během LiveView. |
| **`Lens.moveRelativePos4um(short)`** | `_ZN9LensProxy18moveRelativePos4umEs` (`0x4AD94F0C`) | `af_cmd_relative_position_4um` → `lens_af_cmd_relative_position_4um_req` | Relativní mikrokrok v násobcích **4 µm** (kladné = Far, záporné = Near) bez spuštění `image_find_focus_req`. |
| **`Lens.onMoveRelativePos4umResult(int)`** | `LensProxy::onMoveRelativePos4umResultFinished` (`0x4AD943D4`) | Asynchronní D-Bus odpověď (`QVariant::toInt()`) | Předá 32bitový `result` přímo do QML. |
| **`Lens.moveAbsolutePos(short)`** | `_ZN9LensProxy15moveAbsolutePosEs` (`0x4AD95108`) | `af_cmd_position` → `lens_af_cmd_position_req` | Přesun na absolutní pozici. |
| **`Lens.moveAtSpeed(short)`** | `_ZN9LensProxy11moveAtSpeedEs` (`0x4AD95304`) | `af_cmd_speed` → `lens_af_cmd_speed_req` | Plynulý pohyb motoru zadanou rychlostí. |

#### 4. Náš algoritmus `Gated CDAF + Peak Drop Rate` (`firmware/X1D_v1_25_0_afc.cim`)
V novém firmwaru **[`firmware/X1D_v1_25_0_afc.cim`](../firmware/X1D_v1_25_0_afc.cim)** (kompletní dokumentace v [`custom_firmware_dokumentace/05-modul-continuous-autofocus-afc.md`](../custom_firmware_dokumentace/05-modul-continuous-autofocus-afc.md)) jsme proto nahradili smyčku `stopSession/startSession` uzavřeným **5stavovým konečným automatem Gated CDAF s porovnáváním rychlosti poklesu kontrastu (Peak Drop Rate)**:

1. **Úvodní zachycení vrcholu (`Initial Peak Lock`):** Po stisku `HALFPRESS` / `AF-D` (nebo klepnutí v LiveView) proběhne jediné úvodní zaostření pro nalezení výchozího vrcholu ostrosti $(x_{\text{peak}}, CV_{\text{peak}})$, aktivuje se `Lens.focusUpdateState(true)` a automat přejde do stavu **`GATE_HOLD` (`1`)**.
2. **Stav 1 – `GATE_HOLD` (Hradlování v klidu):** Dokud relativní pokles kontrastu nepřekročí práh brány (`dropFrac = (afcPeakCv - cv) / afcPeakCv < 4,5 %`), objektiv stojí **zcela v klidu (nulové dýchání/hunting)** a svítí zelený zámek ostrosti. Jakmile se objekt pohne a kontrast klesne o $\ge 4,5\,\%$, automat přejde do stavu **`PROBE_LEFT` (`2`)**.
3. **Stavy 2 & 3 – `PROBE_LEFT` a `PROBE_RIGHT` (Porovnání rychlosti poklesu obou stran – Peak Drop Rate):**
   - Objektiv provede mikrokrok doleva (`-6 × 4 µm = -24 µm`) a změří rychlost poklesu levé strany:
     $$R_L = \frac{CV_{\text{ref}} - CV_L}{\Delta x}$$
   - Následně provede mikrokrok doprava (`+12 × 4 µm`, tj. `+24 µm` od středu) a změří rychlost poklesu pravé strany:
     $$R_R = \frac{CV_{\text{ref}} - CV_R}{\Delta x}$$
   - **Klíčové pravidlo pro pohybující se objekt v reálném čase:** Pokud klesají obě strany současně ($R_L > 0 \land R_R > 0$), **strana, která klesá rychleji ($\max(R_L, R_R)$), se vzdaluje od bodu ostrosti rychleji a je od vrcholu dál – ostření proto musí okamžitě táhnout na opačnou stranu!**
     $$\text{afcTrackDir} = \begin{cases} +1 & \text{pokud } R_L > R_R \\ -1 & \text{pokud } R_R \ge R_L \end{cases}$$
4. **Stav 4 – `TRACK_CLIMB` (Sledování vrcholu a detekce ohybu za vrcholem):** Objektiv krokuje ve směru `afcTrackDir` po `8 × 4 µm` (`32 µm`) a sleduje klouzavé maximum $(x_{\max}, CV_{\max})$ a sklon $dCV/dt$. Jakmile hodnota kontrastu začne klesat (`der < -12` nebo `cv < afcMaxCv - 90`), znamená to, že čočka právě projela optimálním bodem ostrosti.
5. **Stav 5 – `PULLBACK` (Parabolický návrat na vrchol):** Z trojice bodů $(x_{-1}, CV_{-1})$, $(x_{\max}, CV_{\max})$, $(x_{+1}, CV_{+1})$ se vypočítá parabolický vrchol `afcTargetPos`, objektiv se jedním mikrokrokem `Lens.moveRelativePos4um(pullDelta)` vrátí přesně na vrchol ostrosti, uloží nový `afcPeakCv` a přejde zpět do klidového stavu **`GATE_HOLD` (`1`)**.

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
