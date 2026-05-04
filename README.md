# Neovim Config — Pedro

Config Neovim basée sur [LazyVim](https://www.lazyvim.org/) pour C/C++ (norme 42), web fullstack et usage quotidien.

> **Référence complète des keymaps** : voir [`cheatsheet.md`](./cheatsheet.md).

---

## ✨ Features signature

- **Theme** : Catppuccin Mocha (`NormalFloat` = `base`, bordures mauve cohérentes partout y compris dans le picker Snacks)
- **42 Header** : `F1` insère un header 42 (via `42-header.nvim`)
- **Pedro Banner** : `F2` insère une bannière perso, auto-update au save (scopée aux `*.c`/`*.h`/`*.cpp`/`*.hpp` uniquement)
- **Compteur fonction 42** : `Fn:N/25` dans la statusline pour les fichiers C/C++ (vert <20 / jaune 20-24 / rouge ≥25). Cache treesitter pour pas réparser à chaque redraw.
- **Debug C/C++ + JS/TS** : `nvim-dap` + `codelldb` (C/C++) + `vscode-js-debug` (Node + Chrome) avec UI complète
- **Match flottant** : search/replace avec UI flottante style VSCode (`<Space>r` / `<Space>R`), input échappé proprement, errors visibles
- **Web tooling** : live-preview HTML/CSS/MD, REST client (kulala), DB GUI (vim-dadbod), colorizer hex/rgb/Tailwind
- **Font** : Monaspace Argon Nerd Font

---

## 📦 Stack plugins

**Distribution** : LazyVim (avec extras lang clangd/typescript/tailwind/yaml/json/markdown/docker, editor neo-tree/harpoon2/aerial, dap.core)

**Plugins custom (lua/plugins/)** :

| Fichier | Plugins |
|---|---|
| `core.lua` | catppuccin, 42-header, treesitter, lualine (compteur Fn:N/25) |
| `completion.lua` | blink.cmp (snippets off, ghost-text off, min_keyword_length=3) |
| `lsp.lua` | clangd (norme 42, sans placeholders), lua_ls (callSnippet=Disable) |
| `formatting.lua` | conform.nvim (clang-format, prettierd, prettier) |
| `dap.lua` | nvim-dap, dap-ui, mason-nvim-dap, codelldb, nvim-dap-vscode-js |
| `git.lua` | gitsigns (signs custom + hunk actions sur `<Space>h*`) |
| `git-advanced.lua` | diffview.nvim |
| `web.lua` | live-preview, kulala (REST), nvim-colorizer, snacks.image |
| `db.lua` | vim-dadbod + ui + completion |
| `headers.lua` | Pedro banner (autocmd BufWritePre scopé C/C++) |
| `match.lua` | Search/replace flottant custom (~430 lignes Lua, escape proprement, errors visibles) |
| `ui-enhancements.lua` | wakatime |
| `vscode-like.lua` | nvim-surround, vim-be-good, noice |

---

## 🚀 Installation

### Prérequis

```bash
# Neovim >= 0.10 (recommandé 0.11+)
sudo dnf install neovim   # Fedora
brew install neovim       # macOS
sudo pacman -S neovim     # Arch

# Pour le debug C/C++ (UBSan) :
sudo dnf install libubsan

# Font Nerd Font (sinon les icônes n'affichent pas)
# Télécharger Monaspace Argon Nerd Font ou équivalent
```

### Clone

```bash
mv ~/.config/nvim ~/.config/nvim.backup 2>/dev/null

git clone https://github.com/ruipedro-pinheiro/nvim-config.git ~/.config/nvim
nvim   # les plugins s'installent automatiquement via Lazy
```

### Setup 42

Dans `lua/plugins/core.lua`, change le bloc `42-header.nvim` :

```lua
opts = {
  user = "TON_LOGIN",
  mail = "TON_LOGIN@student.42lausanne.ch",
},
```

Dans `lua/plugins/headers.lua`, change la bannière Pedro pour ton nom/github (ASCII art + ligne `PEDRO PINHEIRO` + `RUIPEDRO-PINHEIRO`).

---

## ⌨️ Quick start (10 keys must-know)

> Détails complets : [`cheatsheet.md`](./cheatsheet.md)

| Key | Action |
|---|---|
| `jk` ou `jj` | Sortir d'insert mode (sans bouger les doigts d'`Esc`) |
| `Ctrl+S` | Sauver |
| `<Space>e` | Explorer fichiers |
| `<Space>ff` | Find files (fuzzy) |
| `<Space>fg` | Live grep |
| `<Space>gg` | Lazygit |
| `<Space>cf` | Format manuel |
| `gd` / `K` / `<Space>ca` | LSP : go to def / hover / code action |
| `F9` / `F10` / `F11` / `F12` | Debug : breakpoint / step over / into / out |
| `<Space>r` | Search & replace (Match flottant) |

> **F-keys 42 build/make** : retirées (utilise le terminal flottant `Ctrl+/` pour `make`, `make debug`, etc.).

---

## 📁 Structure

```
~/.config/nvim/
├── init.lua                # Point d'entrée
├── lazyvim.json            # Extras LazyVim activés
├── cheatsheet.md           # Référence keymaps complète
├── README.md               # Ce fichier
├── stylua.toml             # Config stylua
├── commit-template.txt     # Template git commit (à wirer manuellement)
├── lua/
│   ├── config/
│   │   ├── autocmds.lua    # C indent, trim whitespace, picker floats, dap-ui clean
│   │   ├── keymaps.lua     # Escape (jk/jj), clipboard, navigation centrée, terminal
│   │   ├── lazy.lua        # Bootstrap lazy.nvim (defaults.lazy=true)
│   │   └── options.lua     # Tabs, scrolloff, undofile, signcolumn=auto, ...
│   └── plugins/            # Voir tableau "Stack plugins" plus haut
└── .gitignore
```

---

## 📝 Choix de design (philosophie anti-roulettes)

- **Format auto au save** : ON globalement (web, JS/TS, CSS, MD, JSON), **OFF par filetype pour C/C++/H** — manual format avec `<Space>cf` (norme 42 + discipline).
- **AI completion désactivée** (`vim.g.ai_cmp = false`) — éthique 42 sur le code gradué + posture générale.
- **Snippets désactivés** dans blink.cmp — pas d'expansion automatique de `for` / `if` / etc.
- **Auto-brackets désactivés** — tu fermes tes `}` toi-même.
- **Ghost text désactivé** — pas de prévisualisation grise inline.
- **clangd sans placeholders** ni auto-`#include` — anti-roulettes.
- **`min_keyword_length = 3`** sur LSP/buffer — l'autocomplete pop seulement après 3 chars (réduit le bruit).
- **Compteur Fn:N/25** : pas seulement pour 42, c'est de la discipline générale (norme stricte de code).

## 🔧 Customisation rapide

- Ajouter un keymap : `lua/config/keymaps.lua`
- Ajouter une option : `lua/config/options.lua`
- Activer un extra LazyVim : ajouter dans `lazyvim.json` puis `:Lazy sync`
- Ajouter un plugin : nouveau fichier dans `lua/plugins/`

---

## 🧪 Test sur autre machine

Config testée sur Fedora 43. Devrait marcher sur :
- Fedora / Ubuntu / Arch (avec adaptation des `dnf`/`apt`/`pacman`)
- macOS (brew install neovim + Nerd Font)
- Windows : non testé

Si Neovim ≥ 0.10 et une Nerd Font installée, ça devrait charger.
