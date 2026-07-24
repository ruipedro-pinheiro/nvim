-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                       Web dev tooling                                    ║
-- ║  - Live preview HTML/CSS/Markdown                                        ║
-- ║  - REST client (.http files)                                             ║
-- ║  - Inline color preview (hex, rgb, hsl, tailwind)                        ║
-- ║  - Image preview via snacks.image (kitty graphics protocol)              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

return {
  -- Live preview: opens a local server and browser, reloads on save
  {
    "brianhuster/live-preview.nvim",
    cmd = { "LivePreview" },
    keys = {
      { "<leader>lp", "<cmd>LivePreview start<cr>", desc = "Live Preview Start" },
      { "<leader>lP", "<cmd>LivePreview close<cr>", desc = "Live Preview Stop" },
    },
    opts = {
      port = 5500,
      browser = "default",
    },
  },

  -- markdown-preview.nvim (pulled by the lang.markdown extra): abandoned since
  -- 2023 + fragile yarn build, and live-preview above already covers browser
  -- preview (including markdown). Disable it.
  { "iamcco/markdown-preview.nvim", enabled = false },

  -- REST client: .http files in VSCode REST Client / JetBrains style
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>Rs", function() require("kulala").run() end, desc = "REST: Send request" },
      { "<leader>Ra", function() require("kulala").run_all() end, desc = "REST: Send all requests" },
      { "<leader>Ri", function() require("kulala").inspect() end, desc = "REST: Inspect request" },
      { "<leader>Rt", function() require("kulala").toggle_view() end, desc = "REST: Toggle headers/body view" },
    },
    opts = {
      default_view = "body",
      default_env = "dev",
    },
  },

  -- Colorizer: shows the real color next to #ff5733, rgb(...), tailwind
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      filetypes = {
        "css", "scss", "sass", "html",
        "javascript", "javascriptreact",
        "typescript", "typescriptreact",
        "lua", "vim", "conf",
      },
      user_default_options = {
        names = false,        -- no "red", "blue" as colors
        RGB = true,           -- #RGB
        RRGGBB = true,        -- #RRGGBB
        RRGGBBAA = true,      -- #RRGGBBAA
        rgb_fn = true,        -- rgb(...)
        hsl_fn = true,        -- hsl(...)
        css = true,           -- enable everything css
        css_fn = true,
        tailwind = true,      -- bg-red-500 and similar
        mode = "background",  -- or "foreground" / "virtualtext"
      },
    },
  },

  -- Enable snacks.image (already installed, only needs enabling)
  -- Uses the kitty graphics protocol to display images
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = true },
    },
  },
}
