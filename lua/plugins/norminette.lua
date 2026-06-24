-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                  Norminette 42 — via nvim-lint (sortie JSON)                ║
-- ║                                                                            ║
-- ║  Remplace hardyrafael17/norminette42.nvim, qui était cassé :                ║
-- ║   - colonnes parsées par offsets de caractères FIXES → fausses dès que la    ║
-- ║     sortie norminette est colorée (3.3.59) → diagnostic à côté (ex: posé     ║
-- ║     sur NULL au lieu du `+`) ;                                               ║
-- ║   - codes ANSI (^[[94m…) laissés dans le message ;                          ║
-- ║   - norminette lancé sur le fichier DISQUE, pas le buffer.                   ║
-- ║                                                                            ║
-- ║  Ici : `norminette --no-colors -f json` → JSON structuré (lineno/column      ║
-- ║  exacts, zéro ANSI), parsé proprement. Lint à l'ouverture / au save / en     ║
-- ║  sortie d'insert sur les .c/.h.                                              ║
-- ║                                                                            ║
-- ║  (l'ancien plugin reste installé mais n'est plus chargé → `:Lazy clean`.)    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

return {
  {
    "mfussenegger/nvim-lint",
    ft = { "c", "cpp" },
    config = function()
      local lint = require("lint")

      lint.linters.norminette = {
        cmd = "norminette",
        stdin = false,
        args = { "--no-colors", "-f", "json" },
        stream = "stdout",
        ignore_exitcode = true, -- norminette sort en code != 0 dès qu'il y a une erreur
        parser = function(output)
          local diags = {}
          -- norminette préfixe sa sortie d'un "Setting locale to en_US" → on isole
          -- l'objet JSON ({...}) avant de décoder, sinon vim.json.decode plante.
          local json = output:match("%b{}")
          if not json then
            return diags
          end
          local ok, decoded = pcall(vim.json.decode, json)
          if not ok or type(decoded) ~= "table" or not decoded.files then
            return diags
          end
          for _, file in ipairs(decoded.files) do
            for _, err in ipairs(file.errors or {}) do
              local sev = err.level == "Error" and vim.diagnostic.severity.ERROR
                or vim.diagnostic.severity.WARN
              for _, h in ipairs(err.highlights or {}) do
                -- vim.json.decode rend les `null` JSON comme vim.NIL (truthy) → on
                -- valide le type `number`, sinon `col + vim.NIL` lève une erreur.
                local lnum = type(h.lineno) == "number" and h.lineno or 1
                local hcol = type(h.column) == "number" and h.column or 1
                local col = math.max(hcol - 1, 0)
                table.insert(diags, {
                  lnum = math.max(lnum - 1, 0),
                  col = col,
                  end_col = type(h.length) == "number" and (col + h.length) or nil,
                  severity = sev,
                  source = "norminette",
                  code = err.name,
                  message = err.text or err.name,
                })
              end
            end
          end
          return diags
        end,
      }

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("NorminetteLint", { clear = true }),
        pattern = { "*.c", "*.h" },
        callback = function()
          require("lint").try_lint("norminette")
        end,
      })

      -- nvim-lint est chargé sur ft=c/cpp : l'autocmd BufReadPost rate le 1er
      -- buffer (celui qui a déclenché le load), on le lint donc tout de suite.
      -- Inconditionnel pour couvrir aussi les .h (filetype cpp sur ce nvim).
      require("lint").try_lint("norminette")
    end,
  },
}
