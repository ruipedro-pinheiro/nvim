-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                        Debugger C/C++ (codelldb)                         ║
-- ║  Core DAP (UI + virtual text + keymaps) vient de l'extra LazyVim:        ║
-- ║    lazyvim.plugins.extras.dap.core                                       ║
-- ║  Ce fichier ajoute juste l'adapter et la config de lancement C/C++.      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

return {
  -- Auto-install codelldb (C/C++) and js-debug-adapter (JS/TS) via Mason
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = { "codelldb", "js-debug-adapter" },
      automatic_installation = true,
    },
  },

  -- JS/TS debug (Node + Chrome) via vscode-js-debug
  {
    "mxsdev/nvim-dap-vscode-js",
    dependencies = { "mfussenegger/nvim-dap" },
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    config = function()
      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
        debugger_cmd = { "js-debug-adapter" },
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      })

      local dap = require("dap")
      for _, lang in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[lang] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch Node (current file)",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome (localhost:3000)",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to running Node",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end,
  },

  -- DAP UI: bordures arrondies cohérentes + barre d'icônes désactivée
  -- (on utilise les keymaps <Space>d... + F9, plus besoin des icônes).
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      floating = {
        border = "rounded",
      },
      expand_lines = true,
      controls = {
        enabled = false,
      },
    },
  },

  -- Adapter + configurations C/C++
  {
    "mfussenegger/nvim-dap",
    keys = {
      -- F-keys for the most common debug actions (universal convention,
      -- matches VSCode/JetBrains/gdb-tui).
      { "<F9>",  function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<F10>", function() require("dap").step_over() end,         desc = "Step Over" },
      { "<F11>", function() require("dap").step_into() end,         desc = "Step Into" },
      { "<F12>", function() require("dap").step_out() end,          desc = "Step Out" },
    },
    config = function()
      local dap = require("dap")

      -- codelldb adapter (LLDB-based, supports C/C++/Rust)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = { "--port", "${port}" },
        },
      }

      -- Smart default: pre-fill with cwd + lowercased project folder name
      -- (matches the convention of 42 projects: ~/GITHUB/Minishell → ./minishell)
      local function pick_program()
        local cwd = vim.fn.getcwd()
        local guess = cwd .. "/" .. vim.fn.fnamemodify(cwd, ":t"):lower()
        return vim.fn.input("Path to executable: ", guess, "file")
      end

      local cpp_configs = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = pick_program,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }

      dap.configurations.c = cpp_configs
      dap.configurations.cpp = cpp_configs
    end,
  },
}
