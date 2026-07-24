-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                  Norminette 42 — via nvim-lint (JSON output)                ║
-- ║                                                                            ║
-- ║  Replaces hardyrafael17/norminette42.nvim, which was broken:                ║
-- ║   - columns parsed with FIXED character offsets → wrong as soon as           ║
-- ║     norminette output is colored (3.3.59) → misplaced diagnostic (ex: on     ║
-- ║     NULL instead of `+`);                                                    ║
-- ║   - ANSI codes (^[[94m…) left in the message;                               ║
-- ║   - norminette run on the DISK file, not the buffer.                         ║
-- ║                                                                            ║
-- ║  Here: `norminette --no-colors -f json` → structured JSON (exact            ║
-- ║  lineno/column, zero ANSI), parsed cleanly. Lint on open / save / insert     ║
-- ║  exit for .c/.h.                                                            ║
-- ║                                                                            ║
-- ║  (the old plugin remains installed but no longer loads → `:Lazy clean`.)     ║
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
        ignore_exitcode = true, -- norminette exits nonzero as soon as there is an error
        parser = function(output)
          local diags = {}
          -- norminette prefixes output with "Setting locale to en_US" → isolate
          -- the JSON object ({...}) before decoding, otherwise vim.json.decode fails.
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
                -- vim.json.decode returns JSON `null` as vim.NIL (truthy) → validate
                -- the `number` type, otherwise `col + vim.NIL` raises an error.
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

      -- nvim-lint loads on ft=c/cpp: the BufReadPost autocmd misses the first
      -- buffer (the one that triggered loading), so lint it immediately.
      -- Unconditional to also cover .h files (filetype cpp on this nvim).
      require("lint").try_lint("norminette")
    end,
  },
}
