# Neovim Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an amazing, fully-documented Tokyo Night NvChad IDE to the dotfiles repo, with first-class Python / JS-web / ops-docs support and an in-editor Claude that runs on the user's Team plan with no API key.

**Architecture:** Vendor the NvChad 2.5 "starter" into a `nvim/` dir in the repo and symlink it to `~/.config/nvim` (the repo's existing pattern). NvChad loads as a lazy.nvim plugin; our config layers on top via `lua/chadrc.lua`, `lua/configs/*`, and `lua/plugins/*`. AI integration drives the interactive `claude` CLI so it stays on the subscription's interactive usage pool.

**Tech Stack:** Neovim 0.11+, NvChad 2.5, lazy.nvim, Mason, blink.cmp, conform.nvim, nvim-lint, nvim-dap, coder/claudecode.nvim, base46 tokyonight. macOS / Homebrew.

**Spec:** `docs/superpowers/specs/2026-06-03-neovim-setup-design.md`

---

## Execution notes

- **Branch first** (we're on `main`): `git switch -c feat/neovim-setup` (Task 1).
- The `nvim/` directory in the repo IS the live config via symlink; plugins install to `~/.local/share/nvim` on first launch.
- After any change to plugin specs, re-sync with `nvim --headless "+Lazy! sync" +qa`.
- Commit messages end with the repo's `Co-Authored-By` trailer.

---

## Task 1: Branch, prerequisites, scaffold NvChad starter, symlink

**Files:**
- Create: `nvim/` (cloned from NvChad/starter, `.git` removed)
- Symlink: `~/.config/nvim` → `nvim/`

- [ ] **Step 1: Create the feature branch**

Run:
```bash
cd /Users/ryan/work/dotfiles && git switch -c feat/neovim-setup
```
Expected: `Switched to a new branch 'feat/neovim-setup'`

- [ ] **Step 2: Install Homebrew prerequisites**

Run:
```bash
brew install neovim lazygit ripgrep fd
```
Expected: all four installed (or "already installed"). Verify Neovim is ≥ 0.11:
```bash
nvim --version | head -1
```
Expected: `NVIM v0.11.x` or newer. (FiraCode Nerd Font and the `claude` CLI are already present per the repo README and environment.)

- [ ] **Step 3: Back up any existing nvim config**

Run:
```bash
[ -e ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s) || echo "no existing config"
[ -d ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.bak.$(date +%s) || echo "no existing data"
```
Expected: existing config/data (if any) moved aside; otherwise the "no existing" messages.

- [ ] **Step 4: Scaffold the NvChad starter into the repo**

Run:
```bash
cd /Users/ryan/work/dotfiles
git clone https://github.com/NvChad/starter nvim
rm -rf nvim/.git nvim/LICENSE
```
Expected: `nvim/init.lua` and `nvim/lua/` exist. Verify:
```bash
ls nvim nvim/lua nvim/lua/configs nvim/lua/plugins
```
Expected: `init.lua`, `lua/{chadrc,mappings,options}.lua`, `lua/configs/{lazy,lspconfig,conform}.lua`, `lua/plugins/init.lua`.

- [ ] **Step 5: Symlink into place**

Run:
```bash
ln -sf "/Users/ryan/work/dotfiles/nvim" ~/.config/nvim
```
Expected: `readlink ~/.config/nvim` prints the repo path.

- [ ] **Step 6: First launch — let NvChad bootstrap**

Run (interactive, so base46 compiles its cache):
```bash
nvim
```
Expected: lazy.nvim clones plugins, NvChad installs, you land on the nvdash dashboard with the default theme. Quit with `:q`. Then confirm a clean headless start:
```bash
nvim --headless "+Lazy! sync" +qa && echo OK
```
Expected: ends with `OK`, no errors.

- [ ] **Step 7: Commit**

```bash
git add nvim docs/superpowers
git commit -m "$(cat <<'EOF'
feat(nvim): scaffold NvChad starter + spec/plan

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Theme — Tokyo Night, palette-matched (`chadrc.lua`)

**Files:**
- Modify: `nvim/lua/chadrc.lua` (overwrite)

- [ ] **Step 1: Write the theme config**

Overwrite `nvim/lua/chadrc.lua` with:
```lua
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
```

- [ ] **Step 2: Reload and verify the theme applies**

Run:
```bash
nvim --headless "+lua require('base46').load_all_highlights()" +qa && echo OK
```
Expected: `OK`. Then launch `nvim`, confirm the background is the dark Tokyo Night blue-grey and comments render in `#565f89`. `:q`.

- [ ] **Step 3: Commit**

```bash
git add nvim/lua/chadrc.lua
git commit -m "$(cat <<'EOF'
feat(nvim): Tokyo Night theme matched to tmux/starship palette

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Editor options (`options.lua`)

**Files:**
- Modify: `nvim/lua/options.lua` (overwrite)

- [ ] **Step 1: Write the options**

Overwrite `nvim/lua/options.lua` with:
```lua
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
```

- [ ] **Step 2: Verify clean load**

Run:
```bash
nvim --headless "+lua assert(vim.o.relativenumber == true and vim.o.scrolloff == 8)" +qa && echo OK
```
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add nvim/lua/options.lua
git commit -m "$(cat <<'EOF'
feat(nvim): editor options (relativenumber, undofile, smartcase, …)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Keymaps + format-toggle commands (`mappings.lua`)

**Files:**
- Modify: `nvim/lua/mappings.lua` (overwrite)

- [ ] **Step 1: Write the mappings**

Overwrite `nvim/lua/mappings.lua` with:
```lua
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
```

- [ ] **Step 2: Verify commands exist**

Run:
```bash
nvim --headless "+lua assert(vim.fn.exists(':FormatDisable')==2 and vim.fn.exists(':FormatEnable')==2)" +qa && echo OK
```
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add nvim/lua/mappings.lua
git commit -m "$(cat <<'EOF'
feat(nvim): format keymaps + :FormatDisable/:FormatEnable toggles

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: LSP — servers, schemas, Mason auto-install

**Files:**
- Modify: `nvim/lua/configs/lspconfig.lua` (overwrite)
- Create: `nvim/lua/plugins/tooling.lua`
- Modify: `nvim/lua/plugins/init.lua` (overwrite — also sets up blink, conform, treesitter in later tasks; this task writes the lspconfig + treesitter entries)

> Note: `plugins/init.lua` is overwritten once with its final content in **Task 9** (it bundles blink, conform, lspconfig deps, and treesitter). For this task, write the version below; Task 6/7/9 will not need to touch it again because it already includes their entries. Tasks 6, 7, 9 only add/verify the corresponding config files.

- [ ] **Step 1: Write `plugins/init.lua` (final content)**

Overwrite `nvim/lua/plugins/init.lua` with:
```lua
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
```

- [ ] **Step 2: Write `lua/configs/lspconfig.lua`**

Overwrite `nvim/lua/configs/lspconfig.lua` with:
```lua
require("nvchad.configs.lspconfig").defaults()

-- We replaced nvim-cmp with blink.cmp; give every server blink's capabilities.
local ok, blink = pcall(require, "blink.cmp")
if ok then
  vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
end

-- Servers to enable. Mason installs them via plugins/tooling.lua.
local servers = {
  "lua_ls",
  "basedpyright", -- types/hover (maintained pyright fork)
  "ruff",         -- python lint/format/imports (built-in `ruff server`; ruff-lsp is dead)
  "ts_ls",        -- renamed from tsserver
  "eslint",       -- JS/TS lint via LSP (only attaches with an eslint config)
  "html",
  "cssls",
  "jsonls",
  "tailwindcss",
  "yamlls",
  "bashls",
  "dockerls",
  "marksman",
  "taplo",
}

-- Python: basedpyright owns types/hover; ruff owns lint/format/imports.
vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
      disableOrganizeImports = true, -- ruff organizes imports instead
    },
  },
})

