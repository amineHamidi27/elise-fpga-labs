# Guide de la séance de TP : Projet 3, Q1 (SPI vers DDS AD9834)

À suivre dans l'ordre. Coche les cases au fur et à mesure.
Les sections 4 et 5 sont prioritaires : ce sont les mesures qu'on ne peut faire qu'en TP.

---

## 0. Avant de partir (chez toi)

- [ ] Copier le dossier `Projet_3/q1/` sur une clé USB ou dans ton dépôt git.
- [ ] Préparer le top provisoire `test_spi_tx/` (voir section 4), qui doit être **écrit et simulé avant le TP**.
- [ ] Récupérer `chenillard_v2` sur Moodle (programme de la STM32).
- [ ] Charger le téléphone (photos de l'oscilloscope).
- [ ] Imprimer ou garder ouvert ce guide et `figures/state_diagram.png`.

---

## 1. Installation sur le PC du TP

```
mkdir -p ~/ELISE2/<ton_nom>          # dossier imposé : home/etudiant/ELISE2/your_name
cp -r <clé>/q1 ~/ELISE2/<ton_nom>/
cd ~/ELISE2/<ton_nom>/q1
source /home/jmfriedt/openxc7/export.sh     # une seule fois par terminal
```

- Utiliser **`Makefile.openXC7`**, et **pas** `Makefile.local`, qui ne sert que sur ton PC.
- Le Makefile cherche la chipdb dans `../chipdb/`. Si elle n'y est pas, il la génère lui-même, ce qui est **long** (plusieurs minutes). C'est normal la première fois.
- `make -f Makefile.openXC7 clean` **avant** chaque `make` (énoncé : « Do not forget to perform make clean »).
- L'erreur `ImportError: cannot import name 'antlr_to_tuple'` peut apparaître : elle est **sans gravité**. Ce qui compte, c'est que le `.bit` fasse plusieurs Mo.

---

## 2. Matériel et branchements

| Signal | GPIO (ports.xdc) | Broche FPGA | Vers la carte DDS |
|---|---|---|---|
| SDATA | GPIO[0] | G18 | SDATA |
| SCLK | GPIO[1] | H17 | SCLK |
| FSYNC | GPIO[2] | H18 | FSYNC |
| RESET | GPIO[3] | K18 | RESET (fixé à 0) |
| masse | GND | — | **GND commun obligatoire** |

- Programmateur JTAG Digilent HS2 sur le connecteur près de la prise Ethernet de la Red Pitaya (3V3, GND, TCK, TDO, TDI, TMS sont écrits sous la carte).
- Oscilloscope : sondes en **×10**, masse de chaque sonde sur un GND de la carte.

---

## 3. Programmer la STM32 (carte DDS) : à faire une fois

- [ ] Programmer la STM32 avec **`chenillard_v2`**.
- [ ] Vérifier que **les LEDs défilent** : la programmation a marché.

Pourquoi : la STM32 fournit l'horloge **MCLK = 70 MHz** du DDS et met ses propres broches MOSI et SCLK **en haute impédance**, pour ne pas entrer en conflit avec le FPGA.

---

## 4. Étape 1 : `spi_tx` seul à l'oscilloscope (exigé par l'énoncé)

> Énoncé : « The first entity will of course be simulated and tested with an oscilloscope before working on the Moore machine. »

### Top provisoire `test_spi_tx/`
Dossier séparé, pour ne pas toucher `top_spi` :
- `test_spi_tx.vhd` : IBUFDS + BUFG, une seule instance de `spi_tx` ;
- `data = x"2200"` (mot fixe) ;
- `enable = SW(0) and not fin` : l'envoi se répète tant que SW(0) = 1 ;
- `GPIO(0) = sdata`, `GPIO(1) = sclk`, `GPIO(2) = enable` (déclenchement de l'oscilloscope) ;
- une copie de `spi_tx.vhd`, de `ports.xdc` et du Makefile avec :
  ```
  PRJ        = test_spi_tx
  VHDL_BIBLI = spi_tx.vhd
  V_LIST     = test_spi_tx.v
  ```

### Commandes
```
cd test_spi_tx
make -f Makefile.openXC7 clean
make -f Makefile.openXC7
make -f Makefile.openXC7 load
```
Mettre ensuite **SW(0) à 1**.

### Oscilloscope
| Voie | Signal |
|---|---|
| CH1 | SCLK (GPIO[1]) |
| CH2 | SDATA (GPIO[0]) |
| CH3 | enable (GPIO[2]), sert au déclenchement |

Déclenchement sur CH3, front montant, environ 1,6 V. Base de temps : 500 ns/div pour le mot entier, puis 50 ns/div pour le zoom.

### À vérifier et à photographier
- [ ] **Période de SCLK = 160 ns** (6,25 MHz). Utiliser la mesure automatique ou les curseurs. **Photo 1**
- [ ] **16 fronts descendants** par mot, SCLK = 1 entre les mots.
- [ ] **SDATA = 0x2200**, lu sur les fronts descendants : `0010 0010 0000 0000`. **Photo 2** (500 ns/div)
- [ ] **SDATA change sur les fronts montants** de SCLK. **Photo 3** (50 ns/div)
- [ ] Noter les niveaux haut et bas (≈ 3,3 V et 0 V) et l'allure des fronts (dépassement, sonnerie).

Si quelque chose est faux, corriger `spi_tx.vhd`, **resimuler** avec `tb_spi_tx`, puis recompiler. Ne passer à l'étape 2 que quand l'étape 1 est validée.

---

## 5. Étape 2 : système complet `top_spi` avec le DDS

### Commandes
```
cd ~/ELISE2/<ton_nom>/q1
make -f Makefile.openXC7 clean
make -f Makefile.openXC7
make -f Makefile.openXC7 load
```

### Vérification de la carte (avant le DDS)
- [ ] **7 segments** : SW(3..2) choisit le quartet affiché. Vérifier les 4 quartets de 0x2200 : `0`, `0`, `2`, `2`.
  - Si l'affichage est **inversé** (segments allumés et éteints échangés), l'afficheur est actif à 0 : inverser `gfedcba` dans `top_spi.vhd`. **À noter pour le rapport.**
- [ ] **LEDs** : elles affichent l'octet qui contient le quartet choisi.

### Envoi au DDS
| Ordre | SW(1..0) | Mot | Rôle |
|---|---|---|---|
| 1 | 00 | 0x2200 | configuration (D13 = 1, D9 = 1) |
| 2 | 01 | 0x43A8 | FREQ0, 14 LSB de W |
| 3 | 10 | 0x40EA | FREQ0, 14 MSB de W, donc **1 MHz** |

Pour chaque ligne : positionner les switchs, **appuyer sur le bouton puis le relâcher**.

### Oscilloscope
| Voie | Signal |
|---|---|
| CH1 | SCLK |
| CH2 | SDATA |
| CH3 | FSYNC, sert au déclenchement (front **descendant**) |
| CH4 | sortie du DDS (JP2 : OUT / GND) |

### À vérifier et à photographier
- [ ] **FSYNC passe à 0** avant le premier front de SCLK, reste à 0 pendant les 16 bits, puis remonte. **Photo 4**
- [ ] Un **appui = un seul envoi**, même en gardant le bouton appuyé : c'est l'état WAIT_RELEASE.
- [ ] Le mot lu sur SDATA correspond aux switchs (0x2200, puis 0x43A8, puis 0x40EA).
- [ ] **Sortie du DDS** après les 3 envois : une sinusoïde à **1 MHz**. Mesurer la fréquence et l'amplitude. **Photo 5**
- [ ] Noter l'écart entre la fréquence mesurée et la fréquence théorique (70 MHz × 3 834 792 / 2^28 = 1,000 MHz).

---

## 6. En cas de problème

| Symptôme | Causes possibles |
|---|---|
| Rien sur SCLK | `.bit` non chargé, SW(0) à 0 (étape 1), horloge (IBUFDS/BUFG), mauvaise broche mesurée |
| SCLK correct mais SDATA toujours à 0 | mauvais mot sur `data`, mot avec très peu de 1 |
| Le DDS ne sort rien | STM32 non programmée (pas de MCLK 70 MHz) ; RESET pas à 0 ; GND non commun ; mots envoyés dans le mauvais ordre (0x2200 d'abord, puis LSB, puis MSB) ; W = 0 |
| Fréquence de sortie fausse | erreur dans le calcul de W, LSB et MSB inversés |
| Deux envois pour un seul appui | **rebonds** du bouton (pas d'anti-rebond). À expliquer dans le rapport |
| 7 segments inversé | afficheur actif à 0 : inverser la sortie |
| `make` très long au début | génération de la chipdb, normal la première fois |

---

## 7. À noter pendant la séance (pour le rapport)

- [ ] Le montage : modèle de l'oscilloscope, sondes ×10, longueur des câbles, masse commune.
- [ ] Chaque photo : base de temps, échelle verticale, ce qu'elle montre.
- [ ] Les valeurs mesurées : période de SCLK, fréquence et amplitude de la sortie du DDS.
- [ ] Tout comportement inattendu, avec une hypothèse sur la cause (le prof demande « why? »).
- [ ] Les modifications du code faites pendant la séance, et pourquoi.

---

## 8. Q2 (si le temps le permet)

Énoncé : ouvrir le projet `TP_M2_source` (dans `home/etudiant/seb`), **l'enregistrer depuis Vivado dans ton dossier**, l'adapter pour inclure le projet SPI avec le mot de 16 bits choisi par le **GPIO**, générer le bitstream, programmer le FPGA, écrire les registres GPIO avec `devmem`, tester à l'oscilloscope et conclure.
