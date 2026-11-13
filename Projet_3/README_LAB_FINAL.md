# Dernière séance : Projet 3, valider la Q1 et terminer la Q2

**Objectif de la séance :** obtenir la **sinusoïde à 1 MHz à la sortie du DDS**, d'abord avec la Q1 (switchs et bouton), puis avec la Q2 (GPIO et `devmem`), et prendre toutes les photos du rapport.

**Déjà validé lors des séances précédentes :**
- `spi_tx` seul à l'oscilloscope (SCLK = 160 ns, mots 0x2200 et 0xA5A5) ;
- `top_spi` : envois de 0x2200 et de 0x43A8 corrects (FSYNC, SCLK, SDATA).

**Ce qui manque :**
- la **sortie du DDS** (CH4 restait plate) ;
- **tout le test sur la carte de la Q2**.

---

## Plan horaire (indicatif)

| Durée | Tâche |
|---|---|
| 15 min | installation, `git pull`, branchements, STM32 |
| 45 min | **Q1 : obtenir la sinusoïde** (section 2, puis dépannage section 3 si besoin) |
| 60 min | **Q2 : `devmem` et sinusoïde** (section 4) |
| 15 min | photos manquantes, notes, `git push` |

Si la Q1 bloque plus de 30 minutes sur la sortie du DDS, **passe à la Q2** : avec `devmem`, on peut envoyer **n'importe quel mot**, ce qui aide beaucoup au dépannage (section 4.4).

---

## 0. Avant de partir

- [ ] `git push` fait chez toi ; en TP, un simple `git pull` suffit.
- [ ] Sur GitHub, tu dois avoir :
  - `Projet_3/q1/top_spi.bit` (table 7 segments actif à 0) ;
  - `Projet_3/q2/.../impl_1/design_1_wrapper.bit.bin` ;
  - `Projet_3/TP3_chenillard/test_original.bin` (programme de la STM32).
- [ ] Téléphone chargé pour les photos.

---

## 1. Installation

```
cd ~/ELISE2/<ton_nom>
git clone https://github.com/amineHamidi27/elise-fpga-labs.git    # ou git pull si déjà cloné
cd elise-fpga-labs/Projet_3
```

### Branchements Red Pitaya (connecteur E1) → carte DDS
| E1 | FPGA | Signal | Carte DDS |
|---|---|---|---|
| DIO0_N | G18 | SDATA | SDATA |
| DIO1_N | H17 | SCLK | SCLK |
| DIO2_N | H18 | FSYNC | FSYNC |
| DIO3_N | K18 | RESET | RESET |
| GND | | masse | **GND (obligatoire)** |

### Oscilloscope
| Voie | Signal | Échelle |
|---|---|---|
| CH1 | SDATA | 2 V/div |
| CH2 | SCLK | 2 V/div |
| CH3 | FSYNC | 2 V/div, déclenchement front descendant |
| CH4 | **sortie du DDS (JP2 : OUT, masse sur GND de JP2)** | 100 mV/div, couplage AC |

Le réglage de « Probe » dans le menu de chaque voie doit correspondre au curseur ×1 ou ×10 de la sonde.

### STM32 (carte DDS) : à faire en premier
- [ ] Brancher l'USB de la carte DDS.
- [ ] `ls /dev/ttyUSB*` : repérer le port qui **n'est pas** le câble Digilent (vérification : `udevadm info -q property -n /dev/ttyUSBx | grep ID_MODEL`).
- [ ] Flasher le programme du prof :
  ```
  cd TP3_chenillard
  stm32flash.sh -w test_original.bin /dev/ttyUSBx
  ```
  La sortie doit se terminer par `(100.00%) Done.`
- [ ] Appuyer sur RESET, ou débrancher et rebrancher la carte DDS.
- [ ] ✅ **Les LEDs de la carte DDS défilent.** Sans ça, pas de MCLK à 70 MHz, et la sortie du DDS restera plate.

---

## 2. Q1 : valider le système complet

### 2.1 Charger `top_spi`
```
cd ~/ELISE2/<ton_nom>/elise-fpga-labs/Projet_3/q1
source /home/jmfriedt/openxc7/export.sh
make -f Makefile.openXC7 load          # charge top_spi.bit (câble JTAG)
```
Si `top_spi.bit` pose problème, recompile-le : `make -f Makefile.openXC7 clean`, puis `make -f Makefile.openXC7`.

### 2.2 Vérifier la carte fille
- [ ] SW1-SW0 = 00 ; avec SW3-SW2, le 7 segments affiche **0, 0, 2, 2** (dans le bon sens, pas en négatif).
- [ ] Les LEDs affichent l'octet correspondant.

