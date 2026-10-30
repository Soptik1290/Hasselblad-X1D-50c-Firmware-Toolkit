# 06 – Emulace UI na PC a bezpečné testování úprav mimo fotoaparát

Než cokoliv zabalíš do `.cim` a nahraješ do fotoaparátu, existují **tři úrovně bezpečného testování rozhraní `victory-gui`**:

1. **Úroveň 1 (Okamžitá na Windows/macOS/Linux): Lokální 640×480 UI Simulátor & QML Inspektor** (`ui_simulator/run_simulator.py`) – přímo spouští rozbalené `MenuItemSpecifications*.js` skripty, originální fonty `HelveticaNeueLTStd` a všech 267 PNG ikon ze složky `victory_gui_qml/`.
2. **Úroveň 2 (Plná ARM Linux emulace na PC): Spuštění originální binárky `victory-gui` v QEMU** (`qemu-system-arm`) s kompozitorem Weston/Wayland a emulovaným framebufferem `640×480`.
3. **Úroveň 3 (Testování na foťáku bez zápisu do eMMC flash): Spuštění upraveného `victory-gui` přímo z SD karty** (`/media/data/victory-gui`) nebo využití skrytého přepínače `--main`.

---

## 1. Lokální PC UI Simulátor (`ui_simulator/run_simulator.py`)

Proč nejde jednoduše otevřít `victory_gui_qml/main.qml` ve standardním desktopovém prohlížeči `qmlscene` z Qt5?
V souboru `main.qml` (řádky 3–17) vyžaduje rozhraní 15 proprietárních C++ modulů registrovaných přímo v binárce `/usr/bin/victory-gui` a napojených na D-Bus daemony:
```qml
import com.hasselblad.config 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.power 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.storage 1.0
import com.hasselblad.error 1.0
import com.hasselblad.systemd 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.settings 1.0
import com.hasselblad.lens 1.0
import com.hasselblad.sound 1.0
```

Protože samotná struktura všech menu a voleb je definována v čistém JavaScriptu (`victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`), vytvořili jsme v projektu složku **`ui_simulator/`**, která:
- **Přímo načítá a vykonává živý soubor `victory_gui_qml/settings/scripts/MenuItemSpecificationsWedge.js`** (případně `MenuItemSpecifications.js` pro H6D, `MenuItemSpecificationsCFV.js` pro 907X/CFV II 50C a `MenuItemSpecificationsA6D.js` pro A6D).
- Vykresluje **autentické rozlišení 640×480 px** s originálními fonty **`HelveticaNeueLTStd-Lt_1.otf`** a **`HelveticaNeueLTStd-Bd_1.otf`** (vytáhnutými z `/usr/lib/fonts/` v `rootfs`) a **originálními PNG ikonami** z `victory_gui_qml/icons/`.
- Replikuje chování `MainScreen.qml`, `Menu.qml`, `SettingsGeneric.qml`, `DemoMarker.qml` (červené zvýraznění `demo: true` položek) i `DemoModeIndicator.qml` (`NO STORAGE`).
- Obsahuje vpravo **Rentgen C++ Backendu** a **Živou kontrolu QRC slotů (zlib level 9)** – jakmile upravíš libovolný soubor ve `victory_gui_qml/` a klikneš na **„Znovu načíst živé QML/JS ze složky“**, simulátor ti okamžitě ukáže upravené menu i to, kolik volných bajtů zbývá ve slotu uvnitř binárky `victory-gui`.

### Jak simulátor a přímý `.cim` Bootloader spustit
V kořenové složce projektu stačí spustit:
```powershell
python ui_simulator/run_simulator.py
```
Skript spustí lokální server na `http://127.0.0.1:8125/` a otevře dvojjazyčný (CZ / EN) simulátor v prohlížeči.

