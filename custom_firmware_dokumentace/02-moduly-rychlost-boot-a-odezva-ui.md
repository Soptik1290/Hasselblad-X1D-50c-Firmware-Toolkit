# 02 – Moduly pro rychlost startu (Boot) a okamžitou odezvu UI (`MOD-SPD-01` až `MOD-SPD-06`)

Tento dokument obsahuje přesné technické recepty pro 6 modulů v kategorii **Rychlost & Odezva**. Každý modul uvádí přesný soubor, číslo řádku, původní stav, novou úpravu, dopad na paměť a konkrétní přínos na reálném fotoaparátu Hasselblad X1D-50c.

---

## Přehled modulů v kategorii Rychlost

| ID Modulu | Název v budoucí aplikaci | Hlavní přínos | Dopad na paměť |
| :--- | :--- | :--- | :--- |
| **`MOD-SPD-01`** | **Rychlý start dotyku, senzorů a LiveView po zapnutí** | Dotykový displej, senzor oka v EVF a LiveView naskočí **o 4–5 sekund dříve** po zapnutí fotoaparátu. | `rootfs: +2 B` |
| **`MOD-SPD-02`** | **Zkrácení startovní prodlevy Weston kompozitoru** | Zkrátí čekání grafického serveru Weston na výstupy ze 3 s na 1 s (**−1,5 až −2 s při startu**). | `rootfs: 0 B` |
| **`MOD-SPD-03`** | **Okamžitá aktivace LiveView bez 200ms prodlevy** | Odstraní umělý 200ms `delayed_liveview` časovač při stisku tlačítka LiveView / namáčknutí spouště. | `main.qml: −1 B` |
| **`MOD-SPD-04`** | **Zrychlení animací UI, vyskakovacích oken a 100% lupy** | 3× až 4× rychlejší zavírání oken ISO/WB/AF, švihnutí menu a přiblížení 100% náhledu. | `GlobalConstants.qml: −3 B` |
| **`MOD-SPD-05`** | **Vypnutí debug logování `console.log()` a C++ reflexe fokusu** | Odstraní náročnou C++ serializaci všech vlastností `QObject` při každé změně fokusu a 178 volání `console.log()`. | `TouchWindow.qml: −118 B` (QRC) |
| **`MOD-SPD-06`** | **Odstranění H-systémového `HTS` adaptéru z LiveView** | Vypustí neviditelnou instanci `HTS` (Tilt-Shift adaptér pro H6D) ze stromu `LiveViewOverlay.qml`. | `LiveViewOverlay.qml: −54 B` (QRC) |

---

## `MOD-SPD-01`: Rychlý start dotyku, senzorů a LiveView po zapnutí (`late.timer`)

### Proč je X1D-50c po zapnutí tak dlouho „zamrzlý“ na dotyk?
Při analýze systemd jednotek v `rootfs.tar.bz2` jsme odhalili příčinu známého neduhu X1D-50c, kdy se po zapnutí sice rozsvítí obrazovka, ale **dotykový displej, stav baterie, senzor přiblížení oka (EVF) a živý náhled (LiveView) nereagují dalších ~5 sekund**:
- Ovladač dotykového panelu Atmel maXTouch (`touch-modules.service` -> `/sbin/modprobe atmel_mxt_ts`), ovladače baterie, EVF senzoru a akcelerometru (`bodystate-modules.service` -> `bq28z610_battery`, `sfh7776`, `lis3dsh_acc`) a démon živého náhledu (`video-daemon.service`) jsou vázány na cíl `late.target` (resp. `gui-visible.target`).
- Cíl `late.target` není spouštěn signálem z GUI, ale **natvrdo nastaveným časovačem `/lib/systemd/system/late.timer` s parametrem `OnStartupSec=7`** (plus `DefaultTimerAccuracySec=1` v `/etc/systemd/system.conf`). Systemd tedy po startu čeká celých **7 až 8 sekund**, než vůbec zavede jaderný modul dotykového displeje!