### 2.3 Envoyer les 3 mots
**Un appui sur le bouton = un mot complet.** SW1 et SW0 choisissent le mot. SW3 et SW2 ne servent qu'à l'affichage.

| Ordre | SW1 | SW0 | 7 segments (SW3-SW2 = 00, 01, 10, 11) | Mot |
|---|---|---|---|---|
| 1 | 0 | 0 | 0, 0, 2, 2 | 0x2200 |
| 2 | 0 | 1 | 8, A, 3, 4 | 0x43A8 |
| 3 | 1 | 0 | A, E, 0, 4 | 0x40EA |

Pour chaque mot : **vérifier le 7 segments**, puis appuyer sur le bouton et le relâcher.

- [ ] 📷 **Photo de l'envoi de 0x40EA** (mode SINGLE, déclenchement CH3 front descendant). On doit lire `0100 0000 1110 1010` : il manquait cette photo.

### 2.4 Regarder la sortie du DDS
- [ ] Oscilloscope en **RUN**, seulement **CH4** allumé, couplage AC, 100 mV/div, **500 ns/div**, déclenchement sur CH4.
- [ ] Si rien ne s'affiche : bouton **AUTO**, puis descendre jusqu'à 20 mV/div.
- [ ] ✅ **Sinusoïde de période 1 µs** (6 périodes à l'écran), **Freq ≈ 1,000 MHz**.
- [ ] 📷 **Photo de CH4** avec les mesures Freq et Vpp, prise une fois en couplage **DC** pour voir l'offset.
- [ ] Noter : la fréquence mesurée, la fréquence théorique (70 MHz × 3 834 792 / 2^28 = 999 999,94 Hz), l'écart, et l'amplitude.

**Si CH4 reste plat, passe à la section 3.**

---

## 3. Dépannage : la sortie du DDS reste plate

À faire dans l'ordre, en notant le résultat de chaque test (utile pour le rapport).

| # | Test | Résultat attendu | Si non |
|---|---|---|---|
| 1 | Les LEDs de la carte DDS défilent ? | oui | reflasher la STM32 (section 1) |
| 2 | **MCLK** : sonde sur la broche MCLK du DDS, ou PA8 de la STM32 | signal à **70 MHz**, atténué par l'oscilloscope de 50 MHz mais visible | pas d'horloge : le DDS ne peut rien générer |
| 3 | **Broche RESET du DDS**, mesurée **côté carte DDS** | **0 V** en permanence | si elle est à 1 ou en l'air, le DDS reste en reset (D9 = 1 donne le contrôle du reset à la broche). Vérifier le fil GPIO[3] → RESET |
| 4 | SDATA, SCLK et FSYNC mesurés **côté carte DDS** | même chose que côté Red Pitaya | mauvais contact ou fil inversé |
| 5 | Les 3 mots sont envoyés **dans l'ordre**, 0x40EA **compris** | 3 envois vus en mode SINGLE | refaire la séquence 2.3 |
| 6 | Broches **FSELECT** et **SLEEP** du DDS (sur le schéma de la carte DDS) | FSELECT = 0 (FREQ0), SLEEP = 0 | avec D9 = 1, ce sont ces broches qui commandent. Si FSELECT = 1, le DDS sort FREQ1 = 0 Hz |

**Le test le plus efficace, faisable seulement en Q2 :** envoyer une configuration **sans dépendre des broches** (section 4.4).

---

## 4. Q2 : le SPI piloté par le processeur (GPIO + devmem)

### 4.1 Programmer la Red Pitaya (sans le câble JTAG)
Sur le PC :
```
cd ~/ELISE2/<ton_nom>/elise-fpga-labs/Projet_3/q2
scp project_3_spi2026/project_3_spi2026.runs/impl_1/design_1_wrapper.bit.bin root@192.168.2.200:/tmp
```
Si le `.bit.bin` doit être recréé :
```
/home/jmfriedt/Xilinx/Vivado/2024.2/bin/bootgen -image spi.bif -arch zynq -process_bitstream bin -w on
```
Avant, adapte le chemin du `.bit` dans `spi.bif` au dossier du PC du TP.

Sur la Red Pitaya (`ssh root@192.168.2.200`, mot de passe `root`) :
```
cp /tmp/design_1_wrapper.bit.bin /lib/firmware/
echo design_1_wrapper.bit.bin > /sys/class/fpga_manager/fpga0/firmware
devmem 0x41200004 w 0        # GPIO_TRI  : canal 1 (mot) en sortie
devmem 0x4120000C w 0        # GPIO_TRI2 : canal 2 (commande) en sortie
```

### 4.2 Registres utilisés
| Adresse | Registre AXI GPIO | Rôle |
|---|---|---|
| 0x41200000 | GPIO_DATA (canal 1, 16 bits) | **le mot à envoyer** |
| 0x41200004 | GPIO_TRI | 0 = sortie |
| 0x41200008 | GPIO_DATA2 (canal 2) | **bit 0 = commande d'envoi** (remplace le bouton) |
| 0x4120000C | GPIO_TRI2 | 0 = sortie |

### 4.3 Envoyer la séquence de l'énoncé
Pour chaque mot, l'oscilloscope est en **SINGLE** (déclenchement CH3 front descendant) **avant** le `w 1` :
```
devmem 0x41200000 h 2200 ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0
devmem 0x41200000 h 43A8 ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0
devmem 0x41200000 h 40EA ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0
```
- [ ] 📷 Photo d'un envoi (par exemple 0x43A8) : FSYNC à 0 pendant les 16 bits, et le bon motif sur SDATA.
- [ ] Vérification : `devmem 0x41200000 h` relit le mot écrit.
- [ ] 📷 **Photo de CH4 : sinusoïde à 1 MHz.**

### 4.4 Si la sortie du DDS reste plate : configuration sans les broches
Avec **D9 = 0** (bit PIN/SW), le DDS ignore les broches RESET, SLEEP et FSELECT, et n'obéit qu'aux mots SPI. C'est la séquence recommandée par la datasheet : reset logiciel, fréquence, puis fin du reset.
```
devmem 0x41200000 h 2100 ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0   # B28=1, RESET=1
devmem 0x41200000 h 43A8 ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0   # FREQ0 LSB
devmem 0x41200000 h 40EA ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0   # FREQ0 MSB
devmem 0x41200000 h 2000 ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0   # RESET=0 : la sortie démarre
```
- Si la sinusoïde **apparaît** avec cette séquence et **pas** avec 0x2200, le problème vient des **broches** (RESET, FSELECT ou SLEEP) quand D9 = 1. C'est **une conclusion à écrire dans le rapport**, avec la référence de la datasheet AD9834 (registre de contrôle, bit PIN/SW).
- Si elle n'apparaît toujours pas : MCLK (test 2 de la section 3) ou le câblage.

### 4.5 Montrer l'intérêt de la Q2 : changer de fréquence depuis Linux
Une fois la sinusoïde obtenue :
Exemple pour **2 MHz** : W = 2·10^6 × 2^28 / 70·10^6 ≈ **7 669 584** ; W mod 16384 = 1872 = 0x750, donc LSB = **0x4750** ; W / 16384 = 468 = 0x1D4, donc MSB = **0x41D4** (fréquence obtenue : 70 MHz × 7 669 584 / 2^28 ≈ 1 999 999,9 Hz).
```
devmem 0x41200000 h 4750 ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0
devmem 0x41200000 h 41D4 ; devmem 0x41200008 w 1 ; devmem 0x41200008 w 0
```
Ensuite :
- [ ] 📷 photo de CH4 à la nouvelle fréquence ;
- [ ] noter le calcul (exemple chiffré pour le rapport).

C'est ce que la Q1 ne permettait pas (4 mots fixes) : en Q2, **n'importe quelle fréquence** se règle depuis le clavier (cours : « Add PS to write on the keyboard the data to send via SPI »).

---

## 5. Avant de partir (dernière séance)

- [ ] Toutes les photos transférées sur le PC, dans `Projet_3/q1/figures/` et `Projet_3/q2/figures/`.
- [ ] Notes : fréquences et amplitudes mesurées, écarts, comportements inattendus, et leur explication.
- [ ] Le montage décrit : oscilloscope, sondes, masse, câbles.
- [ ] `git add`, `git commit`, `git push` des photos et des modifications.
- [ ] Rendre le matériel tel qu'il était.

### Liste des photos du rapport
| Photo | Question | État |
|---|---|---|
| `spi_tx` seul : SCLK 160 ns, mot 0x2200, mot 0xA5A5 | Q1 | ✅ déjà prises |
| `top_spi` : envoi de 0x2200 et de 0x43A8 | Q1 | ✅ déjà prises |
| `top_spi` : envoi de 0x40EA | Q1 | ⬜ |
| **Sortie du DDS à 1 MHz (Q1)** | Q1 | ⬜ |
| Envoi via `devmem` (FSYNC, SCLK, SDATA) | Q2 | ⬜ |
| **Sortie du DDS à 1 MHz (Q2)** | Q2 | ⬜ |
| Sortie du DDS à une autre fréquence (Q2) | Q2 | ⬜ (si le temps le permet) |
