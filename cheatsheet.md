# Nvim Cheatsheet — Pedro

> Leader = `<Space>` · Ouvre cette cheatsheet : `nvim ~/.config/nvim/cheatsheet.md`

---

## QUICK START (les 10 keys must-know)

| Key | Action |
|-----|--------|
| `jk` ou `jj` | Sortir d'insert mode sans bouger les doigts d'`Esc` |
| `Ctrl+S` | Sauver |
| `<Space>e` | Explorateur fichiers |
| `<Space>ff` | Find files (fuzzy) |
| `<Space>fg` | Live grep dans le projet |
| `<Space>gg` | Lazygit |
| `<Space>cf` | Format manuel |
| `gd` | Go to definition (LSP) |
| `K` | Hover doc (LSP) |
| `<Space>ca` | Code action (LSP) |

Si tu connais que ces 10, tu fais déjà 60% du job au clavier.

---

## PLAN D'APPRENTISSAGE (8 semaines pour automatiser)

| Semaine | Focus | Pour quoi |
|---------|-------|-----------|
| 1 | `hjkl`, `w/b/e`, `dd`, `cc`, `.` | Navigation et édition de base |
| 2 | Text objects : `ciw`, `ci"`, `ci)`, `da}` | Le vrai power move vim |
| 3 | `f/t/;/,`, `/`/`?`/`n`/`N` | Movement précis |
| 4 | Marks (`m`, `'`), Flash (`s`) | Sauter rapidement |
| 5 | Registers (`"a`, `"+`), Macros (`q`, `@`) | Automatiser le répétitif |
| 6 | LSP (`gd`, `K`, `gr`, `<Space>ca/cr`) | Navigation code |
| 7 | Surround (`cs/ds/ys`), Harpoon | Refacto + multi-fichier |
| 8 | Debug (F9, `<Space>dc/do/dO/di`) | Sortir du `printf`-debugging |

`:VimBeGood` chaque jour 10 min jusqu'à ce que les motions soient instinctives.

---

# VIM FONDAMENTAUX

## Opérateurs (combinent avec motions/text objects)

| Key | Action |
|-----|--------|
| `d` | Delete |
| `c` | Change (delete + insert) |
| `y` | Yank |
| `v` | Visual select |
| `>` / `<` | Indent / dedent |
| `gu` / `gU` | Lowercase / uppercase |
| `=` | Auto-indent |

## Motions (où aller)

| Key | Action |
|-----|--------|
| `w` / `b` / `e` | Mot suivant / précédent / fin de mot |
| `W` / `B` / `E` | Idem WORD (ignore ponctuation) |
| `0` / `^` / `$` | Début / premier non-blanc / fin de ligne |
| `f{c}` / `F{c}` | Jump au char `c` (avant / arrière) |
| `t{c}` / `T{c}` | Idem mais s'arrête juste avant |
| `;` / `,` | Répète f/t suivant / précédent |
| `gg` / `G` | Début / fin du fichier |
| `{` / `}` | Paragraphe précédent / suivant |
| `%` | Saute à la parenthèse/bracket correspondante |
| `H` / `M` / `L` | Haut / milieu / bas de l'écran |

## Text Objects (le power move)

`i` = inside, `a` = around (inclut délimiteurs)

| Key | Action |
|-----|--------|
| `iw` / `aw` | Mot |
| `i"` / `a"` | Entre `"..."` |
| `i'` / `a'` | Entre `'...'` |
| `i)` / `a)` | Entre `(...)` |
| `i]` / `a]` | Entre `[...]` |
| `i}` / `a}` | Entre `{...}` |
| `it` / `at` | Tag HTML/XML |
| `ip` / `ap` | Paragraphe |
| `is` / `as` | Phrase |

