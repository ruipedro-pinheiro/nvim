-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║              Match — Search/Replace flottant (style VSCode)              ║
-- ║                                                                          ║
-- ║  Adapté du plugin ankushbhagats/match.nvim (commit 53bfa67), sous       ║
-- ║  licence MIT. Code presque identique à l'original, ajout local des 3    ║
-- ║  toggles VSCode : case-sensitive (Aa), whole-word (ab), regex (.*).     ║
-- ║                                                                          ║
-- ║  Position : top-right (anchor "NE", col = vim.o.columns).               ║
-- ║                                                                          ║
-- ║  COMMANDES                                                               ║
-- ║    :Match [texte]   Ouvre l'UI avec [texte] pré-rempli                  ║
-- ║    :MatchWord       Ouvre avec le mot sous le curseur                   ║
-- ║    :MatchLine       Ouvre avec la ligne courante                        ║
-- ║                                                                          ║
-- ║  DANS L'UI                                                               ║
-- ║    <Tab>            Bascule Search ↔ Replace                            ║
-- ║    <Esc> / <C-q>    Ferme                                               ║
-- ║                                                                          ║
-- ║  Mode SEARCH                                                             ║
-- ║    <CR>             Passe au champ Replace                              ║
-- ║    <Up>             Match précédent                                     ║
-- ║    <Down>           Match suivant                                       ║
-- ║                                                                          ║
-- ║  Mode REPLACE                                                            ║
-- ║    <CR>             Remplace TOUT                                       ║
-- ║    <Up>             Remplace le match précédent                         ║
-- ║    <Down>           Remplace le match suivant                           ║
-- ║    <C-u> / <C-r>    Undo / Redo (annule un replace)                     ║
-- ║                                                                          ║
-- ║  TOGGLES (n'importe où dans l'UI, mode insert ou normal)                ║
-- ║    <A-c>            Case-sensitive (Aa)                                 ║
-- ║    <A-w>            Whole-word (ab)                                     ║
-- ║    <A-r>            Regex (.*)                                          ║
-- ║                                                                          ║
-- ║  Pour ajouter un keymap, dans lua/config/keymaps.lua :                  ║
-- ║    map("n", "<leader>r", "<cmd>MatchWord<cr>", { desc = "Match" })      ║
-- ║  (évite <leader>sm, déjà pris par Snacks pour les marks)                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local config = {
  prefix = "",
  style = "minimal",
  border = "rounded",
  border_hl = "FloatBorder",
}

-- État local : toggles + références aux fenêtres
local toggles = { case_sensitive = false, whole_word = false, regex = false }
local wins = {}
local searchText = ""    -- pattern Vim final (avec modifiers \c \C \< \> et escapes)
local rawSearch = ""     -- texte brut tapé par l'utilisateur (pour reconstruire au toggle)
local replaceText = ""
local replaceCount = 0
local historyCount = 0

local ns = vim.api.nvim_create_namespace("match_local")

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Construction du pattern Vim selon les toggles                          │
-- │                                                                          │
-- │  - regex OFF → on échappe les metachars de l'input                      │
-- │  - whole_word ON → on entoure de \< \> (bordures de mot)                │
-- │  - case_sensitive → \C (sensitive) ou \c (insensitive)                  │
-- └────────────────────────────────────────────────────────────────────────┘
local function build_pattern(text)
  if not text or text == "" then
    return ""
  end
  local body = toggles.regex and text or vim.fn.escape(text, [[\/.*$^~[]])
  if toggles.whole_word then
    body = [[\<]] .. body .. [[\>]]
  end
  local case = toggles.case_sensitive and [[\C]] or [[\c]]
  return case .. body
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Crée une fenêtre flottante (Search ou Replace) en haut à droite        │
-- └────────────────────────────────────────────────────────────────────────┘
local function float(title, row, parent)
  local width = 36
  local height = 1
  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    anchor = "NE",
    title = title,
    width = width,
    height = height,
    row = row,
    col = vim.o.columns,
    relative = "editor",
    style = config.style,
    border = config.border,
  })

  vim.wo[win].winhl = string.format(
    "NormalFloat:Normal,FloatBorder:%s,Search:None,IncSearch:None,CurSearch:None",
    config.border_hl
  )
  vim.bo[buf].buftype = "prompt"
  vim.bo[buf].filetype = "match"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.fn.prompt_setprompt(buf, config.prefix)

  wins[string.lower(title)] = { win = win, buf = buf, row = row, parent = parent }
  return win, buf
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Adaptation du float aux changements de taille de l'éditeur             │
-- └────────────────────────────────────────────────────────────────────────┘
vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("MatchLocalResize", { clear = true }),
  callback = function()
    for _, item in pairs(wins) do
      if vim.api.nvim_win_is_valid(item.win) then
        vim.api.nvim_win_set_config(item.win, {
          relative = "editor",
          col = vim.o.columns,
          row = item.row,
        })
      end
    end
  end,
})

