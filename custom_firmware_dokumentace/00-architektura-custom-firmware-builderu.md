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

## 4. Přehled všech dokumentů v této složce

1. **[`01-modul-odlehcena-verze-x1d-lite.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/01-modul-odlehcena-verze-x1d-lite.md)**
   Detailní rozbor základního modulu **`MOD-CORE-LITE`** (odstranění komentářů a cizích modelů H6D/A6D/CFV) a realistické zhodnocení jeho přínosů.
2. **[`02-moduly-rychlost-boot-a-odezva-ui.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/02-moduly-rychlost-boot-a-odezva-ui.md)**
   Katalog 6 modulů (**`MOD-SPD-01`** až **`MOD-SPD-06`**) pro zrychlení náběhu fotoaparátu, okamžité zapnutí dotykového displeje, odstranění 200ms prodlevy LiveView, zrychlení animací a vypnutí debug logování.
3. **[`03-moduly-vydrz-baterie-a-chlazeni.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/03-moduly-vydrz-baterie-a-chlazeni.md)**
   Katalog 5 modulů (**`MOD-BAT-01`** až **`MOD-BAT-05`**) pro reálné prodloužení výdrže baterie a snížení zahřívání těla X1D-50c (odpojení Wi-Fi čipu BCM4356 a démonů na pozadí, zkrácení timeoutu 50MP senzoru v LiveView, úsporné podsvícení a redukce framebufferů).
4. **[`04-moduly-skryte-a-nove-funkce-ui.md`](file:///d:/Plocha/projekty/X1D_FirmwareDump/custom_firmware_dokumentace/04-moduly-skryte-a-nove-funkce-ui.md)**
   Katalog 6 modulů (**`MOD-FEAT-01`** až **`MOD-FEAT-06`**) pro odemknutí skrytých továrních funkcí (`Compressed 3FR`, `Noise Filter`, `JPG Size`, `Eye Sensor Distance`, `AF Debug/Speed`, `RAM-Only Demo Mode`, `DebugCam` RAW mapy FPGA, čtení teplot a vlastní barevná témata UI).
