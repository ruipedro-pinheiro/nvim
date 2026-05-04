-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                           Core Theme + 42 Header                       ║
-- ║  clangd/mason config comes from extra: lazyvim.plugins.extras.lang.clangd
-- ║  harpoon config comes from extra: lazyvim.plugins.extras.editor.harpoon2
-- ╚══════════════════════════════════════════════════════════════════════════╝

return {
  -- ┌────────────────────────────────────────────────────────────────────────┐
  -- │                         Catppuccin Theme                               │
  -- └────────────────────────────────────────────────────────────────────────┘
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
      transparent_background = false,
      term_colors = true,
      no_italic = true,
      no_bold = false,
      integrations = {
        blink_cmp = { enabled = true, style = "bordered" },
        cmp = true,
        dap = true,
        dap_ui = true,
        gitsigns = true,
        mason = true,
        neotree = true,
        noice = true,
        snacks = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        telescope = { enabled = true },
        which_key = true,
      },
      -- ┌──────────────────────────────────────────────────────────────┐
      -- │  Single source of truth for float-style highlights.          │
      -- │                                                              │
      -- │  - Standard nvim floats (FloatBorder/FloatTitle/NormalFloat) │
      -- │    set the canonical colors.                                 │
      -- │  - Plugin-specific groups that don't inherit the canonical   │
      -- │    ones (Blink, Snacks picker) are linked back to them.      │
      -- │  - Tweaking FloatBorder later propagates everywhere via the  │
      -- │    links — no duplicated color values to keep in sync.       │
      -- └──────────────────────────────────────────────────────────────┘
      highlight_overrides = {
        mocha = function(colors)
          -- NormalFloat bg = colors.mantle (one shade darker than editor base).
          -- Gives clear visual contrast so floats stand out as elevated surfaces
          -- (hover, signature help, completion menu, picker).
          -- Border bg also = mantle so rounded corners share the float interior
          -- bg → no mismatching square fill around the curves.
          local float = {
            bg     = { bg = colors.mantle, fg = colors.text },
            border = { fg = colors.mauve, bg = colors.mantle },
            title  = { fg = colors.mauve, bg = colors.mantle, bold = true },
          }

          local hl = {
            -- Canonical float style
            NormalFloat = float.bg,
            FloatBorder = float.border,
            FloatTitle  = float.title,

            -- Blink completion uses its own border groups
            BlinkCmpMenuBorder          = { link = "FloatBorder" },
            BlinkCmpDocBorder           = { link = "FloatBorder" },
            BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },

            -- Cursor line number kept on the mauve accent
            CursorLineNr = { fg = colors.mauve, bold = true },
          }

          -- Note: SnacksPicker* groups are linked theme-agnostically
          -- via a ColorScheme autocmd in autocmds.lua, so they follow
          -- whichever theme is active (incl. picker live preview).

          return hl
        end,
      },
    },
  },

  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },

  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = true,
    },
  },

  -- ┌────────────────────────────────────────────────────────────────────────┐
  -- │                           42 Header                                    │
  -- └────────────────────────────────────────────────────────────────────────┘
  {
    "Diogo-ss/42-header.nvim",
    cmd = { "Stdheader" },
    keys = { { "<F1>", "<cmd>Stdheader<cr>", desc = "Insert 42 Header" } },
    opts = {
      default_map = true,
      auto_update = true,
      user = "rpinheir",
      mail = "rpinheir@student.42lausanne.ch",
      asciiart = {
        "        :::      ::::::::",
        "      :+:      :+:    :+:",
        "    +:+ +:+         +:+  ",
        "  +#+  +:+       +#+     ",
        "+#+#+#+#+#+   +#+        ",
        "     #+#    #+#          ",
        "    ###   ########.ch    ",
      },
    },
  },

  -- ┌────────────────────────────────────────────────────────────────────────┐
  -- │                         Treesitter Languages                           │
  -- └────────────────────────────────────────────────────────────────────────┘
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "dockerfile",
        "html",
        "javascript",
        "json",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
    },
  },

  -- ┌────────────────────────────────────────────────────────────────────────┐
  -- │                    Function Line Counter (42 Norm)                     │
  -- └────────────────────────────────────────────────────────────────────────┘
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Cache du compteur de lignes par fonction.
      -- Lualine appelle get_function_lines() à chaque redraw (CursorMoved,
      -- ModeChanged, BufEnter, etc. = plusieurs fois par seconde). Treesitter
      -- parse + tree walk c'est pas gratuit. On cache par (bufnr, ligne, col,
      -- changedtick) et on retourne direct si rien n'a bougé.
      local cache = {}

      local function compute_function_lines(bufnr, row, col)
        local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
        if not ok or not parser then
          return ""
        end
        local tree = parser:parse()[1]
        if not tree then
          return ""
        end
        local node = tree:root():named_descendant_for_range(row, col, row, col)
        while node do
          if node:type() == "function_definition" then
            local body
            for child in node:iter_children() do
              if child:type() == "compound_statement" then
                body = child
                break
              end
            end
            if body then
              local line_count = math.max(0, body:end_() - body:start() - 1)
              local color
              if line_count >= 25 then
                color = "%#DiagnosticError#"
              elseif line_count >= 20 then
                color = "%#DiagnosticWarn#"
              else
                color = "%#DiagnosticOk#"
              end
              return color .. "Fn:" .. line_count .. "/25" .. "%*"
            end
          end
          node = node:parent()
        end
        return ""
      end

      local function get_function_lines()
        local bufnr = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local row, col = cursor[1] - 1, cursor[2]
        local tick = vim.api.nvim_buf_get_changedtick(bufnr)

        local entry = cache[bufnr]
        if entry and entry.tick == tick and entry.row == row and entry.col == col then
          return entry.result
        end

        local result = compute_function_lines(bufnr, row, col)
        cache[bufnr] = { tick = tick, row = row, col = col, result = result }
        return result
      end

      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, {
        get_function_lines,
        cond = function()
          local ft = vim.bo.filetype
          return ft == "c" or ft == "cpp"
        end,
      })
      return opts
    end,
  },
}