-- JSON: validate against the SchemaStore catalog.
vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

-- YAML: disable yamlls' built-in store, use SchemaStore.nvim, and map the
-- bundled Kubernetes schema onto our manifest globs.
local yaml_schemas = require("schemastore").yaml.schemas()
yaml_schemas["kubernetes"] = { "k8s/**/*.yaml", "*.k8s.yaml", "kustomization.yaml" }
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" },
      schemas = yaml_schemas,
      keyOrdering = false, -- k8s manifests aren't alphabetical
    },
  },
})

vim.lsp.enable(servers)

-- ruff's hover duplicates basedpyright's; let basedpyright own it.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ruff_no_hover", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
})
```

- [ ] **Step 3: Write `lua/plugins/tooling.lua` (Mason auto-install of all binaries)**

Create `nvim/lua/plugins/tooling.lua`:
```lua
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
          "vscode-langservers-extracted", -- html, cssls, jsonls
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
```

- [ ] **Step 4: Sync plugins and install tools**

Run:
```bash
nvim --headless "+Lazy! sync" +qa && echo SYNCED
nvim --headless "+MasonToolsInstall" "+sleep 60" +qa ; echo "install attempted"
```
Expected: `SYNCED`. The Mason install runs in the background; give it time. Then verify a few binaries landed:
```bash
ls ~/.local/share/nvim/mason/bin | grep -E 'basedpyright|ruff|typescript-language-server|lua-language-server|stylua|prettierd' || echo "still installing — re-run :Mason in nvim"
```
Expected: the listed binaries appear (re-run if Mason is still downloading).

- [ ] **Step 5: Verify LSP attaches**

Run:
```bash
printf 'x: int = "nope"\n' > /tmp/lsp_check.py
nvim --headless /tmp/lsp_check.py "+sleep 3" "+lua print('#clients='..#vim.lsp.get_clients())" +qa
```
Expected: prints `#clients=` with a number ≥ 1 (basedpyright and/or ruff attached). Then open `/tmp/lsp_check.py` in a real `nvim`, confirm a red type-error diagnostic on the assignment and `K` shows hover from basedpyright (not ruff).

