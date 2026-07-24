-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                       Advanced Git: diffview                              ║
-- ║  Complement to gitsigns + lazygit (already in place):                    ║
-- ║  - Visual multi-file diff between two refs/commits                       ║
-- ║  - File history (and version navigation)                                 ║
-- ║  - Conflict resolution with a 3-way UI                                   ║
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
