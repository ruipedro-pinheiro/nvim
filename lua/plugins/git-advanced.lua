-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                       Git avance: diffview                               ║
-- ║  Complement de gitsigns + lazygit (deja en place):                       ║
-- ║  - Diff visuel multi-fichier entre deux refs/commits                     ║
-- ║  - Historique d'un fichier (et naviguer dans les versions)               ║
-- ║  - Resolution de conflits avec une UI 3-way                              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: Open (working tree vs HEAD)" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview: Close" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: Current file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: Branch history" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
          disable_diagnostics = true,
        },
      },
    },
  },
}
