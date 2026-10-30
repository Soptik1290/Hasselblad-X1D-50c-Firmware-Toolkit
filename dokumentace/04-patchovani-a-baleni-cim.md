# 04 – Analýza patchování `victory-gui` a balení `.cim`

Tento dokument detailně popisuje:
1. Jak jsou uvnitř ELF binárky `/usr/bin/victory-gui` uložené a zkomprimované QML/JS/PNG soubory (Qt Resource System) a jak je přepisuje skript [`patch_victory_qrc_file.py`](../patch_victory_qrc_file.py).
2. Jak přesně démon `/usr/bin/upgrade-daemon` parsuje interní struktury `.cim` kontejneru (`Cim::PublicHeader`, `Cim::PrivateHeader`, `Cim::ItemHeader`) a jak funguje zpětné zabalení pomocí [`hasselblad_pack.py`](../hasselblad_pack.py).

---

## 1. Vnitřní struktura Qt Resource (`qrc://`) v `victory-gui`

Binárka `victory-gui` (`2 210 236` bajtů) má v sekci `.rodata` zkompilované 3 tabulky standardního formátu **Qt Resource System**:

| Tabulka | Offset v `victory-gui` | Velikost / Rozsah | Účel |
| :--- | :--- | :--- | :--- |
| **`DATA_BASE` (`qt_resource_data`)** | `0x0FC7F8` | `898 636` B (`0x0FC7F8` – `0x1D7E44`) | Samotný obsah všech 405 souborů (QML, JS, PNG, TTF) |
| **`NAMES_BASE` (`qt_resource_name`)** | `0x1D7E44` | `18 860` B (`0x1D7E44` – `0x1DC7F0`) | Názvy souborů a složek v UTF-16BE (`[délka 2B][hash 4B][UTF-16BE znaky]`) |
| **`TREE_BASE` (`qt_resource_struct`)** | `0x1DC7F0` | `14` B na uzel | Stromová struktura adresářů a souborů |

### Formát uzlu v `TREE_BASE` (14 bajtů, Big-Endian)
Každý uzel v `TREE_BASE + index * 14` má strukturu:
* `+0x00` (`4B`): `name_offset` – offset názvu vůči `NAMES_BASE`
* `+0x04` (`2B`): `flags` – příznaky uzlu:
  * `0x02` = adresář (následuje `a` = počet potomků, `b` = index prvního potomka)
  * `0x01` = soubor komprimovaný pomocí **`zlib`** (`qCompress`)
  * `0x00` = nekomprimovaný soubor (např. některé již komprimované PNG)
* `+0x06` (`4B`): `a` – u adresáře počet položek, u souboru locale/country příznaky
* `+0x0A` (`4B`): `b` (`data_offset`) – u souboru **offset dat vůči `DATA_BASE`**

### Formát komprimovaného souboru v `DATA_BASE + data_offset` (`flags & 0x1`)
Qt ukládá `zlib`-komprimované zdroje (s hlavičkou `qCompress`) v tomto tvaru:
```text
[celková délka bloku N (4B Big-Endian)]
[nekomprimovaná velikost souboru U (4B Big-Endian)]
[zlib stream (N - 4 bajtů, začíná 0x78 0x9C nebo 0x78 0xDA)]
```
Celková velikost zabraná v `DATA_BASE` je tedy `4 + N = 8 + len(zlib_stream)` bajtů.

---

## 2. Jak funguje in-place patchování (`patch_victory_qrc_file.py`)

Skript [`patch_victory_qrc_file.py`](../patch_victory_qrc_file.py) nemění offsety v `TREE_BASE`, takže všechny ostatní soubory i binární kód v `victory-gui` zůstávají na svém místě. Postup při přepsání jednoho QML/JS souboru:

1. Projede strom `TREE_BASE`, najde hledanou cestu (např. `components/popups/PopoverFocusMode.qml`) a její `data_offset`.
2. Spočítá **velikost slotu (`slot_size`)** jako rozdíl mezi `data_offset` upravovaného souboru a nejbližším vyšším `data_offset` následujícího souboru v `DATA_BASE`.
3. Zkomprimuje nový soubor s maximální kompresí `zlib.compress(replacement, 9)`.
4. Pokud se `8 + len(compressed)` vejde do `slot_size`:
   * Zapíše novou délku `4 + len(compressed)` (4B BE) a novou nekomprimovanou délku `len(replacement)` (4B BE).
   * Zapíše nový `zlib` stream.
   * Zbytek slotu (`slot_size - needed`) vynuluje (`0x00`).