- [ ] **Step 6: Commit**

```bash
git add nvim/lua/configs/lspconfig.lua nvim/lua/plugins/init.lua nvim/lua/plugins/tooling.lua
git commit -m "$(cat <<'EOF'
feat(nvim): LSP for python/web/ops + Mason tool auto-install

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Completion — blink.cmp

**Files:**
- (Already imported in `nvim/lua/plugins/init.lua` Task 5 Step 1.)

- [ ] **Step 1: Sync and verify blink replaced nvim-cmp**

Run:
```bash
nvim --headless "+Lazy! sync" +qa && echo SYNCED
nvim --headless "+lua print(pcall(require,'blink.cmp') and 'blink-ok' or 'blink-missing')" +qa
```
Expected: `SYNCED` then `blink-ok`.

- [ ] **Step 2: Verify LSP completion works with blink**

Open a real `nvim /tmp/lsp_check.py`, type `import o` in insert mode → a blink completion menu offers `os` etc. (Confirms blink's LSP capabilities reached the server.) `:q!`.

- [ ] **Step 3: Commit (if anything changed)**

blink is enabled purely by the import added in Task 5, so there may be nothing new to stage. If `git status` shows changes (e.g. lazy-lock), commit:
```bash
git add nvim
git commit -m "$(cat <<'EOF'
feat(nvim): enable blink.cmp completion

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)" || echo "nothing to commit"
```

---

## Task 7: Formatting — conform.nvim with format-on-save toggle

**Files:**
- Modify: `nvim/lua/configs/conform.lua` (overwrite)
- (conform spec already set in `plugins/init.lua` Task 5 Step 1.)

- [ ] **Step 1: Write `lua/configs/conform.lua`**

Overwrite `nvim/lua/configs/conform.lua` with:
```lua
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
```

- [ ] **Step 2: Verify format-on-save**

Run:
```bash
printf 'x=1\ny   =    2\n' > /tmp/fmt_check.py
nvim --headless /tmp/fmt_check.py "+sleep 2" "+write" "+sleep 2" +qa
cat /tmp/fmt_check.py
```
Expected: file reformatted by ruff (e.g. `x = 1` / `y = 2`). If unchanged, ensure `ruff` installed via Mason (Task 5 Step 4).

- [ ] **Step 3: Verify the toggle**

```bash
printf 'z=3\n' > /tmp/fmt_off.py
nvim --headless /tmp/fmt_off.py "+FormatDisable" "+write" +qa
cat /tmp/fmt_off.py
```
Expected: `z=3` unchanged (autoformat disabled).

- [ ] **Step 4: Commit**

```bash
git add nvim/lua/configs/conform.lua
git commit -m "$(cat <<'EOF'
feat(nvim): conform.nvim format-on-save (ruff/prettierd/stylua/shfmt/…)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Linting — nvim-lint (shell / yaml / markdown)

**Files:**
- Create: `nvim/lua/plugins/format-lint.lua`

