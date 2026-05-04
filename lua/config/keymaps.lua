-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- LazyVim already provides: <C-s> save, <leader>qq quit, <leader>cf format,
-- <leader>gg lazygit, <leader>ft terminal, buffer navigation, etc.

local map = vim.keymap.set

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                         General Keymaps                                │
-- └────────────────────────────────────────────────────────────────────────┘

-- Better escape
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })

-- Scroll inside noice hover/signature WITHOUT focusing it.
-- Falls back to native <C-f>/<C-b> when no noice popup is active.
map({ "n", "i", "s" }, "<C-f>", function()
  if not require("noice.lsp").scroll(4) then
    return "<C-f>"
  end
end, { silent = true, expr = true, desc = "Scroll hover down / page down" })

map({ "n", "i", "s" }, "<C-b>", function()
  if not require("noice.lsp").scroll(-4) then
    return "<C-b>"
  end
end, { silent = true, expr = true, desc = "Scroll hover up / page up" })

-- Force quit all
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit all (force)" })

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                         System Clipboard                               │
-- └────────────────────────────────────────────────────────────────────────┘

map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })
map({ "n", "v" }, "<leader>P", '"+P', { desc = "Paste before from clipboard" })

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                         Better Editing                                 │
-- └────────────────────────────────────────────────────────────────────────┘

-- Don't yank on paste in visual mode
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up centered" })
map("n", "n", "nzzzv", { desc = "Next search centered" })
map("n", "N", "Nzzzv", { desc = "Previous search centered" })

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │                         Terminal                                       │
-- └────────────────────────────────────────────────────────────────────────┘

map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

map({ "n", "t" }, "<C-/>", function()
  Snacks.terminal(nil, {
    cwd = LazyVim.root(),
    win = {
      position = "float",
      border = "rounded",
      width = 0.88,
      height = 0.82,
    },
  })
end, { desc = "Terminal Float (Root Dir)" })

-- F3-F8 : libres. Les anciens raccourcis make/compile/run ont été retirés
-- (Pedro lance ces commandes via le terminal flottant `<C-/>`).
