# 02 – Formát `.cim` a proces aktualizace

## 1. Struktura hlavičky kontejneru `.cim` (`VHABCIM`)

Prvních `128` bajtů (`0x00`–`0x7F`) souboru `X1D_v1_25_0.cim` (celková velikost `63 410 176` bajtů = `0x03C79000`) tvoří nešifrovaná hlavička:

```text
0000: 56 48 41 42 43 49 4d 0d 0a 31 36 30 31 32 35 34  VHABCIM..1601254
0010: 5f 50 56 46 0d 0a 32 35 35 2e 32 35 35 2e 32 35  _PVF..255.255.25
0020: 35 52 0d 0a 32 30 32 30 2d 31 30 2d 32 32 0d 0a  5R..2020-10-22..
0030: 31 30 3a 32 33 3a 30 39 0d 0a 1a 00 00 00 00 03  10:23:09........
0040: 41 88 6a 34 03 c7 90 00 00 00 00 00 00 00 00 00  A.j4............
```

### Rozbor polí v hlavičce:
1. **`VHABCIM\r\n`** – Magic string (*Victor Hasselblad AB Camera Image*).
2. **`1601254_PVF\r\n`** – Interní katalogové číslo / identifikátor balíčku firmwaru.
3. **`255.255.255R\r\n`** – Příznak verze kontejneru.
4. **`2020-10-22\r\n`** – Datum sestavení (`YYYY-MM-DD`).
5. **`10:23:09\r\n`** – Čas sestavení (`HH:MM:SS`).
6. **`0x1A`** (offset `0x3A`) – Znak konce textové hlavičky (DOS EOF).
7. **Offset `0x44` (`03 c7 90 00`)** – Celková velikost souboru v Big-Endian (`0x03C79000` = `63 410 176` bajtů).

---

## 2. Kryptografické schéma `.cim` kontejneru

Od offsetu `0x80` až do konce souboru má payload entropii `7.999997` bitů/bajt – je zašifrovaný algoritmem **AES-128-CBC**.

### Kryptografické konstanty (viz `hasselblad_extract.py`)

* **Statický AES-128 klíč (16 bajtů):**
  ```text
  93 F8 2C A2 44 AB 29 E0 36 69 34 D5 67 13 EE A2
  ```
* **Sůl pro odvození IV (`IV_SALT`, 16 bajtů):**
  ```text
  E6 36 FA DC 3D 99 2D 07 05 FD 95 8E 82 E3 14 7A
  ```
* **Sůl pro kontrolu integrity (`MAGIC_HASH_SALT`, 16 bajtů):**
  ```text
  CD 87 D7 27 FA 5E E7 F9 5D 43 E2 C4 9E 90 D7 0B
  ```

### Výpočet inicializačního vektoru (IV)
Z textového data a času v hlavičce (`2020-10-22` a `10:23:09`) se sestaví 16bajtový buffer `time_buf`:
* `time_buf[0] = year // 100` (`20`)
* `time_buf[1] = year % 100` (`20`)
* `time_buf[2] = month` (`10`)
* `time_buf[3] = day` (`22`)
* `time_buf[4] = hour` (`10`)
* `time_buf[5] = minute` (`23`)
* `time_buf[6] = second` (`9`)
* `time_buf[7..15] = 0x00`

Výsledné IV je:
$$\text{IV} = \text{MD5}(\text{IV\_SALT} \parallel \text{time\_buf})$$
Pro soubor `X1D_v1_25_0.cim` vychází IV:
```text
74d898a2302518ee02bd6e2e76637206
```

### Blokové dešifrování po 4096 bajtech (Chunked AES-CBC)
Zásadní specifikum formátu `.cim` spočívá v tom, že stav šifry AES-CBC nepokračuje plynule přes celý soubor:
1. Na začátku každého vnořeného souboru (a na začátku privátní hlavičky na `0x80`) se inicializuje AES-128-CBC s klíčem `STATIC_KEY` a odvozeným `IV`.
2. **Každých `4096` bajtů (`0x1000`) se `IV` znovu vyresetuje na původní výchozí `IV`!**

### Kontrola integrity (Salted MD5 a dvoufázový `PrivateHeader::Checksum`)
Soubor `.cim` obsahuje dvě nezávislé úrovně kontroly integrity, které démon `/usr/bin/upgrade-daemon` ověřuje před zahájením aktualizace:

1. **Dvoufázový kontrolní součet `PrivateHeader::Checksum` (offset `0x90..0x9F` v souboru, tj. `+0x10..+0x1F` v dešifrované privátní hlavičce):**
   * Funkce `Cim::PrivateHeader::verifyChecksumFormat3()` (na adrese `0x2d6ac` v `/usr/bin/upgrade-daemon`, volaná z `Cim::PrivateHeader::read()` na `0x30170`) počítá tento 16bajtový MD5 otisk ve dvou krocích:
     * **1. fáze:** Spočítá se MD5 ze **zašifrovaných** bajtů celého zbytku souboru od offsetu `0x200` (začátek `ItemHeader` tabulky) až do konce `.cim` souboru (`EOF`), za které se připojí 16bajtová sůl `MAGIC_HASH_SALT`:
       $$\text{Hash}_1 = \text{MD5}(\text{Encrypted\_Bytes}[0\text{x}200:\text{EOF}] \parallel \text{MAGIC\_HASH\_SALT})$$
     * **2. fáze:** K 16 surovým bajtům $\text{Hash}_1$ se připojí dešifrovaný zbytek privátní hlavičky od offsetu `+0x20` do `+0x180` (`352` bajtů obsahujících revizi hlavičky, počet položek a pole `Target`) a spočítá se finální MD5:
       $$\text{PrivateHeader::Checksum} = \text{MD5}(\text{Hash}_1 \parallel \text{Decrypted\_PrivateHeader}[0\text{x}20:0\text{x}180])$$
   * Tento algoritmus jsme zpětně ověřili na všech **6 oficiálních verzích firmwaru** (`v1.20.0` až `v1.25.0`) se 100% shodou.

