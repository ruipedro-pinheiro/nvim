-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                       Web dev tooling                                    ║
-- ║  - Live preview HTML/CSS/Markdown                                        ║
-- ║  - REST client (.http files)                                             ║
-- ║  - Inline color preview (hex, rgb, hsl, tailwind)                        ║
-- ║  - Image preview via snacks.image (kitty graphics protocol)              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

return {
  -- Live preview: ouvre un serveur local et le navigateur, recharge au save
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

  -- REST client: fichiers .http style VSCode REST Client / JetBrains
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

  -- Colorizer: affiche la couleur reelle a cote de #ff5733, rgb(...), tailwind
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
        names = false,        -- pas de "red", "blue" en couleur
        RGB = true,           -- #RGB
        RRGGBB = true,        -- #RRGGBB
        RRGGBBAA = true,      -- #RRGGBBAA
        rgb_fn = true,        -- rgb(...)
        hsl_fn = true,        -- hsl(...)
        css = true,           -- enable everything css
        css_fn = true,
        tailwind = true,      -- bg-red-500 et compagnie
        mode = "background",  -- ou "foreground" / "virtualtext"
      },
    },
  },

  -- Activer snacks.image (deja installe, juste a enable)
  -- Utilise le protocole graphique kitty (que tu as) pour afficher les images
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = true },
    },
  },
}