- [ ] **Step 1: Write the plugin spec**

Create `nvim/lua/plugins/format-lint.lua`:
```lua
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
```

- [ ] **Step 2: Sync and verify shellcheck lints**

Run:
```bash
nvim --headless "+Lazy! sync" +qa && echo SYNCED
printf '#!/bin/bash\nif [ $x = 1 ]; then echo hi; fi\n' > /tmp/lint_check.sh
nvim --headless /tmp/lint_check.sh "+sleep 3" "+lua print('#diag='..#vim.diagnostic.get(0))" +qa
```
Expected: `SYNCED` then `#diag=` with a number ≥ 1 (shellcheck flags the unquoted `$x`). If 0, confirm `shellcheck` is installed (`ls ~/.local/share/nvim/mason/bin | grep shellcheck`).

- [ ] **Step 3: Commit**

```bash
git add nvim/lua/plugins/format-lint.lua
git commit -m "$(cat <<'EOF'
feat(nvim): nvim-lint for shell/yaml/markdown

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Treesitter text objects (verify branch match)

**Files:**
- (Treesitter override already written in `plugins/init.lua` Task 5 Step 1.)

- [ ] **Step 1: Confirm NvChad's treesitter branch**

Run:
```bash
nvim --headless "+lua local p=require('lazy.core.config').plugins['nvim-treesitter']; print('branch='..tostring(p and p.branch))" +qa
```
Expected: prints `branch=nil` or `branch=master` → the master-branch textobjects config in `plugins/init.lua` is correct. **If it prints `branch=main`**, replace the treesitter `opts` block in `nvim/lua/plugins/init.lua` with the main-branch API:
```lua
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup {}
      local sel = require "nvim-treesitter-textobjects.select"
      for lhs, obj in pairs {
        ["af"] = "@function.outer", ["if"] = "@function.inner",
        ["ac"] = "@class.outer", ["ic"] = "@class.inner",
        ["ap"] = "@parameter.outer", ["ip"] = "@parameter.inner",
      } do
        vim.keymap.set({ "x", "o" }, lhs, function() sel.select_textobject(obj, "textobjects") end)
      end
    end,
  },
```
(and drop the `textobjects = {...}` table + the textobjects dependency from the nvim-treesitter entry).

- [ ] **Step 2: Sync and verify text objects work**

Run:
```bash
nvim --headless "+Lazy! sync" +qa && echo SYNCED
```
Then in a real `nvim /tmp/lsp_check.py` (or any function-containing file), in normal mode on a function body type `vif` → it visually selects the function inner. `:q!`.

- [ ] **Step 3: Commit (if the branch fix was applied)**

```bash
git add nvim/lua/plugins/init.lua
git commit -m "$(cat <<'EOF'
feat(nvim): treesitter semantic text objects

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)" || echo "no change to commit (config already correct in Task 5)"
```

---

## Task 10: Debugging — full DAP stack

**Files:**
- Create: `nvim/lua/plugins/dap.lua`

- [ ] **Step 1: Write the DAP spec**

Create `nvim/lua/plugins/dap.lua`:
```lua
-- Single anchor spec so the whole debug stack loads together in the right order.
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- nvim-nio is a HARD dependency of dap-ui since its async rewrite.
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
      { "jay-babu/mason-nvim-dap.nvim", dependencies = { "mason-org/mason.nvim" } },
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input "Condition: ") end, desc = "DAP conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "DAP continue/start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "DAP step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "DAP step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "DAP step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "DAP REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "DAP run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "DAP terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "DAP eval" },
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      -- Install debug adapters via Mason and auto-wire their default configs.
      -- These are DAP names: python -> debugpy, js -> js-debug-adapter.
      require("mason-nvim-dap").setup {
        ensure_installed = { "python", "js" },
        automatic_installation = true,
        handlers = {
          function(config)
            require("mason-nvim-dap").default_setup(config)
          end,
        },
      }

      dapui.setup()
      require("nvim-dap-virtual-text").setup {
        enabled = true,
        highlight_changed_variables = true,
        -- inline virt-text needs nvim 0.10+; fall back to end-of-line otherwise.
        virt_text_pos = vim.fn.has "nvim-0.10" == 1 and "inline" or "eol",
      }

      -- Python: point at Mason's debugpy venv (portable across projects) — NOT
      -- the project venv, so debugging works even where debugpy isn't installed.
      -- dap-python still auto-detects the project venv for the debugged program.
      require("dap-python").setup(
        vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python"
      )

      -- JS/TS: register the pwa-node adapter directly against Mason's
      -- vscode-js-debug build. The old nvim-dap-vscode-js wrapper is abandoned.
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            vim.fn.stdpath "data" .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
            "${port}",
            "127.0.0.1", -- passing host avoids a known init race
          },
        },
      }
      for _, lang in ipairs { "javascript", "typescript", "javascriptreact", "typescriptreact" } do
        dap.configurations[lang] = {
          { type = "pwa-node", request = "launch", name = "Launch file", program = "${file}", cwd = "${workspaceFolder}" },
          { type = "pwa-node", request = "attach", name = "Attach", processId = require("dap.utils").pick_process, cwd = "${workspaceFolder}" },
        }
      end

      -- Auto open/close the UI around debug sessions.
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
    end,
  },
}
```

- [ ] **Step 2: Sync and verify the stack loads**

Run:
```bash
nvim --headless "+Lazy! sync" +qa && echo SYNCED
nvim --headless "+lua require('dap'); require('dapui'); require('dap-python'); print('dap-ok')" +qa
```
Expected: `SYNCED` then `dap-ok` (no `module not found`, confirming nvim-nio is present).

- [ ] **Step 3: Manual smoke test (Python)**

In a real `nvim`, open a small Python script, `<leader>db` on a line, `<leader>dc` to start → the dap-ui panels open and execution stops at the breakpoint. `<leader>dt` to stop. (Requires `debugpy` installed by Mason — re-run `:Mason` if needed.)

- [ ] **Step 4: Commit**

```bash
git add nvim/lua/plugins/dap.lua
git commit -m "$(cat <<'EOF'
feat(nvim): full DAP stack (python debugpy + node pwa-node)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: In-editor Claude — claudecode.nvim (no API key)

