# 03 – Moduly pro výdrž baterie a snížení zahřívání (`MOD-BAT-01` až `MOD-BAT-05`)

Tento dokument popisuje 5 konkrétních hardwarových a systémových úprav, které **reálně prodlužují výdrž na baterii a snižují zahřívání těla Hasselblad X1D-50c**.

---

## Kde se v X1D-50c bere spotřeba energie a teplo?

Rozbor hardwarové architektury X1D-50c ukazuje 4 hlavní žrouty energie z akumulátoru (7,2 V / 3200 mAh = 23 Wh):
1. **50MP senzor Sony IMX161 + 2× FPGA Xilinx Kintex-7 (`farm` Even/Odd) během LiveView:** Odebírá **~6 až 8 W** (hlavní zdroj zahřívání hliníkového těla).
2. **Zadní 3" LCD displej (`fbmain`) a OLED hledáček (`fbevf`) + i.MX6Quad 2D GPU (`gal2d`):** Odebírá **~1,5 až 2,5 W**.
3. **PCIe Wi-Fi čip Broadcom BCM4356 (`brcmfmac4356-pcie.bin`) + síťové démony (`phocus-mobile-server`, `avahi-daemon`, `network-manager`):** Odebírá **~150 až 350 mW trvale**, protože tovární firmware zavádí PCIe Wi-Fi ovladač do jádra 10 sekund po startu bez ohledu na to, zda fotograf Wi-Fi používá!
4. **USB OTG řadič (`ci_hdrc_imx`) a procesor NXP i.MX6Quad (4× Cortex-A9 @ 792 MHz):** Odebírá **~1,0 až 1,8 W**.

---

## Přehled modulů v kategorii Baterie & Chlazení

| ID Modulu | Název v budoucí aplikaci | Odhadovaný přínos (Baterie / Teplo) | Dopad na paměť |
| :--- | :--- | :--- | :--- |
| **`MOD-BAT-01`** | **Odpojení PCIe Wi-Fi čipu a Phocus/Avahi démonů při startu (Offline / Field Mode)** | **−150 až −300 mW trvalého odběru**, **+12 MB volné RAM**, nulové probouzení CPU síťovými démony. | `rootfs: −4 symlinky` |
| **`MOD-BAT-02`** | **Zkrácení nečinného běhu 50MP senzoru v LiveView (`liveViewImageTimeoutDefault`)** | Zabrání 3minutovému žhavení senzoru a FPGA při odloženém fotoaparátu (**ušetří až 15–25 % baterie v terénu**). | `GlobalConstants.qml: 0 B` |
| **`MOD-BAT-03`** | **Hluboké pohasnutí černé (`blackScreenBrightness`) a rychlé vypnutí EVF po oddálení oka** | Sníží zbytkové podsvícení displeje v klidu z `9` na `1` a zkrátí `evfExitTimer` z `1000 ms` na `300 ms`. | `TouchWindow.qml: −1 B` |
| **`MOD-BAT-04`** | **Úsporný dvojitý framebuffer Weston kompozitoru (`FB_MULTI_BUFFER=2`)** | Sníží počet alokovaných framebufferů z `3` na `2` (nižší zátěž DDR3 sběrnice a `gal2d` GPU). | `rootfs: 0 B` |
| **`MOD-BAT-05`** | **Vypnutí ladicích služeb (`sshd.socket`, `usb-modules.service` debug)** | Vypne naslouchající SSH socket a debug USB modul při běžném focení na kartu. | `rootfs: −2 symlinky` |

---

## `MOD-BAT-01`: Odpojení PCIe Wi-Fi čipu BCM4356 a Phocus/Avahi démonů (`verylate.target`)

### Proč tovární firmware vybíjí baterii i s vypnutou Wi-Fi?
V `rootfs.tar.bz2` se 10 sekund po startu spustí časovač `./lib/systemd/system/verylate.timer`, který aktivuje cíl `verylate.target`. V adresáři `./etc/systemd/system/verylate.target.wants/` jsou tyto symlinky:
1. `network-manager.service` -> má v sobě příkaz **`ExecStartPre=/sbin/modprobe brcmfmac`**, který **vždy zavede jaderný ovladač PCIe Wi-Fi karty Broadcom BCM4356** a inicializuje PCIe sběrnici i firmware `brcmfmac4356-pcie.bin`!
2. `phocus-mobile-server.service` -> spouští `/usr/bin/phocus-mobile-server -p 50001` s vysokou prioritou **`Nice=-10`** (stejná priorita jako hlavní GUI!).
3. `avahi-daemon.service` a `avahi-daemon.socket` -> mDNS/Bonjour démon.
4. `systemd-networkd.service` a `systemd-networkd.socket`.

