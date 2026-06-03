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

  -- Semantic text objects on top of NvChad's treesitter. (Task 9)
  -- NOTE: this uses the master-branch textobjects API to match the treesitter
  -- revision NvChad pins. If `:Lazy` shows nvim-treesitter on branch `main`,
  -- switch to the main-branch textobjects setup (see plan Task 9 note).
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "python", "javascript", "typescript", "tsx", "html", "css", "json",
        "lua", "bash", "yaml", "dockerfile", "markdown", "markdown_inline", "toml",
      })
      opts.textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer", ["if"] = "@function.inner",
            ["ac"] = "@class.outer",    ["ic"] = "@class.inner",
            ["ap"] = "@parameter.outer", ["ip"] = "@parameter.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
          goto_previous_start = { ["[m"] = "@function.outer", ["[["] = "@class.outer" },
        },
      }
      return opts
    end,
  },
}
