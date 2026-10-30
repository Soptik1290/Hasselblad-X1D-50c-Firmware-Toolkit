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

### Jak simulátor spustit
V kořenové složce projektu stačí spustit:
```powershell
python ui_simulator/run_simulator.py
```
Skript spustí lokální server na `http://127.0.0.1:8125/` a otevře simulátor v prohlížeči.

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

## 2. Skryté příkazové přepínače přímo v binárce `/usr/bin/victory-gui`

Při statické analýze `/usr/bin/victory-gui` (offset `0x7f700..0x7f850`) jsme objevili, že samotná binárka používá třídu `QCommandLineParser` a podporuje tyto přepínače příkazové řádky:

| Přepínač | Popis v binárce (`victory-gui`) | Význam |
| :--- | :--- | :--- |
| `--wedge` | `Run in Wedge Mode.` | Vynutí režim **Hasselblad X1D-50c** (`guiconfig.isWedge = true`) bez ohledu na OTP sériové číslo v CPU |
| `--albatross` | `Run in Albatross Mode.` | Vynutí režim **H6D-100c** |
| `--cfv` | `Run in CFV Mode.` | Vynutí režim **907X / CFV II 50C** |
| `--a6d50` | `Run in A6D 50 Mode.` | Vynutí režim **A6D-50c** |
| `--a6d100` | `Run in A6D 100 Mode.` | Vynutí režim **A6D-100c** |
| `--session` | `Use the DBus session bus.` | Místo systémové D-Bus sběrnice (`--system`) použije uživatelskou session sběrnici (pro vývoj na Linuxu) |
| `--fullscreen` | `Run in fullscreen.` | Celoobrazovkový režim |
| `--main <cesta>` | *(přepíše výchozí `qrc:///main.qml`)* | Umožní načíst hlavní QML soubor mimo interní `qrc:///`! |

Кromě toho třída `KeyInject` (`com.hasselblad.mockup`, offset `0x7fd90`) přijímá přes D-Bus simulované stisky kláves (`menu`, `f1`..`f5`, `left`, `right`, `double_click`), které vývojáři v Göteborgu používali při automatizovaném testování GUI.

---

## 3. Plná ARM emulace v QEMU (`qemu-system-arm`)

Pokud chceš spustit přímo binárku `/usr/bin/victory-gui` spolu s daemony (`configstore`, `camera-daemon`, `bodystate-daemon`, `weston`) v emulovaném ARM procesoru na PC, projekt `YuHaoyua/hasselblad-x1d-reverse-engineering` ukazuje přesný postup:

1. **Co je potřeba**:
   - Nainstalované `qemu-system-arm` (balíček QEMU pro Windows nebo Linux/WSL2).
   - Linuxový kernel `zImage` zkompilovaný pro `imx_v6_v7_defconfig` nebo `vexpress-a9` s podporou `devtmpfs`, `fbdev` (640×480) a `virtio`.
2. **Sestavení `initramfs` z rozbaleného `rootfs`**:
   - V `rootfs` je již kompletní Yocto uživatelský prostor (`Hasselblad Umbrella Distro 2.0.3`), včetně `/usr/bin/weston`, `/usr/lib/weston/fbdev-backend.so` a `/usr/lib/weston/victory-shell.so`.
   - Pro běh v QEMU (kde není grafický akcelerátor Vivante GC2000 z i.MX6) se ve skriptu `/usr/bin/weston.sh` upraví spuštění Westonu z `--use-gal2d=1` na čistý softwarový Pixman framebuffer (`--backend=fbdev-backend.so`) a `victory-gui` se spustí s přepínačem:
     ```sh
     export XDG_RUNTIME_DIR=/tmp
     export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
     /usr/bin/victory-gui -platform wayland --wedge
     ```
3. **Kdy použít QEMU vs. náš lokální simulátor**:
   - Pro **99 % úprav menu, odemykání `demo: true` položek a testování QML/JS změn** je mnohem rychlejší náš lokální simulátor `python ui_simulator/run_simulator.py`, protože nabíhá okamžitě a nepotřebuje kompilovat ARM kernel.
   - QEMU se hodí ve chvíli, kdy bys chtěl ladit binární patche přímo v ARM instrukcích `/usr/bin/victory-gui` nebo `/usr/bin/camera-daemon` pomocí `gdb-multiarch`.
