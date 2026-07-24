-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║              Match — Floating Search/Replace (VSCode style)              ║
-- ║                                                                          ║
-- ║  Adapted from ankushbhagats/match.nvim (commit 53bfa67), under the MIT  ║
-- ║  license. Code is almost identical to upstream, with 3 local VSCode     ║
-- ║  toggles: case-sensitive (Aa), whole-word (ab), regex (.*).             ║
-- ║                                                                          ║
-- ║  Position: top-right (anchor "NE", col = vim.o.columns).                ║
-- ║                                                                          ║
-- ║  COMMANDS                                                                ║
-- ║    :Match [text]    Opens the UI with [text] prefilled                  ║
-- ║    :MatchWord       Opens with the word under the cursor                ║
-- ║    :MatchLine       Opens with the current line                         ║
-- ║                                                                          ║
-- ║  IN THE UI                                                               ║
-- ║    <Tab>            Toggles Search ↔ Replace                            ║
-- ║    <Esc> / <C-q>    Closes                                              ║
-- ║                                                                          ║
-- ║  Mode SEARCH                                                             ║
-- ║    <CR>             Moves to the Replace field                          ║
-- ║    <Up>             Previous match                                      ║
-- ║    <Down>           Next match                                          ║
-- ║                                                                          ║
-- ║  Mode REPLACE                                                            ║
-- ║    <CR>             Replaces ALL                                        ║
-- ║    <Up>             Replaces the previous match                         ║
-- ║    <Down>           Replaces the next match                             ║
-- ║    <C-u> / <C-r>    Undo / Redo (undoes one replace)                    ║
-- ║                                                                          ║
-- ║  TOGGLES (anywhere in the UI, insert or normal mode)                    ║
-- ║    <A-c>            Case-sensitive (Aa)                                 ║
-- ║    <A-w>            Whole-word (ab)                                     ║
-- ║    <A-r>            Regex (.*)                                          ║
-- ║                                                                          ║
-- ║  DEFAULT KEYMAPS (declared in the plugin spec at the bottom of file)    ║
-- ║    <leader>r        :MatchWord (word under cursor)                      ║
-- ║    <leader>R        :Match (free input)                                  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local config = {
  prefix = "",
  style = "minimal",
  border = "rounded",
  border_hl = "FloatBorder",
}

-- Local state: toggles + window references
local toggles = { case_sensitive = false, whole_word = false, regex = false }
local wins = {}
local searchText = ""    -- final Vim pattern (with \c \C \< \> modifiers and escapes)
local rawSearch = ""     -- raw typed text (used to rebuild on toggle)
local replaceText = ""
local replaceCount = 0
local historyCount = 0
local original_pos = { 1, 0 }  -- cursor position at open time (VSCode-style incremental search restarts there, not at line 1)
local saved_hlsearch = nil     -- hlsearch snapshot at open(), restored at close()

local ns = vim.api.nvim_create_namespace("match_local")