### Co je třeba změnit

1. **Soubor v `rootfs.tar.bz2`:** `./lib/systemd/system/late.timer`
   - **Původní stav:**
     ```ini
     [Unit]
     Description=Run the late target

     [Timer]
     OnStartupSec=7
     Unit=late.target

     [Install]
     WantedBy=timers.target
     ```
   - **Nový stav (volitelně v aplikaci `2` nebo `3` sekundy):**
     ```ini
     [Unit]
     Description=Run the late target

     [Timer]
     OnStartupSec=2
     Unit=late.target

     [Install]
     WantedBy=timers.target
     ```

2. **Soubor v `rootfs.tar.bz2`:** `./etc/systemd/system.conf` (řádek 21)
   - **Původní stav:**
     ```ini
     DefaultTimerAccuracySec=1
     ```
   - **Nový stav:**
     ```ini
     DefaultTimerAccuracySec=100ms
     ```

---

## `MOD-SPD-02`: Zkrácení startovní prodlevy Weston kompozitoru (`weston.sh`)

### Technický rozbor
Skript `./usr/bin/weston.sh` spouští Wayland kompozitor Weston s parametrem `--output-delay=3` (3sekundová prodleva při inicializaci framebufferů `/dev/fbmain`, `/dev/fbhdmi`, `/dev/fbevf`). Protože symlinky framebufferů jsou v době startu `weston.service` již vytvořené udevem, lze prodlevu bezpečně snížit na `1`.

### Co je třeba změnit
- **Soubor v `rootfs.tar.bz2`:** `./usr/bin/weston.sh` (řádek 8)
- **Původní stav:**
  ```sh
  /usr/bin/weston --tty=1 --use-gal2d=1 --use-gl=0 --output-delay=3 --device=${MAIN}${HDMI}${EVF}
  ```
- **Nový stav:**
  ```sh
  /usr/bin/weston --tty=1 --use-gal2d=1 --use-gl=0 --output-delay=1 --device=${MAIN}${HDMI}${EVF}
  ```

---

## `MOD-SPD-03`: Okamžitá aktivace LiveView bez 200ms prodlevy (`delayed_liveview`)

