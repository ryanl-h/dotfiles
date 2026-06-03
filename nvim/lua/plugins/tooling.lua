-- Declaratively install every LSP server, formatter, and linter binary so the
-- config is reproducible on a fresh machine. Mason package names (which differ
-- from lspconfig server names) are used here.
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    config = function()
      require("mason-tool-installer").setup {
        ensure_installed = {
          -- LSP servers
          "lua-language-server",
          "basedpyright",
          "ruff",
          "typescript-language-server",
          "eslint-lsp",
          "css-lsp", -- cssls
          "html-lsp", -- html
          "json-lsp", -- jsonls
          "tailwindcss-language-server",
          "yaml-language-server",
          "bash-language-server",
          "dockerfile-language-server",
          "marksman",
          "taplo",
          -- Formatters
          "stylua",
          "prettierd",
          "prettier",
          "shfmt",
          "yamlfmt",
          -- Linters
          "shellcheck",
          "yamllint",
          "markdownlint-cli2",
        },
        run_on_start = true,
        auto_update = false,
      }
    end,
  },
}
