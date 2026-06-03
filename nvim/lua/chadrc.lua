-- Mirrors the schema in NvChad/ui (v3.0): lua/nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
---@type ChadrcConfig
local M = {}

M.base46 = {
  -- base46 ships "tokyonight"; matches the tmux status bar + starship prompt.
  theme = "tokyonight",
  -- <leader>th cycles dark <-> light.
  theme_toggle = { "tokyonight", "one_light" },

  -- base46's tokyonight is already ~#1a1b26, but it skews slightly red. Pin the
  -- most visible groups to the EXACT tmux/starship hexes so nvim/tmux/starship
  -- look identical. For pixel-exact control, copy a base46 theme into
  -- lua/themes/<name>.lua and edit its palette table instead.
  hl_override = {
    Comment = { fg = "#565f89", italic = true }, -- muted grey, matches starship
    Visual = { bg = "#3b4261" }, -- selection, matches tmux current-window bg
  },
}

M.ui = {
  telescope = { style = "bordered" }, -- borders read better with Tokyo Night
}

return M