2. **Kontrola integrity jednotlivých zabalených souborů (`ItemHeader` v `0x200..0x5FF`):**
   * Každý ze 4 záznamů v tabulce souborů (`0x100` B na položku, šifrováno samostatně s výchozím `IV`) obsahuje na offsetu `+0x24`:
     * `Offset` (4B Big-Endian)
     * `Size` (4B Big-Endian)
     * `Expected_Hash` (16B MD5)
     * Nulový padding + ASCII název souboru na `+0x60` zakončený `\r\n` na `+0x7E..+0x7F`
   * Integrita každého dešifrovaného souboru se ověřuje vzorcem:
     $$\text{Hash} = \text{MD5}(\text{Decrypted\_Content} \parallel \text{MAGIC\_HASH\_SALT})$$

> [!NOTE]
> Absence asymetrického podpisu (RSA/ECDSA) u `.cim` kontejneru 1. generace znamená, že kdokoliv se znalostí statického klíče, obou solí a dvoufázového výpočtu `PrivateHeader::Checksum` dokáže nejen rozbalit originální `.cim`, ale pomocí [`hasselblad_pack.py`](file:///d:/Plocha/projekty/X1D_FirmwareDump/hasselblad_pack.py) také sestavit 100% platný upravený `.cim` kontejner, který projde všemi kontrolami v `upgrade-daemon`.

---

## 3. Soubory vyextrahované z `X1D_v1_25_0.cim`

| Název souboru | Offset v `.cim` | Velikost (B) | MD5 kontrola | Popis |
| :--- | :--- | ---: | :---: | :--- |
| **`hbl-upgrade`** | `0x00000600` | `7 783` | `OK` | Hlavní aktualizační `/bin/sh` skript spouštěný démonem `upgrade-daemon` |
| **`rootfs`** | `0x00002600` | `63 123 278` | `OK` | `bzip2` komprimovaný `tar` archiv (`rootfs.tar.bz2`) celého Linuxu |
| **`uboot`** | `0x03C35600` | `269 312` | `OK` | Bootloader U-Boot s i.MX6 IVT hlavičkou (`d1 00 20 40...`) |
| **`hbl-kks-revisions`** | `0x03C77400` | `7 030` | `OK` | Pomocný skript kopírující `.dtb` soubory podle KKS revizí desek |

---

## 4. Jak přesně probíhá aktualizace ve fotoaparátu

1. **Spuštění (`upgrade-daemon`):**
   * Když uživatel v menu **Service → Check for Update** potvrdí aktualizaci z SD karty, GUI zavolá přes D-Bus metodu `com.hasselblad.upgrade.Upgrade` (viz `upgrade_from_slot.sh`).
   * `upgrade-daemon` dešifruje `.cim` soubor do dočasného adresáře `/media/data/upgrade/` a spustí `./hbl-upgrade`.
2. **Příprava neaktivního A/B slotu (`hbl-upgrade`):**
   * Skript zjistí aktivní slot pomocí `fw_printenv -n current_bootpart`.
   * Pokud systém běží ze Slotu A (`current_bootpart == 1`), cílem aktualizace se stane Slot B (`/dev/mmcblk3p3` + `/dev/mmcblk3p4`), a naopak.
   * Naformátuje cílový root oddíl jako `ext4` bez žurnálu (`mkfs.ext4 -E nodiscard` + `tune2fs -O ^has_journal`) a cílový boot oddíl jako `FAT32`.
3. **Rozbalení `rootfs` a jádra (`update_imx`):**
   * Rozbalí `rootfs` (`bzcat rootfs | tar xf - -C root_mnt`).
   * Zkopíruje kernel `zImage` a pomocí `hbl-kks-revisions` zkopíruje všechny `.dtb` soubory pod názvy odpovídajícími KKS číslům revizí (např. `/boot/0x5f701d1b` pro X1D Rev 3), aby si U-Boot při startu mohl načíst DTB přímo podle hodnoty v OTP registru.
   * Ověří, že pro KKS číslo aktuálního fotoaparátu (`cat /sys/fsl_otp/HW_OCOTP_GP1`) existuje v `/boot` příslušný `.dtb` soubor.
   * Zkopíruje `/etc/machine-id` ze starého systému do nového.
4. **Aktualizace koprocesorů (`program_nodes.sh`):**
   * Postupně přeflashuje:
     * `update_farm` (20 % progress) – FPGA obrazy `bootimage_even-wedge.bin` a `bootimage_odd-wedge.bin`
     * `update_spc` (40 % progress) – `power-control.bin`
     * `update_fx3` (60 % progress) – USB 3.0 čip `fx3_wedge.bin`
     * `update_touch` – konfigurace dotykového řadiče
     * `check_rtc` – kontrola hodin reálného času (`/dev/rtc1`)
     * `update_suc` (80 % progress) – mikrokontrolér `camera-control.bin` (vyžaduje, aby **nebyl** připojený USB kabel!)
5. **Přepnutí boot slotu (`hbl-upgrade` + `hbl-post-upgrade`):**
   * Nastaví v U-Boot env proměnné `emmcboot` a `upgrade=1`.
   * Po restartu skript `/usr/bin/hbl-post-upgrade` přepíše v SPI NOR paměti (`spi_imx` / `m25p80`) proměnnou `current_bootpart` na nový slot (`1 <-> 3`) a smaže `/media/data/upgrade`.
