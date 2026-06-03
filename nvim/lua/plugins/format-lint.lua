return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    config = function()
      local lint = require "lint"
      -- Only lint what no LSP already covers. Python and JS/TS are handled by
      -- the ruff and eslint LSP servers, so they're intentionally absent here
      -- (avoids duplicate diagnostics).
      lint.linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        yaml = { "yamllint" },
        markdown = { "markdownlint-cli2" },
      }
      local grp = vim.api.nvim_create_augroup("nvim_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = grp,
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
