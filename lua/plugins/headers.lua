-- Personal banner inserted with <F2> (C/C++/H), auto-updated on save.
-- The banner content + marker live in lua/personal.lua (gitignored); without it,
-- a generic placeholder is used. Copy lua/personal.lua.example to get started.
local ok, personal = pcall(require, "personal")
personal = ok and personal or {}

local RULE =
  "/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */"
local DEFAULT_BANNER = {
  "/*                                                                            */",
  "/*            Set your banner in lua/personal.lua (see .example)              */",
  "/*                                                                            */",
}

return {
  {
    "custom-header",
    virtual = true,
    lazy = false,
    config = function()
      local banner = personal.banner or DEFAULT_BANNER
      local marker = personal.banner_marker or "Set your banner"

      local function updated_line(time)
        return "/*                        UPDATED: " .. time .. "                        */"
      end

      local function build_header(time)
        local h = { RULE }
        for _, line in ipairs(banner) do
          h[#h + 1] = line
        end
        h[#h + 1] = updated_line(time)
        h[#h + 1] = RULE
        h[#h + 1] = ""
        return h
      end

      -- Filetypes where the banner (a /* ... */ block) is valid.
      local allowed_filetypes = { c = true, cpp = true, h = true }

      local function insert_header()
        if not allowed_filetypes[vim.bo.filetype] then
          vim.notify(
            "Header: banner only for C/C++/H files",
            vim.log.levels.WARN
          )
          return
        end
        local time = vim.fn.strftime("%Y/%m/%d %H:%M:%S")
        vim.api.nvim_buf_set_lines(0, 0, 0, false, build_header(time))
        vim.opt_local.list = false
      end

      local function update_header(args)
        local max_lines = math.min(vim.api.nvim_buf_line_count(args.buf), 20)
        local lines = vim.api.nvim_buf_get_lines(args.buf, 0, max_lines, false)
        local has_header = false
        local replace_until = 0

        for index, text in ipairs(lines) do
          if text:find(marker, 1, true) then
            has_header = true
          end

          if index == 1 and not text:match("^/%* ") then
            break
          end

          if text:match("^/%* ") or text == "" then
            replace_until = index
          else
            break
          end
        end

        if not has_header or replace_until == 0 then
          return
        end

        local time = vim.fn.strftime("%Y/%m/%d %H:%M:%S")
        vim.api.nvim_buf_set_lines(args.buf, 0, replace_until, false, build_header(time))
      end

      vim.keymap.set("n", "<F2>", insert_header, { desc = "Insert header banner" })

      -- Scope to filetypes where the banner makes sense (C/C++/headers).
      -- Avoids running the regex check on every JSON/MD/lua/etc. save.
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("CustomHeader", { clear = true }),
        pattern = { "*.c", "*.h", "*.cpp", "*.hpp" },
        callback = update_header,
      })
    end,
  },
}
