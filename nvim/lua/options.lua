require "nvchad.options"

local o = vim.o

-- Absolute line for the cursor, relative elsewhere — fast j/k motions.
o.number = true
o.relativenumber = true
-- Keep context around the cursor when scrolling.
o.scrolloff = 8
-- Don't soft-wrap code; long lines scroll horizontally.
o.wrap = false
-- Snappier CursorHold/LSP than the 4000ms default.
o.updatetime = 250
-- How long to wait for a mapped sequence (which-key popup feel).
o.timeoutlen = 400
-- Persistent undo across sessions.
o.undofile = true
-- Case-insensitive search unless the query has an uppercase char.
o.ignorecase = true
o.smartcase = true
-- Always show the sign column so diagnostics/git signs don't shift text.
o.signcolumn = "yes"
-- Treat dash-joined words as one word (CSS classes, kebab-case identifiers).
vim.opt.iskeyword:append "-"