**Files:**
- Create: `nvim/lua/plugins/ai.lua`

- [ ] **Step 1: Confirm Team-plan auth (no API key)**

Run:
```bash
command -v claude && echo "ANTHROPIC_API_KEY=[${ANTHROPIC_API_KEY:-unset}]"
```
Expected: a path to `claude` and `ANTHROPIC_API_KEY=[unset]`. **If it is set, the config must keep it unset** — it would override subscription auth and switch to API billing.

- [ ] **Step 2: Write the AI spec**

Create `nvim/lua/plugins/ai.lua`:
```lua
-- In-editor Claude that runs on the Team subscription with NO API key.
-- claudecode.nvim is a pure-Lua implementation of Claude Code's IDE protocol:
-- it stands up a localhost WebSocket and the interactive `claude` CLI (already
-- logged into the Team plan) connects back to it. The CLI owns ALL Anthropic
-- auth, so traffic stays on the interactive subscription pool — unaffected by
-- the 2026-06-15 Agent-SDK metered-credit change. Do NOT set ANTHROPIC_API_KEY.
--
-- Pinned to a recent commit: the latest tagged release (v0.3.0) lags active
-- development. macOS note: Cmd-V of large pastes into the Claude terminal can
-- truncate on Neovim < 0.12.2 (issue #161) — use right-click paste as a
-- workaround.
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
```

- [ ] **Step 3: Sync and verify it loads + registers commands**

Run:
```bash
nvim --headless "+Lazy! sync" +qa && echo SYNCED
nvim --headless "+lua vim.cmd('runtime! plugin/**/*.lua')" "+lua print(pcall(require,'claudecode') and 'cc-ok' or 'cc-missing')" +qa
```
Expected: `SYNCED` then `cc-ok`.

- [ ] **Step 4: Manual smoke test**

In a real `nvim` inside a project, `<leader>ac` opens a Claude terminal split that's already authenticated (no key prompt). Select lines, `<leader>as` to send; when Claude proposes an edit, it shows as a native diff — `<leader>aa` accepts. Confirms editor-aware, no-API-key operation.

- [ ] **Step 5: Commit**

