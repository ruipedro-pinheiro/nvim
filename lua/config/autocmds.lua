-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- LazyVim already provides: highlight_yank, resize_splits, last_loc,
-- close_with_q, checktime, wrap_spell, auto_create_dir, etc.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                      C filetype settings                               │
-- │                                                                        │
-- │  - Tabs reels (norme 42 + anti-roulettes on autoformat)                │
-- │  - colorcolumn=80                                                      │
-- │  - autoformat OFF per-buffer : tu formates a la main avec <Space>cf    │
-- └────────────────────────────────────────────────────────────────────────┘
augroup("CIndent", { clear = true })
autocmd("FileType", {
  group = "CIndent",
  pattern = { "c", "cpp", "h" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.colorcolumn = "80"
    -- Override the global autoformat-on-save: in C/C++ on garde la main.
    vim.b.autoformat = false
  end,
})

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                      Remove trailing whitespace                        │
-- └────────────────────────────────────────────────────────────────────────┘
augroup("TrimWhitespace", { clear = true })
autocmd("BufWritePre", {
  group = "TrimWhitespace",
  pattern = { "*.c", "*.h", "*.cpp", "*.hpp" },
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Snacks picker: mirror Float* highlights to picker sub-window groups   │
-- │                                                                        │
-- │  Snacks creates SnacksPicker<Suffix>{,Border,Title} per sub-window     │
-- │  (Input/List/Preview/Box) and remaps FloatBorder -> SnacksPickerXBorder│
-- │  in the window's winhighlight. We can't `link = "FloatBorder"` because │
-- │  the winhl remap creates a circular reference (FloatBorder -> picker  │
-- │  group -> link FloatBorder -> ...) that nvim resolves to no-highlight, │
-- │  i.e. transparent. We COPY the resolved values instead.                │
-- └────────────────────────────────────────────────────────────────────────┘
local picker_suffixes = { "Input", "List", "Preview", "Box" }

local function mirror_picker_floats()
  -- Resolve to absolute values (link = false collapses the chain)
  local function resolve(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end
  local normal = resolve("NormalFloat")
  local border = resolve("FloatBorder")
  local title = resolve("FloatTitle")

  -- Force the border/title bg to the interior bg so the border zone
  -- is always solid — even for themes (e.g. shine) where FloatBorder
  -- has no bg defined and would render transparent.
  border.bg = normal.bg
  title.bg = normal.bg

  for _, suffix in ipairs(picker_suffixes) do
    local prefix = "SnacksPicker" .. suffix
    vim.api.nvim_set_hl(0, prefix, normal)
    vim.api.nvim_set_hl(0, prefix .. "Border", border)
    vim.api.nvim_set_hl(0, prefix .. "Title", title)
  end
end

augroup("PickerFloats", { clear = true })
autocmd("ColorScheme", {
  group = "PickerFloats",
  callback = mirror_picker_floats,
})
-- Apply once now for the current colorscheme (autocmd file loads at
-- VeryLazy, after the initial ColorScheme event has already fired).
mirror_picker_floats()

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │            DAP UI: hide signcolumn/numbers (no empty left strip)       │
-- └────────────────────────────────────────────────────────────────────────┘
local dapui_filetypes = {
  ["dapui_scopes"] = true,
  ["dapui_breakpoints"] = true,
  ["dapui_stacks"] = true,
  ["dapui_watches"] = true,
  ["dapui_console"] = true,
  ["dap-repl"] = true,
}

augroup("DapUiClean", { clear = true })
autocmd({ "BufWinEnter", "FileType" }, {
  group = "DapUiClean",
  callback = function(ev)
    if not dapui_filetypes[vim.bo[ev.buf].filetype] then
      return
    end
    -- Apply to all windows showing this buffer
    for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
      vim.api.nvim_win_call(win, function()
        vim.opt_local.signcolumn = "no"
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.foldcolumn = "0"
        vim.opt_local.statuscolumn = ""
      end)
    end
  end,
})

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                      Diagnostic float on cursor hold                   │
-- └────────────────────────────────────────────────────────────────────────┘
augroup("DiagnosticFloat", { clear = true })
autocmd("CursorHold", {
  group = "DiagnosticFloat",
  callback = function()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = line })) then
      return
    end
    vim.diagnostic.open_float(nil, {
      scope = "cursor",
      focusable = false,
      close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertEnter", "FocusLost" },
    })
  end,
})
