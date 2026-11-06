# Projet 3 (SPI vers DDS AD9834) : Question 1, notes pour le rapport

Ces notes servent à rédiger le rapport. Elles ne sont pas à copier telles quelles.
Pour chaque point : ce qu'on a fait, **pourquoi**, et quelle **preuve** montrer (simulation, photo).

---

## 0. Ce que demande l'énoncé (TP_VHDL_ELISE2_2026b.pdf, pages 6-7)

- Une liaison SPI dans un seul sens : FPGA (maître) → DDS AD9834 (esclave).
- Correspondance des signaux : SDATA = MOSI, FSYNC = SS/. MISO n'est pas utilisé.
- SCLK : période t4 d'au moins 25 ns (40 MHz max). Prescaler `tscale` > 2, valeur par défaut 20, ce qui donne 125 MHz / 20 = 6,25 MHz.
- Paquets de 16 bits, **MSb en premier**.
- Le DDS lit SDATA sur le **front descendant** de SCLK, donc on change SDATA sur le **front montant**.
- Conception hiérarchique en 3 entités :
  1. émetteur (SCLK et N bits) ;
  2. machine de Moore (FSYNC et bouton) ;
  3. encapsulation de la carte (switchs, LEDs, 7 segments, GPIO).
- Sorties vers le DDS : GPIO[0] = SDATA, GPIO[1] = SCLK, GPIO[2] = FSYNC, GPIO[3] = RESET (fixé à 0).
- Exigences pour le rapport : diagramme d'états complet (transitions et sorties de chaque état), simulation de chaque entité avant l'assemblage, tous les .vhd en annexe (testbenches compris).

---

## 1. Entité 1 : `spi_tx.vhd` (FAIT, simulation OK)

### Interface
| Port | Sens | Rôle |
|---|---|---|
| `clk` | in | horloge FPGA 125 MHz (T = 8 ns) |
| `enable` | in | '1' : envoi ; '0' : reset (SCLK = 1, compteurs remis à zéro) |
| `data(N-1 downto 0)` | in | mot à envoyer |
| `sclk` | out | horloge SPI |
| `sdata` | out | bit envoyé (MOSI) |
| `fin` | out | passe à '1' quand les N bits sont envoyés |

Generics : `tscale = 20`, `N = 16`.

### Choix de conception (à expliquer dans le rapport)
- **Deux compteurs entiers.**
  - `count`, de 0 à `tscale-1`, avance à chaque cycle d'horloge ; c'est le diviseur de fréquence.
  - `bit_counter`, de `N-1` jusqu'à 0, recule d'une unité par période de SCLK ; il donne le numéro du bit envoyé.
- **Pourquoi pas un seul compteur de 0 à N·tscale-1 ?** Il faudrait diviser par `tscale`. Comme 20 n'est pas une puissance de 2, le FPGA devrait construire un vrai diviseur, qui coûte cher en logique. Avec deux compteurs, on n'a que des +1, des -1 et des comparaisons.
- **Tout découle du compteur du diviseur**, comme le demande le cours (« do not manage independently these 3 outputs ») :
  - `count = tscale/2 - 1` : SCLK passe à 0 au cycle suivant. C'est le front descendant, où le DDS lit le bit.
  - `count = tscale - 1` : SCLK repasse à 1 (front montant), `count` revient à 0, on passe au bit suivant, ou bien `fin = '1'` si c'était le dernier.
- **Une demi-période = 10 cycles** : SCLK vaut 1 pour count de 0 à 9 et 0 pour count de 10 à 19. Une période = 20 × 8 = **160 ns**.
- **Pourquoi `data(bit_counter - 1)` et pas `data(bit_counter)` ?** Un signal ne prend sa nouvelle valeur qu'à la fin du process. Dans le même cycle, `bit_counter` vaut encore l'ancienne valeur, donc pour envoyer le bit **suivant** il faut écrire `- 1`.
- **Le reset prépare le MSb** (`sdata <= data(N-1)`) : le premier bit est déjà stable avant le premier front descendant.
- **Après le dernier bit**, `fin = '1'` bloque le compteur et SCLK reste à 1, l'état de repos.
- **Un seul process synchrone** (`wait until rising_edge(clk)`). Le prof l'a demandé dans le Projet 1. Toutes les sorties sortent de registres.
- **Compteurs en `integer range`.** Le cours dit « use integers for arithmetic ». La plage fixe le nombre de bits : 5 bits pour 0..19, 4 bits pour 0..15.