-- Escape `replaceText` for `:s/pat/rep/`.
--
-- - Always:
--     `/`         substitute delimiter → escaped as `\/`
--     newline     replaced with `\r` (vim sub sequence = line break)
--
-- - Regex mode OFF (literal):
--     `\`         escaped as `\\` (otherwise vim sub interprets \1-\9, \&, etc.)
--     `&`         escaped as `\&` (otherwise = matched text)
--     `~`         escaped as `\~` (otherwise = previous replacement)
--   → result: text is inserted exactly as-is, whatever its contents.
--
-- - Regex mode ON:
--     `\` `&` `~` NOT escaped → \1-\9, &, ~ can be used as capture
--     references and matched text.
--
-- Substitution order matters: `\` BEFORE `/` and `& ~`
-- to avoid double-escaping the `\` injected by the other rules.
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
-- │  Build the Vim pattern according to toggles                             │
-- │                                                                          │
-- │  - regex OFF → escape input metachars                                   │
-- │  - regex ON  → keep metachars BUT escape `/` (otherwise it breaks       │
-- │    `:s/pat/rep/` because it is the substitute delimiter)                │
-- │  - whole_word ON → surround with \< \> (word boundaries)                │
-- │  - case_sensitive → \C (sensitive) ou \c (insensitive)                  │
-- └────────────────────────────────────────────────────────────────────────┘
local function build_pattern(text)
  if not text or text == "" then
    return ""
  end
  local body
  if toggles.regex then
    -- Keep user metachars, but escape `/` to avoid breaking
    -- the `:s/pat/rep/` delimiter later.
    body = (text:gsub("/", "\\/"))
  else
    -- Non-regex: escape all vim metachars, including `/`.
    body = vim.fn.escape(text, [[\/.*$^~[]])
  end
  if toggles.whole_word then
    body = [[\<]] .. body .. [[\>]]
  end
  local case = toggles.case_sensitive and [[\C]] or [[\c]]
  return case .. body
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Create a floating window (Search or Replace) at the top right          │
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
-- │  Adapt floats to editor size changes                                    │
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
  -- Restore hlsearch (search()/replace() forced it).
  if saved_hlsearch ~= nil then
    vim.o.hlsearch = saved_hlsearch
  end
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
-- │  [N/M] counter + toggle state, displayed in the Search bar              │
-- │  via right-aligned virt_text                                            │
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
-- │  Callback on each keystroke in the Search field                         │
-- │                                                                        │
-- │  Search from the opening position (original_pos), not from line 1 —    │
-- │  expected behavior for incremental search.                              │
-- │                                                                        │
-- │  vim.fn.search returns 0 when there is no match (no throw); no pcall   │
-- │  needed.                                                              │
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
  -- Reset to the original position. cursor() clamps out-of-buffer values
  -- (e.g. line deleted after opening), so this is safe without a check.
  vim.fn.cursor(original_pos[1], original_pos[2] + 1)
  -- "Wc": no wrap, accepts the current match.
  vim.fn.search(searchText, "Wc")
  searchcount(parent, win, buf)
  set_win(win)
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Reapply the current pattern after a toggle (without moving the cursor) │
-- └────────────────────────────────────────────────────────────────────────┘
local function reapply()
  if not wins.search or not vim.api.nvim_win_is_valid(wins.search.win) then
    return
  end
  if rawSearch == "" then
    -- Even without a pattern, refresh the toggle display.
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
-- │  - Replacement escaped via escape_replacement (regex-aware, also       │
-- │    handles literal newlines).                                          │
-- │  - Vim cmd errors captured and displayed (never silent!).              │
-- │  - Match count captured BEFORE substitute (searchcount.total).         │
-- │  - Cursor restored to original_pos after substitute (vim sub otherwise │
-- │    moves the cursor to the last match).                                │
-- │  - UI closed only on success.                                          │
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

  -- Restore the cursor to the opening position (vim sub moved it to the
  -- last replaced match, which is disorienting).
  vim.fn.cursor(original_pos[1], original_pos[2] + 1)

  vim.notify(string.format("Match : %d remplacement(s)", total), vim.log.levels.INFO)
  close()
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Navigation: next (key="n") or previous (key="N") match.               │
-- │  Use vim.fn.search (API) instead of `silent! normal!`:                 │
-- │  - No silent! swallowing errors.                                        │
-- │  - vim.fn.search returns 0 when nothing is found (cleanly handled).    │
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
-- │  Sequence:                                                             │
-- │  1. `searchpos` (without `n`) → cursor moved to match start.            │
-- │  2. `searchpos(..., "Wcen")` → match end WITHOUT moving cursor (`n`).  │
-- │  3. `nvim_buf_set_text(start, end, replaceText.split("\n"))` →         │
-- │     100% literal insertion, never reinterpreted by normal mode.        │
-- │  4. Cursor moved AFTER the replaced zone to prevent                    │
-- │     `search "W"` re-matching in the replacement (case: "foo" →        │
-- │     "foofoo").                                                        │
-- │  5. `vim.fn.search` to the next match.                                  │
-- └────────────────────────────────────────────────────────────────────────┘
local function replaceJump(key, parent)
  local sw, sb = wins.search.win, wins.search.buf
  local rw = wins.replace.win
  if not vim.api.nvim_win_is_valid(parent) or searchText == "" then
    return
  end
  set_win(parent)

  -- 1. Locate the next (key="n") or previous (key="N") match.
  local flag = (key == "n") and "W" or "Wb"
  local start_row, start_col = unpack(vim.fn.searchpos(searchText, flag))
  if start_row == 0 then
    set_win(rw)
    return vim.notify("Match : pas d'autre match", vim.log.levels.WARN)
  end

  -- 2. Match end WITHOUT moving the cursor (n = no-move, c = accept current
  --    match, e = end position).
  local end_row, end_col = unpack(vim.fn.searchpos(searchText, "Wcen"))
  if end_row == 0 then
    set_win(rw)
    return vim.notify("Match : end-of-match introuvable (regex foireuse ?)", vim.log.levels.ERROR)
  end

  -- 3. Replace the [start, end+1) interval with replaceText, literally.
  --    (start_col / end_col are 1-indexed from searchpos; nvim_buf_set_text
  --    expects 0-indexed positions, exclusive end.)
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

  -- 4. Direction-aware cursor position to avoid re-matching inside replacement.
  --    Forward (n): cursor AFTER the replacement; search "W" finds the next.
  --    Backward (N): cursor AT replacement start; search "Wb" searches
  --    strictly before it → skips over the replacement (no re-match).
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

  -- 5. Jump in the requested direction (W or Wb depending on key).
  vim.fn.search(searchText, flag)
  searchcount(parent, sw, sb)
  set_win(rw)

  -- Bug 2 fix: if undos happened before this new replace, the undo tree has
  -- branched → previous redos are buried. Resync counters so <C-u> cannot go
  -- above the Match session into earlier work.
  if historyCount > 0 then
    replaceCount = replaceCount - historyCount + 1
    historyCount = 0
  else
    replaceCount = replaceCount + 1
  end
end

-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  Undo / Redo in the source window.                                      │
-- │                                                                        │
-- │  - Use `vim.cmd.undo()` / `vim.cmd.redo()` (proper ex commands,        │
-- │    not `silent! normal!`, which hides errors).                         │
-- │  - Clamp historyCount between 0 and replaceCount to avoid going        │
-- │    ABOVE the Match session (= work before Match opened).               │
-- │  - Notify if vim.cmd fails.                                            │
-- │                                                                        │
-- │  `action` is "undo" or "redo".                                        │
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
-- │  Force insert mode when switching to a float buffer                     │
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
-- │  Entry point: open both floats and install keymaps                      │
-- └────────────────────────────────────────────────────────────────────────┘
local function open(args)
  args = args or ""
  local parent = vim.api.nvim_get_current_win()

  -- Remember the cursor position before moving into floats —
  -- incremental search restarts here (not from line 1).
  local cur = vim.api.nvim_win_get_cursor(parent)
  original_pos = { cur[1], cur[2] }
  saved_hlsearch = vim.o.hlsearch  -- snapshot for restoration at close()

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
-- │  lazy.nvim spec: virtual plugin (nothing to download)                   │
-- │  <leader>sm remains Snacks marks (vim marks picker).                    │
-- │  Match is on <leader>r / <leader>R (= Replace mnemonic).                │
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
