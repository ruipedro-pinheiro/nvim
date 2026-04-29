# Neovim Config

Config Neovim basée sur [LazyVim](https://www.lazyvim.org/) pour C/C++, web et usage quotidien, avec headers 42 + bannière perso et search/replace flottant.

## ✨ Features

- **Theme** : Catppuccin Mocha
- **42 Header** : Header automatique avec `<F1>`
- **Pedro Header** : Bannière perso avec `<F2>` (auto-update au save)
- **Match** : Search & Replace flottant style VSCode (`<Space>sm`)
- **Compteur 42** : `Fn:N/25` dans la statusline pour les fonctions C/C++ (vert/jaune/rouge)
- **Font** : Monaspace Argon Nerd Font

## 📦 Plugins Principaux

- [LazyVim](https://github.com/LazyVim/LazyVim) — Distribution Neovim
- [42-header.nvim](https://github.com/Diogo-ss/42-header.nvim) — Headers 42
- [blink.cmp](https://github.com/saghen/blink.cmp) — Complétion LSP (snippets désactivés)
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) — Explorateur latéral
- [catppuccin](https://github.com/catppuccin/nvim) — Theme
- [gitsigns](https://github.com/lewis6991/gitsigns.nvim) — Hunks git in-buffer
- [nvim-surround](https://github.com/kylechui/nvim-surround) — `cs/ds/ys`
- [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) — Entraînement vim
- [wakatime](https://github.com/wakatime/vim-wakatime) — Tracking temps de code

## 🚀 Installation

### Prérequis

```bash
# Neovim >= 0.10
brew install neovim       # macOS
sudo dnf install neovim   # Fedora
sudo pacman -S neovim     # Arch
```

### Installation de la config

```bash
# Backup de l'ancienne config si elle existe
mv ~/.config/nvim ~/.config/nvim.backup

# Clone la config
git clone https://github.com/TON_USERNAME/nvim-config.git ~/.config/nvim

# Lance Neovim (les plugins s'installent automatiquement via Lazy)
nvim
```

### Setup spécifique 42

1. Vérifier que Neovim ≥ 0.10 est installé
2. Ajuster `user` et `mail` du header 42 (voir ci-dessous)
3. L'autoformat est désactivé par défaut (format manuel avec `<Space>cf`)

## ⚙️ Configuration Header 42

Dans `lua/plugins/core.lua`, modifie ton login et mail :

```lua
{
  "Diogo-ss/42-header.nvim",
  opts = {
    user = "TON_LOGIN",
    mail = "TON_LOGIN@student.42lausanne.ch",
  },
},
```

## ⌨️ Keymaps Essentiels

> Liste exhaustive : voir `cheatsheet.md`. Leader = `<Space>`.

### Général
- `<F1>` — Insérer header 42
- `<F2>` — Insérer header Pedro
- `<F5>` — Compile C (`cc -Wall -Werror -Wextra`, async)
- `<F7>` / `<F8>` — `make` / `make re` (async)
- `<Space>cf` — Format manuel
- `jk` ou `jj` — Escape (insert mode)

### Navigation
- `<Space>e` — Explorer de fichiers (neo-tree)
- `<Space>ff` — Find files
- `<Space>fg` — Live grep
- `<Space>fr` — Recent files

### Search & Replace
- `<Space>sm` — Match (mot sous curseur)
- `<Space>sM` — Match (saisie libre)

### LSP
- `gd` — Go to definition
- `gr` — References
- `K` — Hover doc
- `<Space>ca` / `<Space>cr` — Code action / Rename

### Git
- `<Space>gg` — Lazygit
- `]c` / `[c` — Hunk suivant / précédent
- `<Space>hs` — Stage hunk

## 📁 Structure

```
~/.config/nvim/
├── init.lua                     # Point d'entrée
├── lazyvim.json                 # Extras LazyVim activés
├── cheatsheet.md                # Cheatsheet keymaps complet
├── lua/
│   ├── config/
│   │   ├── autocmds.lua         # C indent, trim whitespace, diag float
│   │   ├── keymaps.lua          # Keymaps custom (clipboard, F-keys, terminal)
│   │   ├── lazy.lua             # Bootstrap lazy.nvim
│   │   └── options.lua          # Options Vim (tabs 4, scrolloff 8, etc.)
│   └── plugins/
│       ├── core.lua             # Catppuccin + 42 header + treesitter + lualine
│       ├── completion.lua       # blink.cmp (snippets off)
│       ├── formatting.lua       # conform.nvim (clang-format, prettier)
│       ├── git.lua              # gitsigns + hunk keymaps
│       ├── headers.lua          # Bannière Pedro (auto-update au save)
│       ├── lsp.lua              # clangd (norm 42), lua_ls
│       ├── match.lua            # Search & Replace flottant
│       ├── ui-enhancements.lua  # Wakatime
│       └── vscode-like.lua      # Surround, vim-be-good, noice
└── .gitignore
```

## 🎨 Theme

Le theme Catppuccin Mocha :
- Bordures de toutes les fenêtres flottantes en mauve (`mauve`)
- Fond `mantle` pour les floats
- Transparent désactivé par défaut

## 📝 Notes

- Format automatique à la sauvegarde **désactivé** (`vim.g.autoformat = false`)
- AI completion **désactivée** (`vim.g.ai_cmp = false`) — éthique 42
- Tabs en C/C++ : tabs réels (pas d'expandtab), 4 colonnes, `colorcolumn 80`
- Le compteur de lignes de fonction (`Fn:N/25`) ne s'affiche que dans les fichiers C/C++
- LSP `clangd` configuré sans snippets ni placeholders d'arguments (cohérent avec `<C-Space>` simple)
- Config testée sur Fedora et macOS

## 🔧 Customisation rapide

- Ajouter un keymap : `lua/config/keymaps.lua`
- Ajouter une option : `lua/config/options.lua`
- Activer un extra LazyVim : ajouter dans `lazyvim.json` puis `:Lazy sync`
- Ajouter un plugin : nouveau fichier dans `lua/plugins/`