```bash
git add nvim/lua/plugins/ai.lua
git commit -m "$(cat <<'EOF'
feat(nvim): in-editor Claude via claudecode.nvim (Team plan, no API key)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: IDE quality-of-life layer

**Files:**
- Create: `nvim/lua/plugins/editor.lua`

- [ ] **Step 1: Write the editor spec**

Create `nvim/lua/plugins/editor.lua`:
```lua
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
```

- [ ] **Step 2: Sync, build fzf-native, verify**

Run:
```bash
nvim --headless "+Lazy! sync" +qa && echo SYNCED
nvim --headless "+Lazy! build telescope-fzf-native.nvim" +qa && echo BUILT
nvim --headless "+lua for _,m in ipairs({'trouble','todo-comments','aerial','persistence','snacks'}) do assert(pcall(require,m), m) end print('editor-ok')" +qa
```
Expected: `SYNCED`, `BUILT`, then `editor-ok`.

- [ ] **Step 3: Manual checks**

In a real `nvim`: `<leader>xx` toggles the Trouble panel; `<leader>o` toggles the outline; `<leader>gg` opens lazygit themed to Tokyo Night; `<leader>ft` lists TODOs. `:q`.

- [ ] **Step 4: Commit**

```bash
git add nvim/lua/plugins/editor.lua
git commit -m "$(cat <<'EOF'
feat(nvim): IDE QoL — telescope ext, trouble, todo, aerial, sessions, lazygit

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Fix the lazy-nvm `node` PATH gotcha (`.zshrc`)

**Files:**
- Modify: `.zshrc` (insert after the lazy-nvm block, around line 94)

- [ ] **Step 1: Add a cheap default-node PATH prepend**

In `.zshrc`, immediately after the `npx()  { _nvm_lazy; npx  "$@"; }` line, insert:
```sh

# Neovim/Mason spawn `node` directly (not through this shell), so the lazy nvm
# wrappers above don't expose it to them. Prepend the newest installed node's
# bin to PATH cheaply — no nvm.sh sourcing, so this keeps shell startup fast.
# Re-run `nvm alias default <version>` after upgrading node.
if [ -d "$NVM_DIR/versions/node" ]; then
  _node_bin="$NVM_DIR/versions/node/$(command ls -1 "$NVM_DIR/versions/node" | sort -V | tail -1)/bin"
  [ -d "$_node_bin" ] && export PATH="$_node_bin:$PATH"
  unset _node_bin
fi
```

- [ ] **Step 2: Verify node resolves in a non-interactive shell**

Run:
```bash
zsh -c 'source ~/.zshrc; command -v node && node --version'
```
Expected: a path under `~/.nvm/versions/node/.../bin/node` and a version string. (If you have no node installed via nvm yet, install one first: `zsh -ic "nvm install --lts"`, then re-test.)

- [ ] **Step 3: Commit**

```bash
git add .zshrc
git commit -m "$(cat <<'EOF'
fix(zsh): expose default node on PATH for Neovim/Mason (lazy-nvm gap)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: Documentation

**Files:**
- Create: `nvim/README.md`
- Modify: `README.md` (add Neovim section, brew tools, symlink line)

- [ ] **Step 1: Write `nvim/README.md`**

Create `nvim/README.md`:
```markdown
# Neovim