local function close()
  for _, item in pairs(wins) do
    if vim.api.nvim_win_is_valid(item.win) then
      vim.api.nvim_win_close(item.win, true)
    end
  end
  wins = {}
end

local function switch()
  local cur = vim.api.nvim_get_current_win()
  for _, item in pairs(wins) do
    if vim.api.nvim_win_is_valid(item.win) and cur ~= item.win then
      vim.api.nvim_set_current_win(item.win)
    end
  end
end

local function set_win(winid)
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_current_win(winid)
  end
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Compteur [N/M] + état des toggles, affichés dans la barre Search      │
-- │  via virt_text aligné à droite                                          │
-- └────────────────────────────────────────────────────────────────────────┘
local function searchcount(parent, win, buf)
  set_win(parent)
  local sc = vim.fn.searchcount({ maxcount = 0 })
  set_win(win)

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local virt = {
    { string.format("[%d/%d] ", sc.current or 0, sc.total or 0), "Label" },
    { " Aa ", toggles.case_sensitive and "DiagnosticOk" or "Comment" },
    { " ab ", toggles.whole_word and "DiagnosticOk" or "Comment" },
    { " .* ", toggles.regex and "DiagnosticOk" or "Comment" },
  }
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    virt_text = virt,
    virt_text_pos = "right_align",
  })
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Callback à chaque keystroke dans le champ Search                      │
-- └────────────────────────────────────────────────────────────────────────┘
local function search(text, parent, win, buf)
  rawSearch = text or ""
  if rawSearch == "" then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.opt.hlsearch = false
    searchText = ""
    return
  end

  searchText = build_pattern(rawSearch)
  vim.opt.hlsearch = true
  vim.fn.setreg("/", searchText)

  set_win(parent)
  vim.fn.cursor(1, 1)
  pcall(vim.fn.search, searchText, "W")
  searchcount(parent, win, buf)
  set_win(win)
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Re-applique le pattern courant après un toggle (sans bouger le curseur)│
-- └────────────────────────────────────────────────────────────────────────┘
local function reapply()
  if not wins.search or not vim.api.nvim_win_is_valid(wins.search.win) then
    return
  end
  if rawSearch == "" then
    -- même si pas de pattern, on rafraîchit l'affichage des toggles
    searchcount(wins.search.parent, wins.search.win, wins.search.buf)
    return
  end
  searchText = build_pattern(rawSearch)
  vim.fn.setreg("/", searchText)
  searchcount(wins.search.parent, wins.search.win, wins.search.buf)
end

local function toggle(key)
  toggles[key] = not toggles[key]
  reapply()
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Replace All — :%s/pattern/replace/g                                    │
-- └────────────────────────────────────────────────────────────────────────┘
local function replace(parent, win)
  if searchText == "" then
    return vim.notify("Match : champ search vide", vim.log.levels.WARN)
  end
  set_win(parent)
  if (vim.fn.searchcount().current or 0) < 1 then
    set_win(win)
    return vim.notify("Match : pattern introuvable : " .. rawSearch, vim.log.levels.ERROR)
  end
  vim.opt.hlsearch = false
  local repl = vim.fn.escape(replaceText, [[/]])
  pcall(vim.cmd, string.format("silent! %%s/%s/%s/g", searchText, repl))
  close()
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Navigation : n / N natifs de Vim depuis la fenêtre source              │
-- └────────────────────────────────────────────────────────────────────────┘
local function jump(key, parent, win, buf)
  if not vim.api.nvim_win_is_valid(parent) or searchText == "" then
    return
  end
  set_win(parent)
  vim.cmd("silent! normal! " .. key)
  searchcount(parent, win, buf)
  set_win(win)
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Replace one + jump : utilise cgn (change next visual match)            │
-- └────────────────────────────────────────────────────────────────────────┘
local function replaceJump(key, parent)
  local sw, sb = wins.search.win, wins.search.buf
  local rw = wins.replace.win
  if not vim.api.nvim_win_is_valid(parent) or searchText == "" then
    return
  end
  set_win(parent)
  vim.cmd('silent! normal! "_cg' .. key .. replaceText .. "\27")
  vim.cmd("silent! normal! " .. key)
  searchcount(parent, sw, sb)
  set_win(rw)
  replaceCount = replaceCount + 1
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Undo / Redo natifs depuis la fenêtre source                            │
-- └────────────────────────────────────────────────────────────────────────┘
local function history(key, parent, win)
  key = vim.api.nvim_replace_termcodes(key, true, false, true)
  local nextCount = key == "u" and historyCount + 1 or historyCount - 1
  if nextCount > replaceCount or nextCount < 0 then
    return
  end
  historyCount = nextCount
  set_win(parent)
  vim.cmd("silent! normal! " .. key)
  if wins.search and vim.api.nvim_win_is_valid(wins.search.win) then
    searchcount(parent, wins.search.win, wins.search.buf)
  end
  set_win(win)
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Force le mode insert quand on bascule sur un buffer du float           │
-- └────────────────────────────────────────────────────────────────────────┘
vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("MatchLocalEnter", { clear = true }),
  callback = function()
    for _, item in pairs(wins) do
      if vim.api.nvim_get_current_buf() == item.buf then
        vim.cmd("startinsert")
      end
    end
  end,
})

