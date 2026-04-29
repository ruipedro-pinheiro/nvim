# Nvim Cheatsheet — Pedro (LazyVim + Custom)

> Ouvre dans nvim : `nvim ~/.config/nvim/cheatsheet.md`
> Leader = `<Space>`

---

## VIM FONDAMENTAUX (a drill avec vim-be-good)

### Operateurs (combiner avec motions/text objects)

| Key | Action |
|-----|--------|
| `d` | Delete |
| `c` | Change (delete + insert mode) |
| `y` | Yank (copie dans registre vim) |
| `v` | Visual select |
| `>` / `<` | Indent / Dedent |
| `gu` / `gU` | Lowercase / Uppercase |

### Motions (ou aller)

| Key | Action |
|-----|--------|
| `w` / `b` | Mot suivant / precedent |
| `e` | Fin du mot |
| `W` / `B` / `E` | Pareil mais WORD (ignore ponctuation) |
| `0` / `$` | Debut / fin de ligne |
| `^` | Premier char non-blanc |
| `f{c}` / `F{c}` | Jump au char `c` (avant/arriere) |
| `t{c}` / `T{c}` | Jump juste avant char `c` |
| `;` / `,` | Repeter f/t suivant / precedent |
| `gg` / `G` | Debut / fin du fichier |
| `{` / `}` | Paragraphe precedent / suivant |
| `%` | Parenthese/bracket correspondante |
| `H` / `M` / `L` | Haut / milieu / bas de l'ecran |

### Text Objects (le vrai power move)

Prefixe `i` = inside, `a` = around (inclut delimiteurs)

| Key | Action | Exemple |
|-----|--------|---------|
| `iw` / `aw` | Mot | `diw` = delete mot sous curseur |
| `i"` / `a"` | Entre guillemets | `ci"` = change contenu entre `"` |
| `i'` / `a'` | Entre apostrophes | `di'` = delete entre `'` |
| `i)` / `a)` | Entre parentheses | `ci)` = change contenu entre `()` |
| `i]` / `a]` | Entre crochets | `da]` = delete `[]` inclus |
| `i}` / `a}` | Entre accolades | `ci}` = change dans `{}` |
| `it` / `at` | Tag HTML/XML | `dit` = delete entre tags |
| `ip` / `ap` | Paragraphe | `dap` = delete paragraphe |
| `is` / `as` | Phrase (sentence) | `cis` = change phrase |

### Combos essentiels

| Combo | Action |
|-------|--------|
| `ciw` | Change le mot sous le curseur |
| `ci"` | Change le contenu entre `"` |
| `di)` | Delete le contenu entre `()` |
| `da}` | Delete les `{}` et leur contenu |
| `yiw` | Yank le mot |
| `vi)` | Selectionne visuellement entre `()` |
| `ct;` | Change jusqu'au `;` |
| `df,` | Delete jusqu'a `,` inclus |
| `.` | **Repeter** la derniere action |
| `u` / `<C-r>` | Undo / Redo |

---

## TES KEYMAPS CUSTOM

### General

| Key | Action |
|-----|--------|
| `jk` / `jj` | Escape (insert mode) |
| `<C-s>` | Save (LazyVim default) |
| `<Space>q` | Quit |
| `<Space>Q` | Force quit all |

### Clipboard (separe du registre vim)

| Key | Action |
|-----|--------|
| `<Space>y` | Yank vers clipboard systeme |
| `<Space>Y` | Yank ligne vers clipboard |
| `<Space>p` | Paste depuis clipboard |
| `<Space>P` | Paste avant depuis clipboard |
| `p` (visual) | Paste sans ecraser le registre |
| `dd` / `d{motion}` | Delete → registre vim (PAS clipboard) |

### Navigation centree

| Key | Action |
|-----|--------|
| `<C-d>` | Scroll demi-page bas (centre) |
| `<C-u>` | Scroll demi-page haut (centre) |
| `n` / `N` | Recherche suivant/precedent (centre) |

### Headers, build et format

| Key | Action |
|-----|--------|
| `F1` | Inserer le header 42 |
| `F2` | Inserer la banniere Pedro (auto-update au save) |
| `<Space>cf` | Format manuel (clang-format pour C) |
| `F5` | Compile fichier C (`cc -Wall -Werror -Wextra`, async) |
| `F6` | Run le binaire compile |
| `F7` | `make` (async) |
| `F8` | `make re` (async) |

### Terminal

| Key | Action |
|-----|--------|
| `<Space>ft` | Terminal flottant (root du projet) |
| `<Space>fT` | Terminal flottant (cwd) |
| `<Space>tb` | Terminal split bas (root) |
| `<Space>tB` | Terminal split bas (cwd) |
| `<C-/>` | Terminal flottant (root) — raccourci |
| `<Esc><Esc>` | Quitter mode terminal |

---

## MATCH (search & replace flottant — `lua/plugins/match.lua`)

### Ouvrir

| Key | Action |
|-----|--------|
| `<Space>sm` | Match avec mot sous curseur |
| `<Space>sM` | Match avec saisie libre |
| `:Match foo` | Ouvrir avec `foo` pre-rempli |
| `:MatchLine` | Ouvrir avec la ligne courante |

### Dans l'UI (en haut a droite)

| Key | Action |
|-----|--------|
| `<Tab>` | Bascule Search ↔ Replace |
| `<Esc>` / `<C-q>` | Fermer |
| `<CR>` (search) | Passer au champ Replace |
| `<CR>` (replace) | Remplacer TOUT |
| `<Up>` (search) | Match precedent |
| `<Down>` (search) | Match suivant |
| `<Up>` (replace) | Remplacer le precedent |
| `<Down>` (replace) | Remplacer le suivant |
| `<C-u>` / `<C-r>` (replace) | Undo / Redo |

