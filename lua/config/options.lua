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
-- for C/C++/H in autocmds.lua; those filetypes use manual formatting for 42 compliance.
--
-- AI completion disabled: no Copilot/Codeium in the blink.cmp menu.
-- Consistent with anti-roulette workflow and 42 ethics for graded code.
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

-- Files (crash safety nets + persistent undo)
-- vim.opt.swapfile default = true (crash safety net). Kept enabled.
vim.opt.backup = false       -- backup files (.bak) are unnecessary
vim.opt.undofile = true      -- persistent undo between sessions

-- Disable auto-save — save explicitly with <C-s>
vim.opt.autowrite = false
vim.opt.autowriteall = false

-- Keep the same screen lines visible when splitting (nvim default is "cursor")
vim.opt.splitkeep = "screen"

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                    Float window borders                                │
-- └────────────────────────────────────────────────────────────────────────┘
-- Global winborder (nvim 0.11+) applies to ALL float windows.
vim.o.winborder = "rounded"

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Diagnostic float: non-focusable (cursor never gets stolen).          │
-- │  Hover/signature non-focusable behavior comes from noice.nvim's       │
-- │  vim.lsp.util.open_floating_preview override (see vscode-like.lua).   │
-- │  Scroll inside noice hover via <C-f>/<C-b> (see keymaps.lua).         │
-- └────────────────────────────────────────────────────────────────────────┘
vim.diagnostic.config({
  float = { focusable = false, source = "if_many" },
})
