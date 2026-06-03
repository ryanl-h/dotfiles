-- Formatter config for conform.nvim (ships with NvChad). Format-on-save is ON
-- but guarded by a toggle (:FormatDisable / <leader>tf, defined in mappings.lua)
-- so you can switch it off on noisy repos.
local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_organize_imports", "ruff_format" }, -- ruff replaces isort + black
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    jsonc = { "prettierd", "prettier", stop_after_first = true },
    css = { "prettierd", "prettier", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    yaml = { "yamlfmt" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    toml = { "taplo" },
  },

  -- "fallback" = format with the LSP if no configured formatter ran.
  -- (Replaces the deprecated `lsp_fallback = true`.)
  default_format_opts = { lsp_format = "fallback" },

  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 500, lsp_format = "fallback" }
  end,
}

return options
