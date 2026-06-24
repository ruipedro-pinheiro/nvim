-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  Bascule blink → nvim-cmp.                                                  ║
-- ║  blink (dans LazyVim) re-câble `auto_insert` en fonction dynamique          ║
-- ║  impossible à forcer à false → naviguer avec ↑/↓ remplaçait le mot tapé.    ║
-- ║  nvim-cmp de LazyVim utilise `completeopt = noinsert` nativement : naviguer ║
-- ║  surligne SANS toucher ton mot. On valide avec <CR>/<C-y>.                   ║
-- ║  + preselect = None (rien surligné d'office) + source "buffer" virée.        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
return {
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      local cmp = require("cmp")
      -- rien n'est présélectionné ; <CR> ne confirme que si TU as sélectionné
      opts.preselect = cmp.PreselectMode.None
      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
        completeopt = "menu,menuone,noinsert,noselect",
      })
      -- virer la source "buffer" (mots du fichier au pif = ton bruit "pas pertinent")
      if opts.sources then
        opts.sources = vim.tbl_filter(function(s)
          return s.name ~= "buffer"
        end, opts.sources)
      end
      return opts
    end,
  },
}
