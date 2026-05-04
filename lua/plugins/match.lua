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
-- ║  KEYMAPS DÉFAUT (déclarés dans le plugin spec en bas de ce fichier)     ║
-- ║    <leader>r        :MatchWord (mot sous le curseur)                    ║
-- ║    <leader>R        :Match (saisie libre)                               ║
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
local original_pos = { 1, 0 }  -- position du curseur au moment de l'ouverture (pour search incrémentale "VSCode-style" qui repart de là, pas de la ligne 1)

local ns = vim.api.nvim_create_namespace("match_local")

-- Échappement de `replaceText` pour `:s/pat/rep/`.
--
-- - Toujours :
--     `/`         délimiteur du substitute → escapé en `\/`
--     newline     remplacé par `\r` (séquence vim sub = saut de ligne)
--
-- - Mode régex OFF (literal) :
--     `\`         escapé en `\\` (sinon vim sub interprète \1-\9, \&, etc.)
--     `&`         escapé en `\&` (sinon = matched text)
--     `~`         escapé en `\~` (sinon = previous replacement)
--   → résultat : le texte est inséré tel quel, peu importe son contenu.
--
-- - Mode régex ON :
--     `\` `&` `~` PAS escapés → l'utilisateur peut utiliser \1-\9, &, ~
--     comme références aux captures et matched text.
--
-- Ordre des substitutions important : `\` AVANT `/` et `& ~`
-- pour éviter de double-escaper le `\` injecté par les autres règles.
local function escape_replacement(s)
  if toggles.regex then
    return (s:gsub("/", "\\/"):gsub("\n", "\\r"))
  end
  return (s
    :gsub("\\", "\\\\")
    :gsub("/", "\\/")
    :gsub("([&~])", "\\%1")
    :gsub("\n", "\\r"))
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Construction du pattern Vim selon les toggles                          │
-- │                                                                          │
-- │  - regex OFF → on échappe les metachars de l'input                      │
-- │  - regex ON  → on garde les metachars MAIS on échappe `/` (qui sinon    │
-- │    casse `:s/pat/rep/` parce que c'est le délimiteur du substitute)     │
-- │  - whole_word ON → on entoure de \< \> (bordures de mot)                │
-- │  - case_sensitive → \C (sensitive) ou \c (insensitive)                  │
-- └────────────────────────────────────────────────────────────────────────┘
local function build_pattern(text)
  if not text or text == "" then
    return ""
  end
  local body
  if toggles.regex then
    -- Garde les metachars du user, mais escape `/` pour ne pas casser
    -- le délimiteur du `:s/pat/rep/` plus tard.
    body = (text:gsub("/", "\\/"))
  else
    -- Non-regex : on échappe tous les metachars vim, y compris `/`.
    body = vim.fn.escape(text, [[\/.*$^~[]])
  end
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
-- │                                                                        │
-- │  Recherche depuis la position d'ouverture (original_pos), pas depuis   │
-- │  la ligne 1 — comportement attendu d'une recherche incrémentale.      │
-- │                                                                        │
-- │  vim.fn.search retourne 0 si pas de match (pas de throw) ; pas besoin │
-- │  de pcall.                                                            │
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
  -- Reset à la position d'origine. cursor() clamp les valeurs hors-buffer
  -- (ex. ligne supprimée après ouverture), donc safe sans check.
  vim.fn.cursor(original_pos[1], original_pos[2] + 1)
  -- "Wc" : pas de wrap, accepte le match courant.
  vim.fn.search(searchText, "Wc")
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
-- │                                                                        │
-- │  - Replacement échappé via escape_replacement (regex-aware, gère       │
-- │    aussi les newlines littéraux).                                      │
-- │  - Erreurs vim cmd capturées et affichées (jamais silent!).            │
-- │  - Compte des matches relevé AVANT substitute (searchcount.total).    │
-- │  - Curseur restauré à original_pos après substitute (vim sub déplace  │
-- │    sinon le curseur au dernier match).                                 │
-- │  - UI fermée seulement en cas de succès.                               │
-- └────────────────────────────────────────────────────────────────────────┘
local function replace(parent, win)
  if searchText == "" then
    return vim.notify("Match : champ search vide", vim.log.levels.WARN)
  end
  set_win(parent)
  local total = vim.fn.searchcount().total or 0
  if total < 1 then
    set_win(win)
    return vim.notify("Match : pattern introuvable : " .. rawSearch, vim.log.levels.ERROR)
  end

  vim.opt.hlsearch = false
  local repl = escape_replacement(replaceText)
  local ok, err = pcall(vim.cmd, string.format("%%s/%s/%s/g", searchText, repl))
  if not ok then
    set_win(win)
    return vim.notify("Match : substitute échoué — " .. tostring(err), vim.log.levels.ERROR)
  end

  -- Restaure le curseur à la position d'ouverture (vim sub l'a déplacé au
  -- dernier match remplacé, ce qui est désorientant pour l'utilisateur).
  vim.fn.cursor(original_pos[1], original_pos[2] + 1)

  vim.notify(string.format("Match : %d remplacement(s)", total), vim.log.levels.INFO)
  close()
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Navigation : prochain (key="n") ou précédent (key="N") match.          │
-- │  Utilise vim.fn.search (API) au lieu de `silent! normal!` :            │
-- │  - Pas de silent! qui mange les erreurs.                                │
-- │  - vim.fn.search retourne 0 si rien trouvé (gérable proprement).       │
-- └────────────────────────────────────────────────────────────────────────┘
local function jump(key, parent, win, buf)
  if not vim.api.nvim_win_is_valid(parent) or searchText == "" then
    return
  end
  set_win(parent)
  local flags = (key == "n") and "W" or "Wb"
  vim.fn.search(searchText, flags)
  searchcount(parent, win, buf)
  set_win(win)
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Replace one + jump                                                     │
-- │                                                                        │
-- │  Sequence :                                                            │
-- │  1. `searchpos` (sans `n`) → curseur déplacé au début du match.        │
-- │  2. `searchpos(..., "Wcen")` → fin du match SANS bouger curseur (`n`). │
-- │  3. `nvim_buf_set_text(start, end, replaceText.split("\n"))` →         │
-- │     insertion 100% littérale, jamais ré-interprétée par normal-mode.   │
-- │  4. Curseur déplacé APRÈS la zone remplacée, pour éviter que           │
-- │     `search "W"` re-match dans le replacement (cas: "foo" → "foofoo"). │
-- │  5. `vim.fn.search` au prochain match.                                  │
-- └────────────────────────────────────────────────────────────────────────┘
local function replaceJump(key, parent)
  local sw, sb = wins.search.win, wins.search.buf
  local rw = wins.replace.win
  if not vim.api.nvim_win_is_valid(parent) or searchText == "" then
    return
  end
  set_win(parent)

  -- 1. Localise le prochain (key="n") ou précédent (key="N") match.
  local flag = (key == "n") and "W" or "Wb"
  local start_row, start_col = unpack(vim.fn.searchpos(searchText, flag))
  if start_row == 0 then
    set_win(rw)
    return vim.notify("Match : pas d'autre match", vim.log.levels.WARN)
  end

  -- 2. Fin du match SANS bouger le curseur (n = no-move, c = accept match
  --    courant, e = end position).
  local end_row, end_col = unpack(vim.fn.searchpos(searchText, "Wcen"))
  if end_row == 0 then
    set_win(rw)
    return vim.notify("Match : end-of-match introuvable (regex foireuse ?)", vim.log.levels.ERROR)
  end

  -- 3. Remplace l'intervalle [start, end+1) par replaceText, littéralement.
  --    (start_col / end_col sont 1-indexed côté searchpos ; nvim_buf_set_text
  --    attend du 0-indexed, end exclusif.)
  local replaced_lines = vim.split(replaceText, "\n", { plain = true })
  local ok, err = pcall(
    vim.api.nvim_buf_set_text,
    0,
    start_row - 1, start_col - 1,
    end_row - 1, end_col,
    replaced_lines
  )
  if not ok then
    set_win(rw)
    return vim.notify("Match : erreur replace — " .. tostring(err), vim.log.levels.ERROR)
  end

  -- 4. Position curseur direction-aware pour éviter re-match dans le replacement.
  --    Forward (n): cursor APRÈS le replacement, search "W" trouve le suivant.
  --    Backward (N): cursor AU début du replacement, search "Wb" cherche
  --    strictement avant → saute par-dessus le replacement (plus de re-match).
  local last_line = replaced_lines[#replaced_lines]
  if key == "n" then
    if #replaced_lines == 1 then
      vim.fn.cursor(start_row, start_col + #last_line)
    else
      vim.fn.cursor(start_row + #replaced_lines - 1, #last_line + 1)
    end
  else
    vim.fn.cursor(start_row, start_col)
  end

  -- 5. Jump dans le sens demandé (W ou Wb selon key).
  vim.fn.search(searchText, flag)
  searchcount(parent, sw, sb)
  set_win(rw)

  -- Bug 2 fix: si on faisait des undos avant ce nouveau replace, l'undo tree
  -- est branché → les redos passés sont enterrés. Resync compteurs pour pas
  -- que <C-u> remonte au-delà de la session Match dans le travail antérieur.
  if historyCount > 0 then
    replaceCount = replaceCount - historyCount + 1
    historyCount = 0
  else
    replaceCount = replaceCount + 1
  end
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Undo / Redo dans la fenêtre source.                                    │
-- │                                                                        │
-- │  - Utilise `vim.cmd.undo()` / `vim.cmd.redo()` (commands ex propres,    │
-- │    pas `silent! normal!` qui masque toute erreur).                     │
-- │  - Borne historyCount entre 0 et replaceCount pour pas remonter        │
-- │    AU-DESSUS de notre session Match (= dans le travail de l'utilisateur│
-- │    avant ouverture de Match).                                          │
-- │  - Notifie l'utilisateur si vim.cmd échoue.                             │
-- │                                                                        │
-- │  `action` est "undo" ou "redo".                                         │
-- └────────────────────────────────────────────────────────────────────────┘
local function history(action, parent, win)
  local nextCount = action == "undo" and historyCount + 1 or historyCount - 1
  if nextCount > replaceCount or nextCount < 0 then
    return
  end
  set_win(parent)
  local cmd = (action == "undo") and vim.cmd.undo or vim.cmd.redo
  local ok, err = pcall(cmd)
  set_win(win)
  if not ok then
    return vim.notify(
      string.format("Match : %s échoué — %s", action, tostring(err)),
      vim.log.levels.ERROR
    )
  end
  historyCount = nextCount
  if wins.search and vim.api.nvim_win_is_valid(wins.search.win) then
    set_win(parent)
    searchcount(parent, wins.search.win, wins.search.buf)
    set_win(win)
  end
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

  -- Mémorise la position du curseur avant qu'on bouge dans les floats —
  -- la search incrémentale repartira d'ici (pas de la ligne 1).
  local cur = vim.api.nvim_win_get_cursor(parent)
  original_pos = { cur[1], cur[2] }

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
        history("undo", parent, item.win)
      end, opts)
      vim.keymap.set({ "n", "i" }, "<C-r>", function()
        history("redo", parent, item.win)
      end, opts)
    end
  end
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Spec lazy.nvim : plugin virtual (rien à télécharger)                   │
-- │  <leader>sm reste à Snacks marks (picker des vim marks).                │
-- │  Match est sur <leader>r / <leader>R (= Replace, mnémonique).           │
-- └────────────────────────────────────────────────────────────────────────┘
return {
  {
    "match-local",
    virtual = true,
    lazy = false,
    keys = {
      { "<leader>r", "<cmd>MatchWord<cr>", desc = "Match: search/replace (mot sous curseur)" },
      { "<leader>R", ":Match ", desc = "Match: search/replace (saisie libre)" },
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