#### Přímý `.cim` Firmware Bootloader (`cim_emulator_loader.py`)
Přímo na Windows můžeš rozbalit a nabootovat **libovolný oficiální nebo upravený `.cim` firmware (`v1.20.0` až `v1.25.0`)**:
1. **Ve WebUI (`http://127.0.0.1:8125/`)**: V horní liště vyber libovolný `.cim` soubor a klikni na **`⚡ Boot .CIM`** (nebo otevři záložku **4. `.CIM` & ARM Emulátor**). Server dešifruje kontejner `VHABCIM`, ověří dvoufázový `PrivateHeader::Checksum`, vytáhne `/usr/bin/victory-gui`, `/usr/bin/configstore` a `/etc/version` z `rootfs.tar.bz2`, automaticky v ELF binárce najde QRC tabulky (`DATA_BASE`, `NAMES_BASE`, `TREE_BASE`), rozbalí všech 405 QRC zdrojů, zobrazí na displeji `640×480` animovaný U-Boot/Linux boot log a živě přepne celé UI na danou verzi firmwaru.
2. **Z příkazové řádky**:
   ```powershell
   python cim_emulator_loader.py --list
   python cim_emulator_loader.py "firmware/X1D_v1_20_0.cim"
   ```

#### 5fázový Anti-Brick Pre-Flight Test & Počítadlo paměti (`verify_firmware_safety.py`)
Před zabalením nebo nahráním upraveného firmwaru spusť automatický bezpečnostní test (v záložce **3. Anti-Brick Test** ve WebUI nebo v terminálu):
```powershell
python verify_firmware_safety.py --fast
```
Test kontroluje:
1. **Syntaxi všech 128 QML a 9 JS souborů**.
2. **Kapacitu QRC slotů a rezervu po ořezu komentářů** (ověří, že se každý soubor po `zlib` kompresi vejde do svého slotu; automatické odstranění komentářů v `patch_victory_qrc_file.py` uvolní **+60,2 KB** komprimovaného místa).
3. **Binární ELF a QRC dekompresi** (`405/405` zdrojů).
4. **U-Boot A/B ochranu proti bricknutí a symlinky v `rootfs`** (ověří, že `hbl-upgrade` zapisuje pouze do neaktivní A/B banky, nikdy nepřepisuje U-Boot `/dev/mtd0`, a zkontroluje symlinky `/sbin/init` + `readlink`, aby `hbl-post-upgrade` korektně nastavil `boot_ok=1`).
5. **Kryptografickou integritu a dvoufázový kontrolní součet `.cim` kontejnerů**.

### Co si v simulátoru můžeš hned vyzkoušet:
1. **Odemknutí skrytých položek (`guiconfig.hideDemoItems`)**:
   - V pravém panelu odškrtni `guiconfig.hideDemoItems`.
   - V hlavním menu se nahoře objeví nápis `Build: 1.25.0` (stejně jako v `MainScreen.qml:1192`) a v sekcích **Autofocus**, **Custom Buttons**, **Configuration**, **Quality** a **Display** se objeví všechny skryté funkce podbarvené poloprůhlednou červenou vrstvou (`DemoMarker.qml`).
   - Odškrtnutím `DemoState.demoOn` červený překryv zmizí.
2. **Aktivace Easter Eggu nanečisto**:
   - Otevři **General Settings (ozubené kolečko) → About**.
   - 5× klikni na řádek **`Firmware: 1.25.0`**.
   - Odemkne se `guiconfig.showSecretMenuItems = true` a v menu **General Settings → Service** přibudou položky **Deactivate Storage**, **Firmware Update Retry** a **Scroll Wheel Handling**.
3. **Vyzkoušení prohození koleček v M (`Front Wheel in M`)**:
   - Otevři **Camera Settings → Configuration → Front Wheel in M** a přepni z `Aperture` na `Shutterspeed`.
   - Stiskni tlačítko **CTRL (✕)** vpravo vedle displeje a otáčej předním/zadním kolečkem nahoře nad displejem – funkce koleček se skutečně prohodí!

---

## 2. Příkazové přepínače přímo v binárce `/usr/bin/victory-gui`