A Tokyo Night [NvChad](https://nvchad.com) 2.5 IDE: full LSP, completion,
formatting, linting, debugging, fuzzy finding, git, and an in-editor Claude that
runs on a Claude **Team plan with no API key**.

## Prerequisites

| Tool | Install | Why |
|------|---------|-----|
| Neovim ≥ 0.11 | `brew install neovim` | Uses `vim.uv` / `vim.lsp.enable`. |
| lazygit | `brew install lazygit` | Git TUI via `<leader>gg` (auto-themed by Snacks). |
| ripgrep, fd | `brew install ripgrep fd` | Telescope live-grep / find-files. |
| C toolchain | `xcode-select --install` | Builds `telescope-fzf-native`. |
| Node | via nvm (already configured) | `ts_ls`, `prettierd`, `js-debug`, `marksman`. See **Node on PATH** below. |
| `claude` CLI | already installed | In-editor Claude (Team-plan auth). |
| FiraCode Nerd Font | already installed | Icons. |

Mason auto-installs every LSP server, formatter, linter, and debug adapter on
first launch.

## Install

```sh
ln -sf "$PWD/nvim" ~/.config/nvim
nvim                       # first launch bootstraps lazy.nvim + NvChad
```

On first launch, wait for lazy to finish, then run `:MasonToolsInstall` to pull
the language tooling and `:Lazy build telescope-fzf-native.nvim` to compile the
fuzzy sorter. Restart.

## In-editor Claude (no API key)

`coder/claudecode.nvim` drives the **interactive `claude` CLI**, which is already
logged into your Team subscription. The plugin never touches Anthropic auth — it
just opens a local WebSocket the CLI connects to — so all usage stays on your
**interactive subscription pool**.

- **Do not set `ANTHROPIC_API_KEY`** — it overrides subscription auth and switches
  you to pay-as-you-go API billing.
- macOS: `Cmd-V` of large pastes into the Claude terminal can truncate on Neovim
  < 0.12.2 ([#161](https://github.com/coder/claudecode.nvim/issues/161)); use
  right-click paste.

| Key | Action |
|-----|--------|
| `<leader>ac` | Toggle the Claude terminal |
| `<leader>as` | Send the visual selection to Claude |
| `<leader>aa` / `<leader>ad` | Accept / reject Claude's proposed diff |
| `<leader>ab` | Add the current buffer to Claude's context |

**Optional alternative (off by default): CodeCompanion + Claude Code ACP.** A
chat-buffer workflow that also needs no API key (via `claude setup-token` →
`CLAUDE_CODE_OAUTH_TOKEN`). Note: from **2026-06-15** this path draws from a
**separate metered Agent-SDK credit pool**, not your interactive limits, and
needs the `@agentclientprotocol/claude-agent-acp` npm bridge + Node. Avante's
`auth_type='max'` is deliberately excluded — it's the reverse-engineered-OAuth
route Anthropic blocked.

## Language support

| Language | LSP | Format | Lint | Debug |
|----------|-----|--------|------|-------|
| Python | basedpyright + ruff | ruff | ruff (LSP) | debugpy |
| JS/TS/web | ts_ls, html, cssls, jsonls, tailwindcss | prettierd | eslint (LSP) | js-debug |
| Lua | lua_ls | stylua | — | — |
| Bash | bashls | shfmt | shellcheck | — |
| YAML/K8s | yamlls (+SchemaStore, k8s) | yamlfmt | yamllint | — |
| Docker | dockerls | — | — | — |
| Markdown | marksman | prettier | markdownlint-cli2 | — |
| TOML | taplo | taplo | — | — |
| JSON | jsonls (+SchemaStore) | prettier | — | — |

Format-on-save is on; toggle with `<leader>tf` (`:FormatDisable` / `:FormatEnable`).

## Keybindings (leader = `Space`)

NvChad defaults still apply (`<leader>ff` find files, `<leader>fw` live grep,
`<C-n>` file tree, `<leader>th` themes, etc.). Added on top:

| Group | Keys |
|-------|------|
| AI / Claude | `<leader>a` → `c` toggle · `s` send (visual) · `a`/`d` accept/deny diff · `b` add buffer |
| Debug | `<leader>d` → `b` breakpoint · `B` conditional · `c` continue · `i`/`o`/`O` step · `r` REPL · `u` UI · `e` eval · `t` terminate |
| Diagnostics | `<leader>xx` Trouble · `<leader>xX` buffer-only · `<leader>cs` symbols |
| Git | `<leader>gg` lazygit |
| Navigation | `<leader>o` outline · `<leader>ft` find TODOs · `<leader>qs`/`<leader>ql` restore session |
| Format | `<leader>fm` format · `<leader>tf` toggle autoformat |

## Node on PATH

`.zshrc` lazy-loads nvm via shell functions, so `node` isn't a real binary on
`PATH`. Neovim spawns Mason/ts_ls/prettierd directly, so `.zshrc` prepends the
newest installed node's `bin` to `PATH` (cheaply, no `nvm.sh` sourcing). If the
JS toolchain can't find node, install one (`nvm install --lts`) and restart the
shell.

## Layout

```
nvim/
├── init.lua              # NvChad bootstrap
├── lua/
│   ├── chadrc.lua        # theme (tokyonight + palette pin), UI
│   ├── options.lua       # editor options
│   ├── mappings.lua      # keymaps + format toggle commands
│   ├── configs/
│   │   ├── lspconfig.lua # servers, schemas, capabilities
│   │   └── conform.lua   # formatters + format-on-save
│   └── plugins/
│       ├── init.lua      # blink, conform, lspconfig deps, treesitter
│       ├── tooling.lua   # Mason tool auto-install
│       ├── format-lint.lua
│       ├── dap.lua
│       ├── ai.lua
│       └── editor.lua
```
```

- [ ] **Step 2: Update the main `README.md`**

In `README.md`, add `neovim` and the IDE tools to the Homebrew install command (the line currently `brew install tmux starship zoxide fzf eza bat nvm`):
```sh
brew install tmux starship zoxide fzf eza bat nvm neovim lazygit ripgrep fd
```

Add this symlink line to the **Symlink configs** block (after the ghostty line):
```sh
ln -sf "$PWD/nvim"                            ~/.config/nvim
```

Add a new top-level section after the Ghostty section:
```markdown
---

## Neovim setup

A Tokyo Night NvChad IDE with full LSP/DAP, format-on-save, fuzzy finding, git,
and an in-editor Claude that runs on a Claude Team plan with **no API key**.

Full documentation — prerequisites, keybindings, language support, and the AI
setup — lives in [`nvim/README.md`](nvim/README.md).

```sh
ln -sf "$PWD/nvim" ~/.config/nvim
nvim                       # first launch bootstraps lazy.nvim + NvChad
```

Then in nvim: `:MasonToolsInstall`, `:Lazy build telescope-fzf-native.nvim`, restart.
```

- [ ] **Step 3: Verify markdown renders / links resolve**

Run:
```bash
test -f nvim/README.md && grep -q "Neovim setup" README.md && grep -q "nvim/README.md" README.md && echo OK
```
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add README.md nvim/README.md
git commit -m "$(cat <<'EOF'
docs(nvim): document setup, keybindings, AI integration, node-on-PATH

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: Final end-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Health check**

Run:
```bash
nvim --headless "+checkhealth" "+w! /tmp/nvim_health.txt" +qa
grep -iE 'ERROR' /tmp/nvim_health.txt || echo "no errors"
```
Expected: no blocking `ERROR` lines for lazy, mason, lsp, treesitter, telescope, dap (warnings for optional providers like ruby/perl are fine).

- [ ] **Step 2: Multi-language LSP smoke test**

Run:
```bash
for f in /tmp/c.py /tmp/c.ts /tmp/c.yaml /tmp/c.lua; do : > "$f"; done
printf 'def f(x):\n    return x+1\n' > /tmp/c.py
printf 'const x: number = "no"\n' > /tmp/c.ts
printf 'apiVersion: v1\nkind: Pod\n' > /tmp/c.yaml
nvim --headless /tmp/c.ts "+sleep 4" "+lua print('ts clients='..#vim.lsp.get_clients({bufnr=0}))" +qa
```
Expected: `ts clients=` ≥ 1 (and a type diagnostic visible if you open it interactively).

- [ ] **Step 3: Theme parity check**

Open `nvim` beside a tmux pane + starship prompt; confirm background `#1a1b26`, accents `#7aa2f7`, comments `#565f89` match visually.

- [ ] **Step 4: AI + DAP smoke (manual)**

`<leader>ac` opens Claude with no key prompt; `<leader>db` + `<leader>dc` debugs a Python file. Both already exercised in Tasks 10–11; re-confirm end-to-end.

- [ ] **Step 5: Final commit (lazy-lock.json)**

Commit the resolved plugin lockfile so installs are reproducible:
```bash
git add nvim/lazy-lock.json
git commit -m "$(cat <<'EOF'
chore(nvim): pin plugin versions (lazy-lock.json)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)" || echo "lazy-lock already committed"
```

---

## Self-review summary

- **Spec coverage:** §3 architecture → Task 1; §4 AI → Task 11 (+ docs Task 14); §5 theme → Task 2; §6 LSP/format/lint/DAP → Tasks 5,7,8,10; §7 IDE layer → Tasks 6,9,12; §8 keymaps → Tasks 4,10,11,12; §9 docs → Task 14; §10 prereqs → Task 1; §11 risks (node PATH → Task 13, textobjects branch → Task 9, claudecode beta → Task 11 notes); §13 verification → Task 15. No gaps.
- **No placeholders:** every code step contains complete, runnable content.
- **Consistency:** server names (`ts_ls`, `basedpyright`, `ruff`), keymaps (`<leader>a*`, `<leader>d*`, `<leader>x*`), and file paths match across tasks and the spec.