### Technický rozbor
V souboru [`victory_gui_qml/main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml#L486-L496) se při stisku tlačítka LiveView nebo při namáčknutí spouště (`HALFPRESS`) nevolá `Camera.setLiveViewState(true)` rovnou, ale spouští se časovač `delayed_liveview` s intervalem **`200 ms`**. Zkrácením na `20 ms` zůstane zachován debounce proti zákmitům tlačítka, ale LiveView se aktivuje okamžitě (**−180 ms latence**).

### Co je třeba změnit
- **Soubor:** [`victory_gui_qml/main.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/main.qml#L486-L490)
- **Původní stav:**
  ```qml
  Timer {
      id: delayed_liveview
      interval: 200
      repeat: false
  ```
- **Nový stav:**
  ```qml
  Timer {
      id: delayed_liveview
      interval: 20
      repeat: false
  ```

---

## `MOD-SPD-04`: Zrychlení animací UI, vyskakovacích oken a 100% lupy

### Technický rozbor
Tovární konstanty v [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml) mají velmi dlouhé časy animací:
- `fadeOutDuration: 500` (půl sekundy trvá pohasnutí/zavření každého vyskakovacího okna ISO, WB, AF, Exposure Mode v [`Popover.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/components/popups/Popover.qml#L157)).
- `zoomFullAnimateTime: 500` a `zoomAnimateTime: 200` (půl sekundy trvá animace přiblížení v LiveView a prohlížení fotek).
- `menuSwipeDuration: 200` a `afSelectionLongPressThreshold: 350` (350 ms musíte držet prst na displeji, než se odemkne posun AF bodu).

### Co je třeba změnit
1. **Soubor:** [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml)
   - Řádek 63: `readonly property int fadeOutDuration : 500` -> `120`
   - Řádek 121: `readonly property int highlightMoveDuration : 50` -> `25`
   - Řádek 162: `readonly property int menuSwipeDuration : 200` -> `90`
   - Řádek 169: `readonly property int zoomAnimateTime: 200` -> `70`
   - Řádek 171: `readonly property int zoomFullAnimateTime: 500` -> `120`
   - Řádek 190: `readonly property int afSelectionLongPressThreshold: 350` -> `180`
2. **Soubor:** [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L1645-L1674)
   - Řádky 1645, 1665, 1673: `duration: 100` -> `duration: 40`

---

## `MOD-SPD-05`: Vypnutí brzdícího debug logování `console.log()` a C++ reflexe fokusu

### Technický rozbor
1. V [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L208-L216) je na řádku 210 zapomenutý vývojářský příkaz:
   ```qml
   console.log("ActiveFocusItem changed:", activeFocusItem, guiconfig.itemProperties(activeFocusItem, false, true, 0))
   ```
   Při **každé změně aktivního prvku v celém GUI** volá C++ metodu `guiconfig.itemProperties(...)`, která přes `QMetaObject` reflexi prochází všechny vlastnosti daného QML objektu, skládá z nich dlouhý textový řetězec a zapisuje ho přes `console.log` do `systemd-journald`!
2. Napříč 137 QML/JS soubory je celkem **178 volání `console.log(...)`**, která neustále posílají ladicí výpisy do žurnálu.
3. V `./etc/systemd/journald.conf` je navíc nastaveno `RateLimitBurst=0` a `ForwardToSyslog=yes` (kvůli ladění FPGA `FARM` trasování), takže `systemd-journald` na procesoru i.MX6 zpracovává neomezený proud debug zpráv.

### Co je třeba změnit
1. **Soubor:** [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L208-L216)
   - **Původní stav:**
     ```qml
     onActiveFocusItemChanged: {
         if(null != activeFocusItem) {
             console.log("ActiveFocusItem changed:", activeFocusItem, guiconfig.itemProperties(activeFocusItem, false, true, 0))
             var itemStr = activeFocusItem.toString()
             if (itemStr.search(/QQuickRootItem/) === 0) {
                 focusRestoreTimer.restart()
             }
         }
     }
     ```
   - **Nový stav:**
     ```qml
     onActiveFocusItemChanged: {
         if(null != activeFocusItem) {
             var itemStr = activeFocusItem.toString()
             if (itemStr.search(/QQuickRootItem/) === 0) {
                 focusRestoreTimer.restart()
             }
         }
     }
     ```
2. **Všechny QML/JS soubory (volitelný přepínač v Builderu):** Automatické odstranění samostatných řádků `console.log(...);` (ušetří dalších **~4,5 KB** v QRC tabulce!).
3. **Soubor v `rootfs.tar.bz2`:** `./etc/systemd/journald.conf`
   - Změnit `RateLimitBurst=0` -> `RateLimitBurst=200`, `ForwardToSyslog=yes` -> `ForwardToSyslog=no` a přidat `MaxLevelStore=warning` + `RuntimeMaxUse=8M`.

---

## `MOD-SPD-06`: Odstranění H-systémového `HTS` adaptéru z `LiveViewOverlay.qml`

### Technický rozbor
V [`victory_gui_qml/liveview/LiveViewOverlay.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/LiveViewOverlay.qml#L791-L797) se při každém načtení LiveView vytváří komponenta `HTS` (Hasselblad Tilt-Shift 1.5X adaptér pro zrcadlovky H6D) a váže se na signál `onHts_attachedChanged: checkOverlay()`. Na X1D-50c tento adaptér fyzicky neexistuje.

### Co je třeba změnit
- **Soubor:** [`victory_gui_qml/liveview/LiveViewOverlay.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/liveview/LiveViewOverlay.qml)
- Odstranit blok `HTS { id: hts ... }` (řádky 791–797) a nahradit kontroly `hts.hts_attached` (řádky 179, 862, 875, 1020) hodnotou `false`.