**Combos essentiels** : `ciw` (change le mot), `ci"` (change le contenu d'une string), `da)` (supprime fonction et parenthèses), `yi}` (yank un bloc), `vit` (sélectionne dans un tag).

## Search & Replace

| Key | Action |
|-----|--------|
| `/foo` | Cherche `foo` en avant |
| `?foo` | Cherche `foo` en arrière |
| `n` / `N` | Match suivant / précédent |
| `*` / `#` | Cherche le mot sous le curseur (avant/arrière) |
| `:%s/old/new/g` | Replace tout dans le buffer |
| `:%s/old/new/gc` | Replace avec confirmation |
| `<Space>r` | Match flottant (custom) sur le mot sous curseur |
| `<Space>R` | Match flottant avec saisie libre |

## Marks (revenir où t'étais)

| Key | Action |
|-----|--------|
| `m{a-z}` | Pose un mark local au buffer (lettres minuscules) |
| `m{A-Z}` | Pose un mark global (majuscules — marche entre fichiers) |
| `'a` | Saute au début de ligne du mark `a` |
| `` `a `` | Saute exactement à la position du mark `a` |
| `''` | Retour à la position avant le dernier saut |
| `'.` | Retour à la dernière modif |
| `<Space>sm` | Picker Snacks : voir tous tes marks avec preview, jump direct |

> Workflow utile : `mA` sur ligne importante du fichier X → tu codes ailleurs → `<Space>sm` → tu vois tes marks listés → jump direct au mark A (cross-file). Plus rapide que Harpoon pour les "spots à retenir 5 minutes".

## Registers (copy/paste avancé)

| Key | Action |
|-----|--------|
| `"ay` | Yank dans le register `a` |
| `"ap` | Paste depuis register `a` |
| `"+y` / `"+p` | Yank / paste vers/depuis le clipboard système |
| `"0` | Le dernier yank (jamais écrasé par delete) |
| `:reg` | Liste tous les registers et leur contenu |

## Macros (automatiser le répétitif)

| Key | Action |
|-----|--------|
| `q{a-z}` | Démarre l'enregistrement dans register `a` |
| `q` | Stoppe l'enregistrement |
| `@a` | Rejoue la macro `a` |
| `@@` | Rejoue la dernière macro |
| `5@a` | Rejoue la macro `a` 5 fois |

**Workflow** : `qa` → fais ton édition → `q` → place curseur ailleurs → `@a` ou `5@a`.

## Undo / Redo / Repeat

| Key | Action |
|-----|--------|
| `u` | Undo |
| `Ctrl+R` | Redo |
| `.` | **Répète la dernière action** (super utilisé avec text objects) |

---

# TES KEYMAPS CUSTOM

## Général

| Key | Action |
|-----|--------|
| `jk` / `jj` | Escape |
| `Ctrl+S` | Save |
| `<Space>q` / `<Space>Q` | Quit / force quit all |

## Clipboard système (séparé du registre vim)

| Key | Action |
|-----|--------|
| `<Space>y` / `<Space>Y` | Yank vers clipboard / yank ligne |
| `<Space>p` / `<Space>P` | Paste depuis clipboard / paste avant |
| `p` (visual) | Paste sans écraser le registre |

## Navigation centrée

| Key | Action |
|-----|--------|
| `Ctrl+D` / `Ctrl+U` | Scroll demi-page bas / haut (centré) |
| `n` / `N` | Recherche suivant / précédent (centré) |

## Headers & format (F-keys)

| Key | Action |
|-----|--------|
| `F1` | Header 42 |
| `F2` | Bannière Pedro (auto-update au save) |
| `<Space>cf` | Format manuel (clang-format / prettier selon filetype) |

> Pour `make`, `make re`, `make debug`, `make asan`, etc. : utilise le terminal flottant `Ctrl+/` et tape la commande.

## Terminal

| Key | Action |
|-----|--------|
| `Ctrl+/` | Terminal flottant (root du projet) |
| `<Space>ft` / `<Space>fT` | Terminal flottant (root / cwd) |
| `<Space>tb` / `<Space>tB` | Terminal split bas (root / cwd) |
| `Esc Esc` | Quitter mode terminal (revenir en NORMAL) |
| `Ctrl+\ puis Ctrl+N` | Idem (alternative universelle si le double Esc passe pas) |

> En mode terminal, toutes tes touches vont dans le programme. Tu dois sortir AVANT que `Ctrl+H/J/K/L` (navigation fenêtres) marche.

---

# NAVIGATION (LazyVim)

## Fichiers

| Key | Action |
|-----|--------|
| `<Space>e` | Explorer (neo-tree) |
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep |
| `<Space>fb` | Buffers ouverts |
| `<Space>fr` | Fichiers récents |
| `<Space>/` | Grep dans le projet |
| `<Space>,` | Switcher de buffer |
| `<Space>:` | Historique commandes |

## Fenêtres

| Key | Action |
|-----|--------|
| `Ctrl+H/J/K/L` | Naviguer entre fenêtres |
| `Ctrl+Flèches` | Resize fenêtre |
| `<Space>-` / `<Space>\|` | Split horizontal / vertical |
| `<Space>wd` | Fermer la fenêtre |

## Harpoon (navigation rapide multi-fichiers)

| Key | Action |
|-----|--------|
| `<Space>H` | Ajouter le fichier courant à la liste |
| `<Space>h` | Menu Harpoon |
| `<Space>1..9` | Switch instant vers fichier 1..9 |

> Workflow : tes 3-4 fichiers principaux, `<Space>H` chacun, puis `<Space>1/2/3` pour switcher.

---

# CODE

## LSP

| Key | Action |
|-----|--------|
| `K` | Hover (doc du symbole) |
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `gD` | Declaration |
| `gK` | Signature help |
| `<Space>ca` | Code action |
| `<Space>cr` | Rename |
| `<Space>cd` | Line diagnostic |
| `]d` / `[d` | Diagnostic suivant / précédent |

## Trouble (diagnostics, TODOs, refs)

| Key | Action |
|-----|--------|
| `<Space>xx` | Diagnostics du projet |
| `<Space>xX` | Diagnostics du buffer |
| `<Space>xt` | Tous les TODOs/FIXME du projet |
| `<Space>xT` | Filtre TODO + FIX + FIXME |
| `<Space>cS` | LSP refs / defs / impls |

## Aerial (outline / symbols sidebar)

Sidebar persistante avec la liste des fonctions/symbols du fichier. Suit ton curseur (le symbol courant est highlighté).

| Key | Action |
|-----|--------|
| `<Space>cs` | Toggle la sidebar Aerial |
| `j` / `k` (dans sidebar) | Naviguer entre symbols |
| `<Entrée>` (dans sidebar) | Jump au symbol |
| `q` (dans sidebar) | Fermer |

## Todo-comments

`TODO:`, `FIXME:`, `HACK:`, `WARN:`, `NOTE:`, `BUG:`, `PERF:`, `TEST:` highlightes auto.

| Key | Action |
|-----|--------|
| `]t` / `[t` | TODO suivant / précédent |

---

# DEBUG (DAP)

> **Prérequis** : binaire avec `-g`. Utilise `F3` (`make debug`) ou `F4` (`make asan`) avant de lancer.

## Workflow rapide

1. `F3` ou `F4` → recompile avec infos debug
2. Curseur sur la ligne suspecte → `F9` pose un breakpoint
3. `<Space>dc` → choisit "Launch" → entrée pour valider le binaire pré-rempli
4. Le programme s'arrête sur le breakpoint, l'UI s'ouvre
5. Avance avec les step keymaps ci-dessous
6. `<Space>dt` quand fini

## Contrôle de session

| Key | Action |
|-----|--------|
| `F9` | Toggle breakpoint |
| `<Space>dB` | Breakpoint avec condition |
| `<Space>dc` | Run / continue |
| `<Space>da` | Run avec arguments |
| `<Space>dC` | Run jusqu'au curseur |
| `<Space>dl` | Re-lance la dernière config |
| `<Space>dt` | Terminate |
| `<Space>dP` | Pause |

## Step (F-keys = workflow rapide)

| Key | Action |
|-----|--------|
| `F9` | Toggle breakpoint |
| `F10` | Step **OVER** (passe la ligne, n'entre pas) |
| `F11` | Step **INTO** (entre dans la fonction) |
| `F12` | Step **OUT** (sort de la fonction) |
| `<Space>dj` / `<Space>dk` | Descend / monte dans la pile d'appels |

> Les `<Space>dO`, `<Space>di`, `<Space>do` marchent toujours, mais les F-keys sont plus rapides en flow continu.

## Inspection

| Key | Action |
|-----|--------|
| `<Space>du` | Toggle l'UI debug |
| `<Space>de` | Eval expression sous le curseur |
| `<Space>dr` | Toggle REPL |
| `<Space>dw` | Hover flottant sur une variable |

## Dans les panneaux DAP UI

| Key | Action |
|-----|--------|
| `Entrée` | Déplier / replier (pointeur, struct, tableau) |
| `o` | Ouvrir la valeur dans une fenêtre |
| `e` | Éditer la valeur |
| `w` | Ajouter au panneau watches |

## Debug JS / TS

3 configs apparaissent quand `<Space>dc` dans un `.js/.ts/.tsx/.jsx` :
- **Launch Node** (current file)
- **Launch Chrome** (localhost:3000)
- **Attach** to running Node

---

# GIT

## Lazygit + Gitsigns

| Key | Action |
|-----|--------|
| `<Space>gg` | Lazygit (TUI complet) |
| `]c` / `[c` | Hunk suivant / précédent |
| `<Space>hs` / `<Space>hr` | Stage / reset hunk |
| `<Space>hp` | Preview hunk |
| `<Space>hb` | Blame ligne (full) |
| `ih` (text obj) | Sélectionne le hunk (`dih`, `vih`) |

## Diffview

| Key | Action |
|-----|--------|
| `<Space>gd` | Diff working tree vs HEAD |
| `<Space>gh` | Historique du fichier courant |
| `<Space>gH` | Historique de la branche |

---

# PLUGINS QUOTIDIENS

## Surround

| Key | Action |
|-----|--------|
| `cs"'` | Change `"hello"` → `'hello'` |
| `ds"` | Delete les `"` autour |
| `ysiw"` | Add `"..."` autour du mot |

## Flash (jump rapide)

| Key | Action |
|-----|--------|
| `s` | Tape 2 chars → jump direct |
| `S` | Flash treesitter (sélection par node) |
| `r` (operator) | Remote flash : `dr{flash}` delete à distance |

## Match (search/replace flottant custom)

| Key | Action |
|-----|--------|
| `<Space>r` | Match (mot sous curseur) |
| `<Space>R` | Match (saisie libre) |
| `Tab` (dans UI) | Bascule Search ↔ Replace |
| `Entrée` (replace) | Remplace TOUT |
| `Alt+C` / `Alt+W` / `Alt+R` | Toggle case / whole-word / regex |

---

# WEB DEV

## Live preview HTML/CSS/Markdown

| Key | Action |
|-----|--------|
| `<Space>lp` / `<Space>lP` | Start / stop |

## REST client (fichiers `.http`)

| Key | Action |
|-----|--------|
| `<Space>Rs` | Send request sous le curseur |
| `<Space>Ra` | Send all requests |
| `<Space>Rt` | Toggle vue body / headers |

## Database (vim-dadbod-ui)

| Key | Action |
|-----|--------|
| `<Space>Da` | Ajouter une connexion |
| `<Space>Du` | Toggle l'UI |

## Couleurs inline

Auto sur CSS/SCSS/HTML/JS/TS/Lua : `#ff5733`, `rgb()`, `bg-red-500` (Tailwind) → couleur en background.

---

# APPENDICES

## Compteur fonction 42 (statusline)

`Fn:N/25` quand le curseur est dans une fonction C/C++ :
- vert si <20 lignes
- jaune si 20-24
- rouge si ≥25 (norme violée)

## Toggles utiles

| Key | Action |
|-----|--------|
| `<Space>uf` | Toggle auto-format |
| `<Space>ud` | Toggle diagnostics |
| `<Space>ul` | Toggle line numbers |
| `<Space>uw` | Toggle word wrap |
| `<Space>us` | Toggle spelling |

## Sessions

| Key | Action |
|-----|--------|
| `<Space>qs` | Restore session du dossier courant |
| `<Space>ql` | Restore dernière session |

## Vim-be-good (entraînement)

`:VimBeGood` pour lancer.

Dans le menu : `dd` sur la difficulte (recommande **noob** pour commencer = 100s par exercice), puis `dd` sur le jeu. Le mode **change** est le plus utile a drill (`ci{`, `ci"`, `ci)`).
