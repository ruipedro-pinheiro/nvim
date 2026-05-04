return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          border = "rounded",
          winblend = 0,
          winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
        },
        accept = {
          auto_brackets = {
            enabled = false,
          },
        },
        documentation = {
          auto_show = false,
          window = {
            border = "rounded",
            winblend = 0,
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,EndOfBuffer:NormalFloat",
          },
        },
        ghost_text = {
          enabled = false,
        },
      },
      signature = {
        enabled = true,
        window = {
          border = "rounded",
          winblend = 0,
          winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          show_documentation = false,
        },
      },
      sources = {
        default = { "lsp", "path", "buffer" },
        providers = {
          lsp = {
            -- Only show LSP suggestions once 3+ chars typed (reduces
            -- noise from clangd dumping every in-scope symbol on 1 letter).
            min_keyword_length = 3,
            transform_items = function(_, items)
              return vim.tbl_filter(function(item)
                return item.kind ~= require("blink.cmp.types").CompletionItemKind.Snippet
              end, items)
            end,
          },
          buffer = {
            min_keyword_length = 3,
          },
          -- path: pas de min_keyword_length (déclenché par `/`, pas par lettres)
        },
      },
    },
  },
}