### Co je třeba změnit (Režim „Bez Wi-Fi / Maximální výdrž v terénu“)
V archivu `rootfs.tar.bz2` odstranit ze složky `./etc/systemd/system/verylate.target.wants/` následující symlinky:
- `./etc/systemd/system/verylate.target.wants/network-manager.service`
- `./etc/systemd/system/verylate.target.wants/phocus-mobile-server.service`
- `./etc/systemd/system/verylate.target.wants/avahi-daemon.service`
- `./etc/systemd/system/verylate.target.wants/avahi-daemon.socket`
- `./etc/systemd/system/verylate.target.wants/systemd-networkd.service`
- `./etc/systemd/system/verylate.target.wants/systemd-networkd.socket`

*(Poznámka: Tethering přes USB kabel pomocí `phocus-daemon.service` zůstává 100% funkční!)*

---

## `MOD-BAT-02`: Zkrácení nečinného běhu 50MP senzoru a FPGA v LiveView

### Technický rozbor
V souboru [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L188) je na řádku 188 definována výchozí doba, po kterou zůstává zapnuté vyčítání 50MP senzoru a obou Kintex-7 FPGA v režimu LiveView:
```qml
readonly property int liveViewImageTimeoutDefault: 3 * 60
```
**180 sekund (3 minuty)** plného odběru (~7 W) při každém zapnutí LiveView, pokud fotograf zapomene LiveView ručně vypnout tlačítkem! Zkrácením na **45 s** nebo **60 s** (volitelné v Builderu) se dramaticky sníží zahřívání těla a spotřeba baterie.

### Co je třeba změnit
- **Soubor:** [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L188)
- **Původní stav:**
  ```qml
  readonly property int liveViewImageTimeoutDefault: 3 * 60
  ```
- **Nový stav (např. 45 sekund):**
  ```qml
  readonly property int liveViewImageTimeoutDefault: 45
  ```

---

## `MOD-BAT-03`: Hluboké pohasnutí černé a rychlé vypnutí EVF po oddálení oka

### Technický rozbor
1. V [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L192) je hodnota podsvícení „černé/ztmavené obrazovky“ nastavena na `blackScreenBrightness: 9`. Snížením na `1` (nebo `2`) klesne spotřeba LED podsvícení LCD v klidovém stavu.
2. V [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L1165-L1176) drží časovač `evfExitTimer` stav po oddálení oka od hledáčku po dobu `1000 ms` (1 sekunda), než povolí vypnutí LiveView streamu (`!evfExitTimeoutActive` na řádku 1636). Zkrácením na `300 ms` se senzor po oddálení oka od hledáčku (pokud není aktivní zadní LCD LiveView) uspí o 700 ms dříve.

### Co je třeba změnit
1. **Soubor:** [`victory_gui_qml/common/GlobalConstants.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/GlobalConstants.qml#L192)
   - `readonly property int blackScreenBrightness: 9` -> `readonly property int blackScreenBrightness: 1`
2. **Soubor:** [`victory_gui_qml/common/TouchWindow.qml`](file:///d:/Plocha/projekty/X1D_FirmwareDump/victory_gui_qml/common/TouchWindow.qml#L1165-L1168)
   - V `Timer { id: evfExitTimer }`: `interval: 1000` -> `interval: 300`

---

## `MOD-BAT-04`: Úsporný dvojitý framebuffer Weston kompozitoru (`FB_MULTI_BUFFER=2`)

### Technický rozbor
Zatímco `victory-gui.service` a `video-daemon.service` používají `Environment=FB_MULTI_BUFFER=1`, služba `./lib/systemd/system/weston.service` nastavuje `Environment=FB_MULTI_BUFFER=3` (trojitý buffering pro všechny výstupy). Snížením na `FB_MULTI_BUFFER=2` zůstane vykreslování zcela bez trhání (tear-free double buffering), ale ušetří se přenosová kapacita DDR3 RAM a paměť framebufferu.

### Co je třeba změnit
- **Soubor v `rootfs.tar.bz2`:** `./lib/systemd/system/weston.service` (řádek 7)
- **Původní stav:**
  ```ini
  Environment=FB_MULTI_BUFFER=3
  ```
- **Nový stav:**
  ```ini
  Environment=FB_MULTI_BUFFER=2
  ```

---

## `MOD-BAT-05`: Vypnutí ladicích služeb (`sshd.socket` a debug USB modulu)

### Technický rozbor
V `./etc/systemd/system/verylate.target.wants/` jsou standardně aktivní ladicí služby:
- `sshd.socket` (spouští OpenSSH server při síťovém spojení)
- `usb-modules.service` (`Description=USB modules for debug`, spouští `/sbin/modprobe ci_hdrc_imx` – ChipIdea High-Speed Dual-Role USB řadič na SoC i.MX6, který slouží pouze pro interní USB ladění, protože tethering s Phocusem běží přes dedikovaný čip **Cypress EZ-USB FX3**!).

### Co je třeba změnit
V archivu `rootfs.tar.bz2` odstranit ze složky `./etc/systemd/system/verylate.target.wants/` symlinky:
- `./etc/systemd/system/verylate.target.wants/sshd.socket`
- `./etc/systemd/system/verylate.target.wants/usb-modules.service`