### Přehled velikostí slotů u nejdůležitějších QML/JS souborů

Protože originální firmware kompiloval QML soubory s výchozí úrovní komprese `zlib` (nikoliv maximální úrovní `9`), samotné překomprimování úrovní `9` okamžitě ušetří desítky až stovky bajtů:

| Soubor v `victory-gui` | Původní velikost | Velikost slotu | Po `zlib` (level 9) | Volná rezerva (bez mazání komentářů) |
| :--- | ---: | ---: | ---: | ---: |
| `common/TouchWindow.qml` | `100 512` B | `18 120` B | `17 822` B | **`+298` B** |
| `settings/SettingsGeneric.qml` | `59 881` B | `9 968` B | `9 741` B | **`+227` B** |
| `controlscreen/ControlScreen.qml` | `62 132` B | `8 157` B | `7 947` B | **`+210` B** |
| `main.qml` | `48 941` B | `8 676` B | `8 509` B | **`+167` B** |
| `settings/scripts/MenuItemSpecificationsWedge.js` | `42 105` B | `6 052` B | `6 026` B | **`+26` B** |
| `components/popups/PopoverFocusMode.qml` | `4 323` B | `1 184` B | `1 183` B | **`+1` B** |
| `DebugCam.qml` | `2 291` B | `670` B | `669` B | **`+1` B** |

> [!TIP]
> **Jak získat ještě mnohem více místa ve slotu:**
> Všechny QML a JS soubory v `victory-gui` obsahují spoustu vývojářských komentářů (`// ...`, `/* ... */`) a odsazení mezerami. Odstraněním jediného komentáře v `PopoverFocusMode.qml` nebo `MenuItemSpecificationsWedge.js` získáš stovky bajtů volného místa ve slotu pro vlastní kód!

### Příklad použití `patch_victory_qrc_file.py`
```powershell
python patch_victory_qrc_file.py `
  "X1D_v1_25_0_extracted\victory-gui" `
  "components/popups/PopoverFocusMode.qml" `
  "victory_gui_qml\components\popups\PopoverFocusMode.qml" `
  -o "X1D_v1_25_0_extracted\victory-gui-patched"
```

---

## 3. Detailní struktura hlaviček `.cim` podle `/usr/bin/upgrade-daemon`

Analýzou binárky `/usr/bin/upgrade-daemon` (třídy `Cim::PublicHeader`, `Cim::PrivateHeader`, `Cim::ItemHeader` a `Cim::EncryptedFileReader`) jsme zrekonstruovali kompletní přesnou strukturu `.cim` kontejneru:

### A) `Cim::PublicHeader` (`0x0000` – `0x007F`, `128` bajtů, nešifrováno)
* `0x00`..`0x39`: Textové řádky oddělené `\r\n` (`File Id = VHABCIM`, `Part number = 1601254_PVF`, `Version = 255.255.255R`, `Generation date = 2020-10-22`, `Generation time = 10:23:09`).
* `0x3A`: `0x1A` (`EOF`).
* `0x3B`..`0x3E`: `00 00 00 00` (`Zero Padding`).
* `0x3F`: `0x03` (`CIM Format = 3`).
* `0x40`..`0x43`: `41 88 6A 34` (konstantní příznak `isEncrypted` – stejný ve všech šifrovaných `.cim` souborech!).
* `0x44`..`0x47`: Celková velikost `.cim` souboru v bajtech (Big-Endian `uint32`, u X1D v1.25.0 je to `0x03C79000` = `63 410 176` B).
* `0x48`..`0x7F`: `Zero padding` (`0x00`).

