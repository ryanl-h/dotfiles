return {
  -- Faster completion. This NvChad import disables the default nvim-cmp and
  -- loads saghen/blink.cmp with NvChad's first-class config. (Task 6)
  { import = "nvchad.blink.lazyspec" },

  -- Formatting; config in lua/configs/conform.lua. event=BufWritePre turns on
  -- format-on-save. (Task 7)
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = require "configs.conform",
  },

  -- LSP; config in lua/configs/lspconfig.lua. SchemaStore feeds JSON/YAML
  -- schemas to jsonls/yamlls. (Task 5)
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Treesitter: NvChad v2.5 drives the MAIN-branch nvim-treesitter (its autocmds
  -- call `require("nvim-treesitter").install` + `vim.treesitter.start`), so we
  -- stay on the default (main) branch and only extend the parser list. NvChad
  -- installs these via its :TSInstallAll command / FileType autocmd.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "python", "javascript", "typescript", "tsx", "html", "css", "json",
        "lua", "bash", "yaml", "dockerfile", "markdown", "markdown_inline", "toml",
      })
      return opts
    end,
  },

  -- Semantic text objects via the MAIN-branch textobjects API: setup() plus
  -- manual keymaps that call the select/move helpers. Uses af/if (function),
  -- ac/ic (class), aa/ia (argument — chosen over ap/ip so we don't shadow the
  -- built-in paragraph text objects).
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup { move = { set_jumps = true } }

      local sel = require "nvim-treesitter-textobjects.select"
      local objects = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      }
      for lhs, capture in pairs(objects) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          sel.select_textobject(capture, "textobjects")
        end, { desc = "TS select " .. capture })
      end

      local move = require "nvim-treesitter-textobjects.move"
      vim.keymap.set({ "n", "x", "o" }, "]m", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
      vim.keymap.set({ "n", "x", "o" }, "[m", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function" })
      vim.keymap.set({ "n", "x", "o" }, "]]", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
      vim.keymap.set({ "n", "x", "o" }, "[[", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class" })
    end,
  },
}