local function onChange(parent, win, buf, callback)
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
        local prefix = vim.fn.prompt_getprompt(buf)
        local text = line:sub(#prefix + 1)
        callback(text, parent, win, buf)
      end)
    end,
  })
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Point d'entrée : ouvre les 2 floats et installe les keymaps            │
-- └────────────────────────────────────────────────────────────────────────┘
local function open(args)
  args = args or ""
  local parent = vim.api.nvim_get_current_win()

  toggles.case_sensitive = false
  toggles.whole_word = false
  toggles.regex = false
  searchText = ""
  rawSearch = ""
  replaceText = ""
  replaceCount = 0
  historyCount = 0

  local searchWin, searchBuf = float("Search", 1, parent)
  local replaceWin, replaceBuf = float("Replace", 4, parent)

  onChange(parent, searchWin, searchBuf, search)
  onChange(parent, replaceWin, replaceBuf, function(text)
    replaceText = text or ""
  end)

  set_win(searchWin)
  vim.api.nvim_buf_set_lines(searchBuf, 0, -1, false, { args })
  vim.api.nvim_win_set_cursor(searchWin, { 1, #args })

  for name, item in pairs(wins) do
    local opts = { buffer = item.buf }
    vim.keymap.set({ "n", "i" }, "<Esc>", close, opts)
    vim.keymap.set({ "n", "i" }, "<C-q>", close, opts)
    vim.keymap.set({ "n", "i" }, "<Tab>", switch, opts)
    vim.keymap.set({ "n", "i" }, "<A-c>", function()
      toggle("case_sensitive")
    end, opts)
    vim.keymap.set({ "n", "i" }, "<A-w>", function()
      toggle("whole_word")
    end, opts)
    vim.keymap.set({ "n", "i" }, "<A-r>", function()
      toggle("regex")
    end, opts)

    if name == "search" then
      vim.keymap.set({ "n", "i" }, "<C-r>", function() end, opts)
      vim.keymap.set({ "n", "i" }, "<CR>", switch, opts)
      vim.keymap.set({ "n", "i" }, "<Up>", function()
        jump("N", parent, item.win, item.buf)
      end, opts)
      vim.keymap.set({ "n", "i" }, "<Down>", function()
        jump("n", parent, item.win, item.buf)
      end, opts)
    elseif name == "replace" then
      vim.keymap.set({ "n", "i" }, "<CR>", function()
        replace(parent, item.win)
      end, opts)
      vim.keymap.set({ "n", "i" }, "<Up>", function()
        replaceJump("N", parent)
      end, opts)
      vim.keymap.set({ "n", "i" }, "<Down>", function()
        replaceJump("n", parent)
      end, opts)
      vim.keymap.set({ "n", "i" }, "<C-u>", function()
        history("u", parent, item.win)
      end, opts)
      vim.keymap.set({ "n", "i" }, "<C-r>", function()
        history("<C-r>", parent, item.win)
      end, opts)
    end
  end
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Spec lazy.nvim : plugin virtual (rien à télécharger)                   │
-- └────────────────────────────────────────────────────────────────────────┘
return {
  -- Override : enlève le default <leader>sm de Snacks picker (ouvre Marks)
  -- pour qu'on puisse l'utiliser pour Match.
  {
    "folke/snacks.nvim",
    keys = function(_, keys)
      return vim.tbl_filter(function(k)
        return k[1] ~= "<leader>sm"
      end, keys)
    end,
  },

  {
    "match-local",
    virtual = true,
    lazy = false,
    keys = {
      { "<leader>sm", "<cmd>MatchWord<cr>", desc = "Match (search/replace)" },
      { "<leader>sM", ":Match ", desc = "Match (saisie libre)" },
    },
    config = function()
      vim.api.nvim_create_user_command("Match", function(opts)
        open(opts.args)
      end, { nargs = "*", desc = "Search and Replace flottant" })

      vim.api.nvim_create_user_command("MatchWord", function()
        local word = vim.fn.expand("<cword>")
        open(word)
      end, { nargs = 0, desc = "Match avec le mot sous le curseur" })

      vim.api.nvim_create_user_command("MatchLine", function()
        local line = vim.fn.getline(".")
        open(line)
      end, { nargs = 0, range = true, desc = "Match avec la ligne courante" })
    end,
  },
}