### Remarque à mentionner
- La toute première demi-période haute de SCLK dure 9 cycles au lieu de 10, parce que le compteur démarre au premier front d'horloge où `enable` vaut 1.
- Ce n'est pas gênant : SCLK était déjà à 1 au repos, et le bit est stable avant le premier front descendant.
- À vérifier sur le chronogramme pour le prouver.

### Paramètres à tester (remarque du prof : « test for other parameter values »)
- [ ] `tscale` impair, par exemple 21 : 10 cycles à 1 et 11 à 0 ; expliquer pourquoi.
- [ ] `tscale` = 3, la valeur minimale (> 2).
- [ ] Une autre valeur de `N`, par exemple 8.

---

## 2. Testbench `tb_spi_tx.vhd` (FAIT)

### Scénario
1. `enable = '0'` pendant 10 T : on voit l'état de repos.
2. `enable = '1'` : envoi de **0x2200**, jusqu'à `fin = '1'`.
3. `enable = '0'` ; on change `data` **avant** l'attente de 50 T, puis `enable = '1'` : envoi de **0x4000**.

### Choix à expliquer
- `data` change **pendant** que `enable` vaut 0. Sinon le reset aurait chargé le MSb de l'ancien mot.
- `wait until fin = '1'` : on écrit `=` (comparaison), pas `<=`, qui voudrait dire « inférieur ou égal » dans une condition.
- Le choix des mots : 0x4000 a un seul bit à 1, donc il prouve peu. Envisager **0x43A8** ou **0xA5A5**, qui ont plus de transitions. Cours : « 111 and 111 ? 110 and 011 is better ».
- [ ] Ajouter éventuellement un process qui lit `sdata` à chaque `falling_edge(sclk)`, reconstitue le mot et le compare à `data` avec un `assert`.

### Commandes
```
ghdl -a --std=08 spi_tx.vhd tb_spi_tx.vhd
ghdl -e --std=08 tb_spi_tx
ghdl -r --std=08 tb_spi_tx --wave=tb_spi_tx.ghw --stop-time=10us
gtkwave tb_spi_tx.ghw tb_spi_tx.gtkw
```
`--stop-time` est nécessaire parce que le process d'horloge ne s'arrête jamais.

### Captures à faire (GTKWave)
- [ ] **Vue d'ensemble** : les 2 envois, avec `enable`, `sclk`, `sdata` et `fin`.
- [ ] **Zoom sur 2 ou 3 bits** : SDATA change sur le front montant de SCLK, et période de 160 ns mesurée avec deux marqueurs.
- [ ] **Zoom sur `count` et `bit_counter`** : count va de 0 à 19, bit_counter change quand count repasse à 0.
- [ ] **Fin d'envoi** : `fin` passe à 1 après le 16e bit et SCLK reste à 1.
- Pour chaque capture, dire **ce qu'elle prouve**, et relier explicitement la figure au texte (remarque du prof).

### Résultat (vérifié)
- Mot reconstitué à partir des fronts descendants : 0x2200, puis 0x43A8 lors d'un test de contrôle avec un 2e mot.
- 16 fronts descendants par mot, période de SCLK de 160 ns.

---

## 3. Entité 2 : `fsm_spi.vhd` (À FAIRE)

- [ ] Dessiner **d'abord** le diagramme d'états : états, conditions de transition, et sorties (`fsync`, `enable`) dans chaque état.
- Machine de **Moore** : les sorties dépendent uniquement de l'état.
- Ne pas écrire « clk = 1 » sur les transitions : c'est implicite (remarque du cours).
- Comportement demandé :
  1. attente (FSYNC = 1) ;
  2. appui sur le bouton : FSYNC = 0 pendant **1 période d'horloge FPGA** ;
  3. envoi (FSYNC = 0, `enable` = 1) ;
  4. quand `fin` = 1 **et** que le bouton est relâché, retour à l'attente.