### B) `Cim::PrivateHeader` (`0x0080` – `0x01FF`, `384` bajtů, šifrováno s vlastním resetem IV)
* `0x0080`..`0x008F`: `Identifier1..4` = `42 42 42 42 4E 41 52 47 45 47 41 48 3C C3 5A A5` (`"BBBBNARGEGAH"` + `0x3CC35AA5`; řetězec `NARGEGAH` pozpátku je **`HAGEGRAN`** – příjmení autora formátu v Hasselbladu).
* `0x0090`..`0x009F`: **`Checksum` privátní hlavičky (16 bajtů)** – dvoufázový MD5 otisk ověřovaný funkcí `Cim::PrivateHeader::verifyChecksumFormat3()` (na adrese `0x2d6ac` v `/usr/bin/upgrade-daemon`, volané z `Cim::PrivateHeader::read()` na `0x30170`). Počítá se následovně:
  1. **1. fáze:** Spočítá se solený MD5 ze všech **zašifrovaných** bajtů od `0x0200` (začátek `ItemHeader` tabulky) až do konce `.cim` souboru (`EOF`):
     $$\text{hash}_1 = \text{MD5}(\text{encrypted\_bytes}[0\text{x}200:\text{EOF}] \parallel \text{MAGIC\_HASH\_SALT})$$
  2. **2. fáze:** K 16 surovým bajtům $\text{hash}_1$ se připojí dešifrovaná část `PrivateHeader` od offsetu `+0x20` do `+0x180` (`0x00A0`..`0x01FF` v souboru, tj. `352` bajtů):
     $$\text{PrivateHeader::Checksum} = \text{MD5}(\text{hash}_1 \parallel \text{priv\_plain}[0\text{x}20:0\text{x}180])$$
  Tento vzorec jsme ověřili na všech **6 oficiálních verzích firmwaru** (`v1.20.0` až `v1.25.0`) se 100% shodou.
* `0x00A0`..`0x00A7`: `Build number` (`00 00 00 00 00 00 00 2A` = `42` u v1.25.0).
* `0x00A8`..`0x00AB`: Unix timestamp v Big-Endian (`0x5F915D8D` = `2020-10-22 10:23:09 UTC`).
* `0x00AC`..`0x00BB`: `Generated by` (`"build2\0...\r\n"`).
* `0x00BC`..`0x00BF`: `Number of items` (`00 00 00 04`).
* `0x00C0`..`0x01FF`: `HW compatibility` a `Serial number` (vynulováno `0x00`).

### C) `Cim::ItemHeader` (`0x0200` – `0x05FF`, `4 × 256` bajtů, každá položka šifrovaná s vlastním resetem IV!)
Důležité zjištění: `Cim::EncryptedFileReader` **resetuje AES-CBC IV na začátku každého `ItemHeader` bloku** (`0x0200`, `0x0300`, `0x0400`, `0x0500`). Po dešifrování s resetovaným IV má každý 256bajtový `ItemHeader` tuto čistou strukturu:
* `+0x00`..`+0x23`: `0x00` (`Board type`, `Build type`, `Status`, `Commited by` – nevyužito / nulové).
* `+0x24`..`+0x27`: `Offset` souboru v `.cim` (4B Big-Endian, zarovnaný na `0x200`).
* `+0x28`..`+0x2B`: `Length` – přesná velikost souboru v bajtech (4B Big-Endian).
* `+0x2C`..`+0x3B`: `Checksum` – 16B `MD5(obsah_souboru + MAGIC_HASH_SALT)`.
* `+0x3C`..`+0x5F`: `0x00` (`HW compatibility`, `Bits reversed`).
* `+0x60`..`+0x7D`: `Image name` – ASCII název souboru (`hbl-upgrade`, `rootfs`, `uboot`, `hbl-kks-revisions`) doplněný nulami.
* `+0x7E`..`+0x7F`: `0D 0A` (`\r\n`).
* `+0x80`..`+0xFF`: `0x00` (`Commit ref`).

---

## 4. Zpětné zabalení `.cim` (`hasselblad_pack.py`)

Skript [`hasselblad_pack.py`](../hasselblad_pack.py) sestaví z upravené složky (`hbl-upgrade`, `rootfs`, `uboot`, `hbl-kks-revisions`) nový `.cim` soubor:
1. Převezme `PublicHeader` (`0x00`..`0x7F`) a šablonu `PrivateHeader` (`0x80`..`0x1FF`) z původního `X1D_v1_25_0.cim`.
2. Pro všechny 4 soubory spočítá novou délku, offset a solený MD5 hash `MD5(data + MAGIC_HASH_SALT)`.
3. Vygeneruje a zašifruje 4 hlavičky `Cim::ItemHeader` (`0x200`..`0x5FF`).
4. Zašifruje samotné soubory po 4096bajtových blocích (s resetem IV každých 4096 B) a aktualizuje celkovou velikost v `PublicHeader` (`0x44`..`0x47`).
5. Ze všech zašifrovaných bajtů `0x200..EOF` spočítá dvoufázový `PrivateHeader::Checksum`, zapíše jej na offset `+0x10..+0x1F` privátní hlavičky a zašifrovaný `PrivateHeader` zapíše na `0x80..0x1FF`.

```powershell
python hasselblad_pack.py `
  -t "firmware\X1D_v1_25_0.cim" `
  -i "X1D_v1_25_0_extracted" `
  -o "firmware\X1D_v1_25_0_custom.cim"
```
