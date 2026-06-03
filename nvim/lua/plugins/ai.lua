-- In-editor Claude that runs on the Team subscription with NO API key.
-- claudecode.nvim is a pure-Lua implementation of Claude Code's IDE protocol:
-- it stands up a localhost WebSocket and the interactive `claude` CLI (already
-- logged into the Team plan) connects back to it. The CLI owns ALL Anthropic
-- auth, so traffic stays on the interactive subscription pool — unaffected by
-- the 2026-06-15 Agent-SDK metered-credit change. Do NOT set ANTHROPIC_API_KEY
-- (it would override subscription auth and switch to pay-as-you-go billing).
--
-- macOS note: large Cmd-V pastes into the Claude terminal can truncate on
-- Neovim < 0.12.2 (issue #161); we're on 0.12.2 so this is moot, but right-click
-- paste is the fallback.
return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject Claude diff" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer to Claude context" },
    },
  },
}
