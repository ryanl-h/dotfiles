return {
  -- Telescope: add the native C fuzzy sorter and route vim.ui.select (code
  -- actions, rename) through telescope. NvChad ships telescope; we extend its
  -- opts so NvChad auto-loads these extensions.
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    opts = function(_, opts)
      opts.extensions_list = opts.extensions_list or {}
      vim.list_extend(opts.extensions_list, { "fzf", "ui-select" })
      opts.extensions = opts.extensions or {}
      opts.extensions["ui-select"] = { require("telescope.themes").get_dropdown {} }
      return opts
    end,
  },

  -- Diagnostics / symbols panel — the "Problems" tab NvChad lacks (Trouble v3).
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
    },
  },

  -- Highlight + search TODO/FIX/HACK/NOTE comments.
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
  },

  -- Symbol outline (functions/classes), treesitter- or LSP-backed.
  {
    "stevearc/aerial.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    cmd = "AerialToggle",
    opts = {},
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Outline (Aerial)" },
    },
  },

  -- Per-project session restore (manual trigger so it doesn't fight nvdash).
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
      { "<leader>ql", function() require("persistence").load { last = true } end, desc = "Restore last session" },
    },
  },

  -- QoL bundle. snacks is already pulled in by claudecode.nvim; enable ONLY a
  -- few modules to avoid colliding with NvChad's dashboard/picker/explorer/
  -- statusline. Snacks.lazygit() auto-themes lazygit to Tokyo Night.
  -- Requires the `lazygit` binary (brew install lazygit).
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      lazygit = { enabled = true },
      notifier = { enabled = true },
      input = { enabled = true },
    },
    keys = {
      { "<leader>gg", function() require("snacks").lazygit() end, desc = "LazyGit" },
    },
  },
}