- À expliquer : pourquoi attendre que le bouton soit relâché. Sinon, un seul appui enverrait le mot plusieurs fois.
- [ ] Testbench seul (`tb_fsm_spi.vhd`) : `fin` est donné par le testbench. Tester aussi le cas où `fin` arrive alors que le bouton est encore appuyé.
- [ ] Testbench de `fsm_spi` et `spi_tx` **ensemble** (« also simulate blocks assembly »).

---

## 4. Entité 3 : `top_spi.vhd` (À FAIRE)

- Horloge : IBUFDS + BUFG, à partir de la paire `adc_clk_p_i` / `adc_clk_n_i` (déjà en place).
- `SW(1 downto 0)` choisit le mot parmi 4.
- `SW(3 downto 2)` choisit le quartet affiché sur le 7 segments (`gfedcba`).
- `led_o` affiche l'octet qui contient ce quartet.
- `GPIO(3)` = RESET = '0' (inactif d'après la datasheet).
- Noms des ports identiques à `ports.xdc` (`SW`, `Button`, `led_o`, `gfedcba`, `GPIO`).
- [ ] Expliquer le décodage du 7 segments (et pourquoi le segment a est le LSb ; remarque du cours).

### Mots à envoyer au DDS
- **0x2200** pour la configuration :
  - D15 et D14 = 00 : écriture dans le registre de contrôle ;
  - D13 = 1 : les 28 bits sont mis à jour en 2 paquets, LSB d'abord ;
  - D9 = 1 : le reset passe par la broche matérielle.
- Fréquence : $f_{out} = f_{MCLK} \cdot W / 2^{28}$, avec $f_{MCLK} = 70$ MHz.
- **Exemple chiffré** (le prof en demande) pour 1 MHz :
  - W = 10^6 × 2^28 / 70·10^6 ≈ 3 834 792 = 0x3A83A8 ;
  - 14 bits LSB = 0x03A8, avec D15 D14 = 01 (FREQ0) : **0x43A8** ;
  - 14 bits MSB = 0x00EA, avec D15 D14 = 01 : **0x40EA** ;
  - fréquence réellement obtenue : 70·10^6 × 3 834 792 / 2^28 ≈ 1,000 MHz (résolution 70 MHz / 2^28 ≈ 0,26 Hz).
- [ ] Choisir le 4e mot, par exemple une autre fréquence, et refaire le calcul.
- **Ordre d'envoi** : 0x2200, puis le paquet LSB, puis le paquet MSB.
- **Source à citer** : la datasheet de l'AD9834, avec le numéro de la table ou de la figure du registre de contrôle et du chronogramme SPI (le prof demande d'où vient chaque information).

---

## 5. Tests sur la carte (À FAIRE)

- [ ] Programmer la STM32 avec `chenillard_v2` (Moodle) : elle fournit le MCLK de 70 MHz et met ses broches MOSI et SCLK en haute impédance. Les LEDs qui défilent confirment que la programmation a marché.
- [ ] Mesurer `spi_tx` seul à l'oscilloscope (SCLK et SDATA) **avant** la machine de Moore. Faire une photo.
- [ ] Mesurer SDATA, SCLK et FSYNC pendant un envoi. Faire une photo et décoder le mot à la main.
- [ ] Mesurer la sortie du DDS (JP2) et vérifier la fréquence calculée. Faire une photo.
- Décrire le montage : oscilloscope, sonde ×1 ou ×10, couplage, masse, longueur des câbles.
- Pour chaque observation, dire **pourquoi** on obtient ce résultat (le prof demande « any idea why? »).

---

## 6. Liste de contrôle finale (remarques du prof sur le Projet 1)

- [ ] Un exemple chiffré après chaque formule.
- [ ] Chaque figure reliée au texte et commentée (ce qu'elle prouve).
- [ ] Les sources citées : datasheet AD9834, avec numéro de figure ou de table et page.
- [ ] Les choix de conception expliqués (pourquoi, pas seulement quoi).
- [ ] Un seul process synchrone par entité, aucun `x <= not x`.
- [ ] Le diagramme d'états complet (transitions et sorties).
- [ ] Toutes les entités simulées seules, puis assemblées.
- [ ] Tous les .vhd en annexe, testbenches compris.
- [ ] Ce que vous avez appris (« explain everything you've learnt »).
