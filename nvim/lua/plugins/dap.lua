-- Single anchor spec so the whole debug stack loads together in the right order.
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- nvim-nio is a HARD dependency of dap-ui since its async rewrite.
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
      { "jay-babu/mason-nvim-dap.nvim", dependencies = { "mason-org/mason.nvim" } },
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input "Condition: ") end, desc = "DAP conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "DAP continue/start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "DAP step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "DAP step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "DAP step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "DAP REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "DAP run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "DAP terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "DAP eval" },
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      -- Install debug adapters via Mason and auto-wire their default configs.
      -- These are DAP names: python -> debugpy, js -> js-debug-adapter.
      require("mason-nvim-dap").setup {
        ensure_installed = { "python", "js" },
        automatic_installation = true,
        handlers = {
          function(config)
            require("mason-nvim-dap").default_setup(config)
          end,
        },
      }

      dapui.setup()
      require("nvim-dap-virtual-text").setup {
        enabled = true,
        highlight_changed_variables = true,
        -- inline virt-text needs nvim 0.10+; fall back to end-of-line otherwise.
        virt_text_pos = vim.fn.has "nvim-0.10" == 1 and "inline" or "eol",
      }

      -- Python: point at Mason's debugpy venv (portable across projects) — NOT
      -- the project venv, so debugging works even where debugpy isn't installed.
      -- dap-python still auto-detects the project venv for the debugged program.
      require("dap-python").setup(
        vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python"
      )

      -- JS/TS: register the pwa-node adapter directly against Mason's
      -- vscode-js-debug build. The old nvim-dap-vscode-js wrapper is abandoned.
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            vim.fn.stdpath "data" .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
            "${port}",
            "127.0.0.1", -- passing host avoids a known init race
          },
        },
      }
      for _, lang in ipairs { "javascript", "typescript", "javascriptreact", "typescriptreact" } do
        dap.configurations[lang] = {
          { type = "pwa-node", request = "launch", name = "Launch file", program = "${file}", cwd = "${workspaceFolder}" },
          { type = "pwa-node", request = "attach", name = "Attach", processId = require("dap.utils").pick_process, cwd = "${workspaceFolder}" },
        }
      end

      -- Auto open/close the UI around debug sessions.
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
    end,
  },
}
