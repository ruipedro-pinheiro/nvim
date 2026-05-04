-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                       Database UI (vim-dadbod)                           ║
-- ║  Postgres / MySQL / SQLite / MongoDB / Redis depuis nvim                 ║
-- ║  - <leader>Du : ouvrir l'UI                                              ║
-- ║  - <leader>Df : trouver le buffer DB                                     ║
-- ║  - <leader>Dr : run la query sous le curseur                             ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "DB: Toggle UI" },
      { "<leader>Df", "<cmd>DBUIFindBuffer<cr>", desc = "DB: Find buffer" },
      { "<leader>Da", "<cmd>DBUIAddConnection<cr>", desc = "DB: Add connection" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1
    end,
  },
}
