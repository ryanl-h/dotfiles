require "nvchad.mappings"

local map = vim.keymap.set

-- starter QoL
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Formatting (conform.nvim; config in lua/configs/conform.lua)
map("n", "<leader>fm", function()
  require("conform").format { lsp_format = "fallback" }
end, { desc = "Format buffer" })
map("n", "<leader>tf", "<cmd>FormatDisable<cr>", { desc = "Toggle off autoformat-on-save" })

-- Toggle commands for format-on-save. Defined here (loaded at startup) so they
-- exist regardless of when conform lazy-loads. conform's format_on_save guard
-- reads vim.g/vim.b.disable_autoformat (see lua/configs/conform.lua).
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.disable_autoformat = true -- this buffer only
  else
    vim.g.disable_autoformat = true -- globally
  end
end, { desc = "Disable autoformat-on-save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, { desc = "Re-enable autoformat-on-save" })