### Toggles VSCode-like

| Key | Action |
|-----|--------|
| `<A-c>` | Case-sensitive (Aa) |
| `<A-w>` | Whole-word (ab) |
| `<A-r>` | Regex (.*) |

---

## HARPOON (navigation rapide entre fichiers)

| Key | Action |
|-----|--------|
| `<Space>H` | Ajouter fichier a la liste |
| `<Space>h` | Menu Harpoon (voir/reordonner) |
| `<Space>1..9` | Switch vers fichier 1..9 |

**Workflow** : ouvre tes 3-4 fichiers principaux, `<Space>H` chacun, puis `<Space>1/2/3` pour switcher instantanement.

---

## LAZYVIM DEFAULTS (les plus utiles)

> Picker = Snacks (pas Telescope). Meme keymaps mais UI plus rapide.

### Fichiers & Navigation

| Key | Action |
|-----|--------|
| `<Space>e` | Explorateur (neo-tree) |
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep (chercher du texte) |
| `<Space>fb` | Buffers ouverts |
| `<Space>fr` | Fichiers recents |
| `<Space>/` | Grep dans le projet |
| `<Space>,` | Switcher de buffer |
| `<Space>:` | Historique commandes |

### Fenetres

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Naviguer entre fenetres |
| `<C-Up/Down/Left/Right>` | Resize fenetre |
| `<Space>-` | Split horizontal |
| `<Space>\|` | Split vertical |
| `<Space>wd` | Fermer la fenetre |

### LSP (quand un serveur est attache)

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
| `]d` / `[d` | Diagnostic suivant/precedent |

### Git (LazyVim + lazygit + gitsigns)

| Key | Action |
|-----|--------|
| `<Space>gg` | Lazygit (TUI git complet) |
| `<Space>gf` | Git files |
| `<Space>gc` | Git commits |
| `<Space>gs` | Git status |

### Gitsigns (hunks dans le fichier courant)

| Key | Action |
|-----|--------|
| `]c` / `[c` | Hunk suivant / precedent |
| `<Space>hs` | Stage hunk |
| `<Space>hr` | Reset hunk |
| `<Space>hS` | Stage tout le buffer |
| `<Space>hR` | Reset tout le buffer |
| `<Space>hu` | Undo stage hunk |
| `<Space>hp` | Preview hunk |
| `<Space>hb` | Blame ligne (full) |
| `<Space>hd` | Diff this |
| `<Space>hD` | Diff this avec parent |
| `ih` (text obj) | Selectionne le hunk (`dih`, `vih`, etc.) |

### Toggles

| Key | Action |
|-----|--------|
| `<Space>uf` | Toggle auto-format |
| `<Space>us` | Toggle spelling |
| `<Space>uw` | Toggle word wrap |
| `<Space>ul` | Toggle line numbers |
| `<Space>ud` | Toggle diagnostics |

---

## PLUGINS

### Flash (jump ultra-rapide)

| Key | Action |
|-----|--------|
| `s` | Flash jump — tape 2 chars, jump direct |
| `S` | Flash treesitter — select par node |
| `r` (operator) | Remote flash (apres `d`/`y`/`c`) |

### Surround

| Key | Action | Exemple |
|-----|--------|---------|
| `cs{old}{new}` | Change surrounding | `cs"'` : `"hello"` → `'hello'` |
| `ds{char}` | Delete surrounding | `ds"` : `"hello"` → `hello` |
| `ysiw{char}` | Add surrounding | `ysiw"` : `hello` → `"hello"` |
| `ysa{obj}{char}` | Add around obj | `ysa)"` : `(foo)` → `"(foo)"` |

### Session (persistence)

| Key | Action |
|-----|--------|
| `<Space>qs` | Restore session (dossier courant) |
| `<Space>ql` | Restore derniere session |
| `<Space>qd` | Don't save current session |

### Noice (cmdline et notifications)

La cmdline `:` apparait flottante au centre. Search `/`/`?` aussi.
Pas de keymap specifique — c'est juste l'UI.

### Lualine — compteur de lignes de fonction (fichiers C/C++ uniquement)

Affiche `Fn:N/25` dans la statusline quand tu es dans une fonction :
- vert si <20 lignes
- jaune si 20-24
- rouge si ≥25 (norme 42 violee)

---

## VIM-BE-GOOD (entrainement)

Lance dans nvim : `:VimBeGood`

Modes disponibles :
- **hjkl** — navigation basique
- **word** — motions w/b/e
- **delete** — d + motions
- **change** — c + motions (le plus utile a drill)

---

## ORDRE D'APPRENTISSAGE RECOMMANDE

1. **Semaine 1** : `hjkl`, `w/b/e`, `dd`, `cc`, `ciw`, `ci"`, `di)`, `.`
2. **Semaine 2** : `f/t` + `;`, text objects (`iw`, `i"`, `i)`, `i}`), `<C-d>/<C-u>`
3. **Semaine 3** : Flash (`s`), Harpoon (`<Space>H`, `<Space>1..9`), Snacks picker (`<Space>ff/fg`)
4. **Semaine 4** : Surround (`cs/ds/ys`), LSP (`gd`, `K`, `<Space>ca/cr`), macros (`q`)
5. **Ongoing** : `:VimBeGood` chaque jour 10 min jusqu'a ce que ce soit instinctif