Spuštění `/usr/bin/victory-gui --help` uvnitř ARMv7 kontejneru vypíše přesné přepínače třídy `QCommandLineParser`:

| Přepínač | Popis v binárce (`victory-gui`) | Význam |
| :--- | :--- | :--- |
| `-w, --wedge` | `Run in Wedge Mode.` | Vynutí režim **Hasselblad X1D-50c** (`guiconfig.isWedge = true`) bez ohledu na OTP sériové číslo v CPU |
| `-a, --albatross` | `Run in Albatross Mode.` | Vynutí režim **H6D-100c** |
| `-c, --cfv` | `Run in CFV Mode.` | Vynutí režim **907X / CFV II 50C** |
| `-k, --a6d50` | `Run in A6D 50 Mode.` | Vynutí režim **A6D-50c** |
| `-l, --a6d100` | `Run in A6D 100 Mode.` | Vynutí režim **A6D-100c** |
| `-s, --session` | `Use the DBus session bus.` | Místo systémové D-Bus sběrnice (`--system`) použije uživatelskou session sběrnici (pro vývoj na Linuxu) |
| `-f, --fullscreen` | `Run in fullscreen.` | Celoobrazovkový režim |
| `-h, --help` / `-v, --version` | `Displays this help / version.` | Vypíše nápovědu a verzi |

Kromě toho třída `KeyInject` (`com.hasselblad.mockup`, offset `0x7fd90`) přijímá přes D-Bus simulované stisky kláves (`menu`, `f1`..`f5`, `left`, `right`, `double_click`), které vývojáři v Göteborgu používali při automatizovaném testování GUI.

---

## 3. Plný ARMv7 Linux Rootfs Emulátor na Windows (`run_arm_emulator.py`)

Pokud chceš na Windows spustit přímo rozbalený ARMv7 Linux `rootfs` fotoaparátu a jeho démony (`configstore`, `victory-gui`) v emulovaném ARMv7 kontejneru přes Docker Desktop (`arm32v7` QEMU user-mode emulace) a zobrazit si `640×480` Weston obrazovku v prohlížeči přes **noVNC**:

```powershell
python run_arm_emulator.py --cim "firmware/X1D_v1_25_0.cim"
```

### Jak to funguje a jak se připojit v noVNC:
1. **Rozbalení `rootfs.tar.bz2`** z vybraného `.cim` firmwaru do `.emulator_cache/<firmware>/rootfs_full/` (včetně linuxových symlinků uvnitř kontejneru).
2. **Sestavení a start kontejneru `x1d-armv7-emulator` (`arm_emulator/`)**:
   - Zkopíruje D-Bus bezpečnostní politiky fotoaparátu (`/etc/dbus-1/system.d/com.hasselblad.*.conf`) a spustí `dbus-daemon --system`.
   - Spustí originální ARMv7 démon `/usr/bin/configstore` z firmwaru (který zaregistruje `com.hasselblad.config` a načte všech 162 konfiguračních vlastností fotoaparátu) spolu s `arm_emulator/mock_hardware_dbus.py` (simulující `com.hasselblad.cambody`, `com.hasselblad.camera`, `com.hasselblad.lens`, `com.hasselblad.systemmanager` atd.).
   - Spustí virtuální framebuffer `640×480` (`Xvfb :0`), Wayland kompozitor **Weston** (`640×480`), `x11vnc` a webový klient **noVNC** na portu `6080`.
3. **Připojení v prohlížeči (`noVNC`)**:
   - Otevři **`http://127.0.0.1:6080/vnc.html?autoconnect=true`**.
   - Pokud v pravém horním rohu vidíš okénko **noVNC** (`Host: 127.0.0.1`, `Port: 6080`, `Password: [prázdné]`), stačí kliknout na tlačítko **`Connect`** (heslo se nevyplňuje) – zobrazí se živá `640×480` plocha kompozitoru Weston běžícího v ARMv7 kontejneru.
