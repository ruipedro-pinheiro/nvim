-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
-- Only set options that DIFFER from LazyVim defaults.
-- LazyVim already sets: relativenumber, number, ignorecase, smartcase,
-- termguicolors, signcolumn, cursorline, splitright, splitbelow,
-- undofile, sidescrolloff, expandtab, clipboard, etc.

-- Tabs (global default: 4 spaces — C/H override to real tabs in autocmds.lua)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- LazyVim behavior
-- Autoformat-on-save is ON globally (LazyVim default), then disabled per-buffer
-- for C/C++/H in autocmds.lua — manual format only there (norme 42 + anti-roulettes).
--
-- AI completion désactivée : pas de Copilot/Codeium dans le menu de blink.cmp.
-- Cohérent avec la philosophie anti-roulettes + éthique 42 sur le code gradué.
vim.g.ai_cmp = false

-- Search
vim.opt.hlsearch = true

-- Tabline only shown when 2+ tabs (avoid empty top row with single buffer)
vim.opt.showtabline = 1

-- Signcolumn auto: column hidden when no signs to show (saves left space)
vim.opt.signcolumn = "auto"

-- UI
vim.opt.scrolloff = 8
vim.opt.pumheight = 12

-- Files (filets de sécurité contre crash + persistence undo)
-- vim.opt.swapfile par défaut = true (filet contre crash). On garde.
vim.opt.backup = false       -- pas besoin de backup files (.bak)
vim.opt.undofile = true      -- undo persistent entre sessions

-- Disable auto-save — Pedro saves explicitly with <C-s>
vim.opt.autowrite = false
vim.opt.autowriteall = false

-- Splits open in the natural direction
vim.opt.splitkeep = "screen"

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                    Float window borders                                │
-- └────────────────────────────────────────────────────────────────────────┘
if vim.fn.has("nvim-0.11") == 1 then
  -- Neovim 0.11+: global winborder applies to ALL float windows
  vim.o.winborder = "rounded"
else
  -- Neovim 0.10: configure borders manually per-feature
  vim.diagnostic.config({
    float = { border = "rounded" },
  })
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Diagnostic float: non-focusable (cursor never gets stolen).          │
-- │  Hover/signature non-focusable behavior comes from noice.nvim's       │
-- │  vim.lsp.util.open_floating_preview override (see vscode-like.lua).   │
-- │  Scroll inside noice hover via <C-f>/<C-b> (see keymaps.lua).         │
-- └────────────────────────────────────────────────────────────────────────┘
vim.diagnostic.config({
  float = { focusable = false, source = "if_many" },
})
