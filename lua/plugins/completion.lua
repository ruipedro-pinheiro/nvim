-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  Switch blink → nvim-cmp.                                                   ║
-- ║  blink (in LazyVim) rewires `auto_insert` to a dynamic function that cannot ║
-- ║  be forced to false → navigating with ↑/↓ replaced the typed word.          ║
-- ║  LazyVim nvim-cmp uses `completeopt = noinsert` natively: navigation        ║
-- ║  highlights WITHOUT changing the typed word. Confirm with <CR>/<C-y>.       ║
-- ║  + preselect = None (nothing pre-highlighted) + removed "buffer" source.    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
return {
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      local cmp = require("cmp")
      -- Nothing is preselected; <CR> confirms only an explicit selection.
      opts.preselect = cmp.PreselectMode.None
      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
        completeopt = "menu,menuone,noinsert,noselect",
      })
      -- Remove the "buffer" source (random file words = irrelevant noise).
      if opts.sources then
        opts.sources = vim.tbl_filter(function(s)
          return s.name ~= "buffer"
        end, opts.sources)
      end
      return opts
    end,
  },
}
