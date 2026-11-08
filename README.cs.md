# Hasselblad X1D-50c (v1.20.0 – v1.25.0) – Firmware Research, Modding & UI Simulator (CZ)

[![Platform](https://img.shields.io/badge/Platform-Hasselblad%20Umbrella%202.0.3%20(NXP%20i.MX6Quad)-blue)](#česká-dokumentace-dokumentace)
[![Firmware](https://img.shields.io/badge/Firmware-v1.20.0%20–%20v1.25.0%20(.cim)-success)](#česká-dokumentace-dokumentace)
[![UI](https://img.shields.io/badge/UI-Qt%205.5.1%20%2F%20QML%20%2B%20640×480%20PC%20Simulátor-orange)](#rychlý-start-a-nástroje)
[![Roadmap](https://img.shields.io/badge/Roadmap-Aktivní%20vývoj-purple)](#️-plán-vývoje-a-postup-prací-roadmap)

> **English documentation:** See [`README.md`](README.md) and [`docs/`](docs/).

Tento projekt slouží k průzkumu, dešifrování, rozbalení, úpravám, lokální simulaci a dokumentaci firmwaru středoformátového fotoaparátu **Hasselblad X1D-50c (1. generace)** napříč všemi 6 oficiálními verzemi (`v1.20.0` až `v1.25.0`, build `42` z `2020-10-22`).

---

## Česká dokumentace (`dokumentace/`)

1. **[01 – Architektura a hardware (`dokumentace/01-architektura-a-hardware.md`)](dokumentace/01-architektura-a-hardware.md)**
   * Rozdíl mezi 1. generací (X1D-50c – Yocto Linux na NXP i.MX6Quad) a novějšími generacemi (X1D II / X2D / 907X 100C – Android/OTA).
   * Unifikovaná platforma **Hasselblad Umbrella Distro 2.0.3** a interní kódová jména modelů (`Wedge` = X1D-50c, `Victory` = H6D-50c, `Albatross` = H6D-100c / A6D, `Idun` = 907X / CFV II 50C).
   * Přehled interních koprocesorů (`FARM` FPGA, `FX3` USB 3.0, `SUC` mikrokontrolér, `SPC` napájení senzoru), A/B rozložení eMMC a systémových služeb (`systemd` + `D-Bus`).
2. **[02 – Formát `.cim` a proces aktualizace (`dokumentace/02-format-cim-a-aktualizace.md`)](dokumentace/02-format-cim-a-aktualizace.md)**
   * Detailní popis kontejneru `VHABCIM`, statického klíče AES-128-CBC, výpočtu IV z časového razítka, resetu IV po 4096 bajtech, kontroly integrity pomocí soleného MD5 hashe a dvoufázového `PrivateHeader::Checksum`.
   * Tabulka souborů uvnitř `X1D_v1_25_0.cim` a podrobný rozbor skriptů `hbl-upgrade`, `program_nodes.sh` a `hbl-post-upgrade`.
3. **[03 – Grafické rozhraní (`victory-gui`), QML a skryté funkce (`dokumentace/03-gui-qml-a-skryte-funkce.md`)](dokumentace/03-gui-qml-a-skryte-funkce.md)**
   * Jak funguje Wayland/Weston a Qt 5.5.1 / QML rozhraní v `victory-gui`.
   * **Skryté servisní menu (Easter Egg)** přímo ve foťáku (odemknutí poklepáním na verzi firmwaru v *About*).
   * Přehled všech skrytých voleb s příznakem `demo: true` v `MenuItemSpecificationsWedge.js` a kalibračních režimů v `DebugCam.qml`.
4. **[04 – Patchování `victory-gui` a balení `.cim` (`dokumentace/04-patchovani-a-baleni-cim.md`)](dokumentace/04-patchovani-a-baleni-cim.md)**
   * Binární rozložení Qt Resource tabulky (`DATA_BASE`, `NAMES_BASE`, `TREE_BASE`) uvnitř `/usr/bin/victory-gui` a postup in-place patche (`zlib` level 9).
   * Reverzní inženýrství tříd `Cim::PublicHeader`, `Cim::PrivateHeader` a `Cim::ItemHeader` z binárky `/usr/bin/upgrade-daemon` a bezpečné testování z SD karty (`/media/data/victory-gui`).
5. **[05 – Hloubková analýza C++ backendu a skrytých funkcí (`dokumentace/05-analyza-cpp-backendu-a-funkci.md`)](dokumentace/05-analyza-cpp-backendu-a-funkci.md)**
   * Kompletní matice provázanosti mezi `victory-gui` (`SettingsMiddleLayer`), `configstore`, `msg2dbus`, `bodystate-daemon`, `camera-daemon` (`WedgeStateMachine`) a `storage-daemon`.
   * Které skryté funkce jsou **100% funkční na reálném hardwaru X1D-50c** (např. mapování tlačítek `AE-L` a `AF-D`, prohození koleček v režimu `M`, skrytí `B/T`, `AE-L` při namáčknutí, citlivost eye-sensoru, ladění rychlosti AF motoru `7000..31000` a Brennerova filtru v FPGA) a proč `AF-C` / `True Focus` na X1D padají zpět na `AF-S`.
   * Rozpletení Dual-QSPI firmwaru čipu `FARM` (Xilinx Zynq-7000), stavový automat `af_service.c` (slepý dvouhranový průjezd) a nízkoúrovňové rozhraní `LensProxy` (`Lens.moveRelativePos4um`).
6. **[06 – Emulace UI na PC a bezpečné testování (`dokumentace/06-emulace-ui-na-pc.md`)](dokumentace/06-emulace-ui-na-pc.md)**
   * Jak používat lokální 640×480 PC simulátor (`ui_simulator/run_simulator.py`), skryté CLI přepínače binárky `victory-gui` (`--wedge`, `--session`, `--main`) a plnou ARM emulaci v QEMU.
7. **[07 – Porovnání všech 6 verzí firmwaru (`dokumentace/07-porovnani-verzi-firmwaru.md`)](dokumentace/07-porovnani-verzi-firmwaru.md)**
   * Kompletní srovnání verzí `v1.20.0`, `v1.20.1`, `v1.21.0`, `v1.22.0`, `v1.24.0` a `v1.25.0`: velikosti a hashe kontejnerů, vývoj koprocesorů (`FARM`, `FX3`, `SPC`, `SUC`), přidané funkce (zvuková odezva ALSA/TFA9882 ve `v1.21.0`, Focus Bracketing ve `v1.22.0`, 4µm krokování nových XCD objektivů ve `v1.24.0`) a ověření dvoufázového `PrivateHeader::Checksum`.

### Dokumentace vlastního firmwaru a budoucí aplikace Builder (`custom_firmware_dokumentace/`, anglicky v [`custom_firmware_docs/`](custom_firmware_docs/))

* **[00 – Architektura a technická pravidla Custom Firmware Builderu (`custom_firmware_dokumentace/00-architektura-custom-firmware-builderu.md`)](custom_firmware_dokumentace/00-architektura-custom-firmware-builderu.md)** – Specifikace paměťových ukazatelů, JSON schématu modulů a 4 kritických pravidel z reálného ARMv7 běhu (Wayland `TouchWindow` vs. `EVFWindow`, Qt 5.4 velká písmena u C++ signálů, limit `3000..20000` pro `DebugAfSpeed` v `/usr/bin/configstore` a D-Bus signatury).
* **[01 – Modul Odlehčená verze X1D Lite (`custom_firmware_dokumentace/01-modul-odlehcena-verze-x1d-lite.md`)](custom_firmware_dokumentace/01-modul-odlehcena-verze-x1d-lite.md)** – Uvolnění `+78,4 KB` v QRC tabulce a `−26,14 MB` na eMMC odstraněním cizích modelů (`H6D`/`A6D`/`CFV`) a komentářů.
* **[02 – Moduly pro zrychlení startu a odezvy UI (`custom_firmware_dokumentace/02-moduly-rychlost-boot-a-odezva-ui.md`)](custom_firmware_dokumentace/02-moduly-rychlost-boot-a-odezva-ui.md)** – Katalog modulů `MOD-SPD-01` až `MOD-SPD-06`.
* **[03 – Moduly pro výdrž baterie a chlazení (`custom_firmware_dokumentace/03-moduly-vydrz-baterie-a-chlazeni.md`)](custom_firmware_dokumentace/03-moduly-vydrz-baterie-a-chlazeni.md)** – Katalog modulů `MOD-BAT-01` až `MOD-BAT-05`.
* **[04 – Moduly pro skryté a nové funkce UI (`custom_firmware_dokumentace/04-moduly-skryte-a-nove-funkce-ui.md`)](custom_firmware_dokumentace/04-moduly-skryte-a-nove-funkce-ui.md)** – Katalog modulů `MOD-FEAT-01` až `MOD-FEAT-06`.
* **[05 – Modul Continuous Autofocus `AF-C` + Touch-to-Track (`custom_firmware_dokumentace/05-modul-continuous-autofocus-afc.md`)](custom_firmware_dokumentace/05-modul-continuous-autofocus-afc.md)** – Samostatný modul `MOD-FEAT-AFC` (`build_custom_firmware.py --mode afc`) nad továrním `1.25.0`: rozpletení Dual-QSPI firmwaru čipu `FARM` (Zynq-7000, `af_service.c`), mikrokrokování přes `Lens.moveRelativePos4um` a 5stavový **Gated CDAF + Peak Drop Rate** engine (`firmware/X1D_v1_25_0_afc.cim`, `63 270 912 B`). Starý prototyp s cyklováním relací je archivován jako `firmware/X1D_v1_25_0_afc_old.cim`.

---

## 🗺️ Plán vývoje a postup prací (Roadmap)

Přehled připravovaných funkcí, komunitní spolupráce a aktuálních milníků pro modifikovaný firmware Hasselblad X1D-50c:

| # | Funkce | Stav | Postup | Popis a aktuální cíl |
| :-: | :--- | :--- | :---: | :--- |
| **1** | **Kontinuální autofocus (`AF-C` + Touch-to-Track)** | 🟡 **Připraveno na testování** | `[█████████░] 90 %` | 5stavový uzavřený CDAF regulátor s mikrokrokováním `Lens.moveRelativePos4um` v balíčku `X1D_v1_25_0_afc.cim`. Ověřeno v ARMv7 emulátoru; připraveno k nahrání a testování na reálném foťáku s XCD objektivy. |
| **2** | **Filmové emulace (Film Emulation – projekt Hazel / Haxel)** | 🟠 **V aktivním vývoji** | `[████░░░░░░] 45 %` | Spolupráce s projektem **[Hazel-firmware](https://github.com/duart38/Hazel-firmware)** (*Haxel* od **[@duart38](https://github.com/duart38)**). Integrace 3D LUT profilů a simulací klasických filmových materiálů (Portra, Tri-X, Provia apod.) do UI a náhledu. |
| **3** | **Dvojitá expozice (Double Exposure / Multi-Exposure)** | 🔵 **Ve fázi návrhu** | `[██░░░░░░░░] 20 %` | Vícenásobná expozice na 50MP senzoru s živým poloprůhledným náhledem (Live View overlay v EVF i na displeji) pro přesnou kompozici druhého snímku a volitelnými režimy prolnutí. |
| **4** | **Připojení k Phocus Mobile 2 / Vlastní mobilní appka** | 🟣 **Výzkum a prototypování** | `[█░░░░░░░░░] 15 %` | Zpětné inženýrství protokolu Phocus Mobile 2 (z novějších X1D II/X2D) pro Wi-Fi ovládání 1. generace X1D, případně vývoj moderní odlehčené mobilní aplikace / Web UI (Live View, dálková spoušť, stahování RAWů). |

### Podrobný přehled cílů a milníků

#### 1. 🎯 Kontinuální autofocus (`AF-C` & Touch-to-Track) – *Skoro hotovo, ready na testování na foťáku*
* **Aktuální stav:** **~90 % hotovo** – Připraven samostatný modul postavený přímo nad továrním firmwarem `v1.25.0` (`firmware/X1D_v1_25_0_afc.cim`, `63 270 912 B`).
* **Technické řešení:** Odstraňuje tovární slepé dvouhranové přejezdy (`af_service.c` v čipu `FARM` FPGA), které na reálném fotoaparátu způsobovaly neustálé přejíždění celého rozsahu (hunting). Využívá vlastní 5stavový CDAF regulátor (`IDLE` → `POLL` → `TRACK` → `CONVERGED` → `RECOVERY`), který řídí krokový motor objektivu přes `Lens.moveRelativePos4um` (4µm mikrokroky), přináší zaostření a sledování dotykem (**Touch-to-Track**) a okamžitou prioritu domáčknutí spouště. Chování bylo plně ověřeno v ARMv7 emulátoru s fyzikálním simulátorem kontrastu.
* **Další krok:** Nahrání do fyzického fotoaparátu X1D-50c a praktické otestování s reálnými XCD objektivy pro finální doladění šířky pásma necitlivosti a velikosti kroků v reálných světelných podmínkách.

#### 2. 🎞️ Filmové emulace a barevné profily (Spolupráce na projektu Hazel / Haxel)
* **Aktuální stav:** **~45 % hotovo** – Aktivní výzkum a spolupráce s autorem **[@duart38](https://github.com/duart38)** na projektu **[Hazel-firmware](https://github.com/duart38/Hazel-firmware)** (*Haxel*).
* **Technické řešení:** Zavedení podpory 3D LUT křivek a filmových simulací přímo do fotoaparátu. Cílem je přinést estetiku klasických analogových filmů (např. barevný negativ Kodak Portra 160/400, černobílý Kodak Tri-X 400, diapozitivní Fuji Provia/Velvia, Cinestill či monochromatické tónování) přímo do živého náhledu v hledáčku/na displeji a do JPEG náhledů generovaných foťákem, spolu s custom DNG profily.
* **Další krok:** Integrace výběru filmových profilů do menu `victory-gui` a otestování shaderů pro transformaci barev v živém náhledu.

#### 3. 📸 Dvojitá / Vícenásobná expozice (Double Exposure)
* **Aktuální stav:** **~20 % hotovo** – Návrh rozhraní a specifikace práce s obrazovými buffery.
* **Technické řešení:** Kreativní vícenásobná expozice pro 50MP středoformátový senzor. Fotoaparát udrží první expozici v paměti a během Live View nabídne poloprůhledný překryv (ghosted overlay) v hledáčku EVF i na zadním LCD, takže fotograf přesně vidí kompozici při pořizování druhé expozice.
* **Plánované možnosti:** Volitelné režimy prolnutí (aditivní součet, průměr, světlejší, tmavší) a volba uložení jak složeného výsledku, tak původních jednotlivých RAWů.
* **Další krok:** Vytvoření prototypu QML komponenty pro překryv v Live View a otestování slučování bufferů.

#### 4. 📱 Připojení k Phocus Mobile 2 nebo Vlastní mobilní aplikace
* **Aktuální stav:** **~15 % hotovo** – Analýza protokolu a návrh architektury propojení.
* **Technické řešení:** Fotoaparát X1D-50c má integrovanou Wi-Fi (802.11a/b/g/n), avšak původní aplikace Hasselblad Phocus Mobile je na moderních operačních systémech již zastaralá/nefunkční a novější Phocus Mobile 2 oficiálně podporuje až fotoaparáty 2. generace (X1D II / X2D).
  * **Varianta A (Překladový můstek pro Phocus Mobile 2):** Zpětné inženýrství protokolu Phocus Mobile 2 (D-Bus over Wi-Fi / REST / WebSocket) a implementace komunikační vrstvy v Linuxu fotoaparátu, která umožní přímé spojení s originální aplikací Phocus Mobile 2 na iPadu, iPhonu i Androidu.
  * **Varianta B (Vlastní mobilní aplikace / PWA Web):** Vývoj odlehčené otevřené mobilní aplikace či lokální webové aplikace běžící přímo z fotoaparátu, která nabídne dálkovou bezdrátovou spoušť, plynulý přenos Live View na displej mobilu, nastavení expozice a rychlé bezdrátové stahování RAW/JPEG fotografií.
* **Další krok:** Odposlech paketů aplikace Phocus Mobile 2 a zmapování síťových soketů v `camera-daemon`.

---

## Rychlý start a nástroje

### 1. Spuštění interaktivního 640×480 PC UI Simulátoru & `.cim` Bootloaderu (CZ / EN)
```powershell
python ui_simulator/run_simulator.py
```
Otevře `http://127.0.0.1:8125/` s:
* **Přímým `.cim` Bootloaderem:** V horní liště můžete vybrat libovolný `.cim` soubor (`v1.20.0` až `v1.25.0` nebo vlastní zabalený `.cim`) a kliknout na **`⚡ Boot .CIM`** – simulátor za běhu dešifruje `rootfs.tar.bz2`, rozbalí `/usr/bin/victory-gui` + `/etc/version` + `/usr/bin/configstore`, automaticky detekuje offsety QRC tabulek, rozbalí všech 405 QML/JS/PNG zdrojů a živě načte rozhraní příslušné verze firmwaru.
* Živým menu X1D-50c (`640×480`), přepínačem jazyka **🇬🇧 EN / 🇨🇿 CZ**, rentgenem C++ backendu, **počítadlem paměti a QRC slotů** a **5fázovým Anti-Brick Pre-Flight testem**.

### 2. Přímé rozbalení a nabootování `.cim` firmwaru z příkazové řádky (`cim_emulator_loader.py`)
```powershell
# Výpis dostupných .cim souborů ve složce firmware/
python cim_emulator_loader.py --list

# Dešifrování, rozbalení rootfs + victory-gui a extrakce všech 405 QRC souborů
python cim_emulator_loader.py "firmware/X1D_v1_20_0.cim"
```

### 3. Spuštění plného ARMv7 Linux Rootfs Emulátoru (`run_arm_emulator.py`)
```powershell
# Vyžaduje Docker Desktop s podporou QEMU arm32v7 (binfmt)
python run_arm_emulator.py --cim "firmware/X1D_v1_25_0.cim"
```
Sestaví a spustí `arm32v7` kontejner s reálným rozbaleným `rootfs` fotoaparátu, běžící originální binárkou **`/usr/bin/victory-gui` (Qt5 QML)**, systémovým `dbus-daemon`, originálním démonem `/usr/bin/configstore` (162 vlastností) a mock službami hardwaru (`mock_hardware_dbus.py`). Fyzický GPU čip Vivante GC2000 (`/dev/galcore`) je přemostěn do **Mesa Software OpenGL ES 2.0 (LLVMpipe)** pomocí tří kompatibilních adaptérů (`libxshmfence_compat.c`, `libbsd_compat.c`, `patch_libm.py`).

Obrazovka `640×480` je okamžitě dostupná v prohlížeči na **`http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale`**.

#### Interaktivní ovládání (Myš / Dotyk a klávesnice):
| Ovládací prvek | Klávesa / Akce | Funkce |
| :--- | :--- | :--- |
| **Dotyk / Klik** | **Levé tlačítko myši** | Kliknutím na `f/2.8`, `125` nebo `ISO 100` se otevře originální vyskakovací volič |
| **Tlačítko MENU** | **`F1`** | Přepíná mezi expoziční obrazovkou (`ControlScreen`) a 9dílným hlavním menu |
| **Tlačítko Zpět** | **`Escape`** | Zavře libovolné otevřené vyskakovací okno nebo menu |
| **Kolečka fotoaparátu** | **Šipky (`←`, `→`, `↑`, `↓`)** | Pohyb v nabídkách a krokování expozičních hodnot |
| **Volič režimů** | **`1`** až **`6`** | `1` = Manuál (M), `2` = Auto, `3` = Priorita času (S), `4` = Program (P), `6` = Video |
| **Přímé zkratky** | **`C`** / **`G`** / **`Y`** | Rychlé vyvolání voliče ISO (`C`), White Balance (`G`) a dvojosé vodováhy (`Y`) |

### 4. Samostatný Anti-Brick Pre-Flight Test & Počítadlo paměti v CLI
```powershell
# Rychlá kontrola + přehled paměti a QRC slotů
python verify_firmware_safety.py --fast

# Plná hloubková kontrola (včetně průchodu celého 60MB rootfs.tar.bz2 a .cim součtů)
python verify_firmware_safety.py
```

---

## Spolupráce a spřízněné projekty

* **[duart38/Hazel-firmware](https://github.com/duart38/Hazel-firmware)** – Aktivně spolupracujeme s projektem **Hazel-firmware** (*Haxel*) od **[@duart38](https://github.com/duart38)**, protože **filmové emulace (Film Emulation) a vlastní barevné profily** patří mezi hlavní funkce, které chceme do upraveného firmwaru X1D-50c přinést.
* **[YuHaoyua/hasselblad-x1d-reverse-engineering](https://github.com/YuHaoyua/hasselblad-x1d-reverse-engineering)** – Základní reverzní inženýrství 1. generace X1D-50c (D-Bus rozhraní, `sutest-daemon`, QEMU emulace a QRC patchování).
* **[YuHaoyua/hasselblad-cim-firmware-extractor](https://github.com/YuHaoyua/hasselblad-cim-firmware-extractor)** – Nástroj pro dešifrování `.cim` kontejnerů.


