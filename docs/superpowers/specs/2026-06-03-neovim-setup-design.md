# Neovim Setup — Design Spec

**Date:** 2026-06-03
**Status:** Approved, pending implementation plan
**Repo:** `dotfiles` (macOS terminal setup — zsh + tmux + ghostty + starship)

## 1. Goal

Add an "amazing", well-documented Neovim configuration to the dotfiles repo, matching
the repo's established ethos:

- Hand-curated config with **`why`-comments** at the density of `.zshrc` / `.tmux.conf`.
- **Tokyo Night** palette, identical to the existing tmux status bar and starship prompt.
- macOS / Homebrew install path, documented with prerequisite tables and step-by-step setup
  (the bar set by the existing `README.md`).
- Performance-conscious, modular, and understandable.

A full **IDE experience** built on the **NvChad** distribution, with first-class support for
Python, JS/TS + web, and the ops/docs surface (Bash, YAML/K8s, Docker, Markdown, TOML, Lua),
plus an in-editor Claude integration that works on a **Claude Team plan with no API key**.

## 2. Decisions locked during brainstorming

| Decision | Choice | Rationale |
|---|---|---|
| Foundation | **NvChad 2.5** (starter model) | User choice; fastest startup, gorgeous built-in UI, base46 Tokyo Night. |
| Scope | **Full IDE** (incl. DAP debugging) | User choice. |
| Languages | Python, JS/TS+web, Bash/YAML/K8s/Markdown, **+ Lua** | User choice; Lua added because it's required to edit the config itself. |
| In-editor AI | **`coder/claudecode.nvim`** | Only path that uses the Team subscription with no API key (see §4). |
| Completion | **blink.cmp** (NvChad opt-in) | Faster than nvim-cmp; NvChad ships first-class config; stable at 1.*. |
| TypeScript LSP | **ts_ls** | Zero-config default; `vtsls` only if monorepo perf becomes an issue. |
| Git porcelain | **`Snacks.lazygit()`** | snacks.nvim is already pulled in by claudecode.nvim; auto-themes lazygit to the colorscheme for free. |
| Theme | **tokyonight** (base46), palette-pinned | Closest 1:1 port; reconciled to exact repo hexes via `hl_override`. |

## 3. Architecture

NvChad 2.5 uses the **"starter" model**: the user config is an ordinary Lua project, and
NvChad itself is loaded *as a plugin* by lazy.nvim. Verified against
`NvChad/starter@main`, `NvChad/NvChad@v2.5`, `NvChad/ui@v3.0`, `NvChad/base46@v3.0`.

The starter files are **vendored into a `nvim/` directory in this repo** and symlinked into
place — matching how every other config here is handled. Plugins themselves install to
`~/.local/share/nvim` on first launch (the same data-dir pattern as TPM, zinit, and lazy
already used in this repo). **Requires Neovim 0.11+** (uses `vim.uv`, `vim.lsp.enable`).

### Symlink

```sh
ln -sf "$PWD/nvim" ~/.config/nvim
```

### File layout

```
nvim/
├── init.lua                   # NvChad bootstrap: base46 cache, lazy clone, mapleader=" "
├── lua/
│   ├── chadrc.lua             # M.base46 = tokyonight + hl_override palette pin; M.ui
│   ├── options.lua            # require "nvchad.options" + vim.o overrides
│   ├── mappings.lua           # require "nvchad.mappings" + added keymaps (AI, DAP, trouble…)
│   ├── configs/
│   │   ├── lazy.lua           # lazy.nvim opts (kept from starter)
│   │   ├── lspconfig.lua      # require("nvchad.configs.lspconfig").defaults() + vim.lsp.enable(servers)
│   │   └── conform.lua        # formatters_by_ft + format-on-save toggle
│   └── plugins/
│       ├── init.lua           # blink.cmp import; conform spec override (event=BufWritePre)
│       ├── lsp.lua            # mason-lspconfig (ensure_installed, automatic_enable) + SchemaStore
│       ├── format-lint.lua    # nvim-lint + mason-tool-installer
│       ├── dap.lua            # nvim-dap stack (anchor spec with all deps)
│       ├── ai.lua             # coder/claudecode.nvim
│       └── editor.lua         # trouble, todo-comments, aerial, telescope ext, persistence, snacks/lazygit, textobjects
├── README.md                  # full nvim docs (see §9)
```

> Files under `lua/plugins/` are auto-imported by `{ import = "plugins" }`; each returns a
> lazy.nvim spec table. To override an NvChad default plugin, re-declare it by the same repo
> name (table `opts` deep-merge; function `opts` replaces).

## 4. AI integration (the load-bearing requirement)

**Constraint:** the user has a Claude **Team plan and no `ANTHROPIC_API_KEY`** (verified on
this machine: `claude` v2.1.161 at `~/.local/bin/claude`, no Anthropic env vars set).

### Primary: `coder/claudecode.nvim`

A pure-Lua implementation of Claude Code's IDE extension protocol (MCP over a localhost
WebSocket — the same protocol the official VS Code/JetBrains extensions use). The plugin
**never touches Anthropic auth**: it stands up a local WebSocket server, writes
`~/.claude/ide/<port>.lock` with a random-UUID `authToken`, and the **interactive `claude`
CLI** (already logged into the Team plan) connects back and validates via the
`x-claude-code-ide-authorization` header. All model traffic rides the official CLI.

**Why this is the right answer (adversarially verified):**

- **No API key. Uses the Team subscription.** Because it drives the *interactive* CLI, it
  stays on the regular **interactive usage pool** — **unaffected** by Anthropic's June 15 2026
  change that moves Agent-SDK / `claude -p` usage to a separate metered credit pool.
- **Editor-aware**, not just a terminal: send a visual selection, add files/buffers to
  context, view Claude's proposed edits as **native nvim diffs**, accept/reject.

**Setup** (`lua/plugins/ai.lua`):

```lua
{
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>",          desc = "Toggle Claude" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Reject Claude diff" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",      desc = "Add current buffer to context" },
  },
}
```

**Caveats to honor (from verification):**

- Status is **beta**; the latest *tagged* release (v0.3.0, 2025-09-16) lags active commits
  (pushed 2026-06-02). **Pin to a recent commit** for newest fixes, accepting beta risk.
- **macOS:** open issue #161 — `Cmd-V` paste of large content into the Claude terminal
  truncates (right-click paste works) on Neovim < 0.12.2. Document the workaround.
- **Do NOT set `ANTHROPIC_API_KEY`** — it takes precedence over subscription OAuth and would
  switch to (possibly empty) API billing. Document this prominently.
- Requires Neovim ≥ 0.8 (we're on 0.11+) and the `claude` CLI on PATH (present).

### Documented-but-disabled alternative: CodeCompanion + `claude_code` ACP adapter

A structured chat buffer with slash commands and diffs. Also works **with no API key** (via
`claude setup-token` → `CLAUDE_CODE_OAUTH_TOKEN`), but:

- As of **June 15 2026** it draws from the **separate metered Agent-SDK credit pool**, *not*
  the interactive subscription limits.
- Needs the npm bridge **`@agentclientprotocol/claude-agent-acp`** (the older
  `@zed-industries/claude-code-acp` is **deprecated/renamed** — use the new name) + Node.
- CodeCompanion's *native* `anthropic` adapter requires an API key — only the **ACP** route
  is subscription-friendly.

This will be documented in `nvim/README.md` as an opt-in, commented-out path, not enabled by
default.

### Excluded: Avante `auth_type='max'`

Avante's subscription path reverse-engineers the OAuth token with a spoofed user-agent — this
is exactly the route Anthropic blocked under the "OpenClaw ban" (Feb 2026 ToS, enforced
April 4 2026). **Not used.**

## 5. Theme — Tokyo Night, palette-matched

`lua/chadrc.lua`:

```lua
M.base46 = {
  theme = "tokyonight",                       -- built into base46, no extra plugin
  theme_toggle = { "tokyonight", "one_light" },
  transparency = false,                       -- TN's bg is part of its identity
  hl_override = { ... },                       -- pin chrome to exact repo hexes
}
```

NvChad's base46 `tokyonight` skews slightly redder than upstream, so `hl_override` / `hl_add`
will pin the editor chrome to the **exact tmux/starship hexes** so nvim, tmux, and starship are
visually identical:

| Role | Hex |
|---|---|
| Background | `#1a1b26` |
| Accent (blue) | `#7aa2f7` |
| Muted / comment | `#565f89` |
| Selection / visual | `#3b4261` |
| Foreground | `#c0caf5` |

Live theme hot-reload via `<leader>th` (NvChad theme picker). FiraCode Nerd Font (already
installed per the repo README) supplies icons. `tokyodark` is a darker alternative, trivially
swappable at runtime.

## 6. Language support

Native Neovim 0.11 LSP API: `require("nvchad.configs.lspconfig").defaults()` then
`vim.lsp.enable(servers)` in `lua/configs/lspconfig.lua`; per-server settings via
`vim.lsp.config(name, opts)`. Mason (`mason-org/*`, v2) auto-installs servers, formatters,
linters, and debug adapters. `mason-lspconfig` v2 uses `ensure_installed` + `automatic_enable`
(no `setup_handlers`).

| Language | LSP server | Format (conform) | Lint (nvim-lint) | Debug (DAP) |
|---|---|---|---|---|
| **Python** | `basedpyright` + `ruff` | `ruff_organize_imports`, `ruff_format` | via `ruff` LSP | `debugpy` |
| **JS/TS/JSX/TSX** | `ts_ls` | `prettierd`→`prettier` | `eslint` (LSP) | `js-debug` (`pwa-node`) |
| **HTML/CSS/JSON** | `html`, `cssls`, `jsonls` (+SchemaStore) | `prettierd`→`prettier` | — | — |
| **Tailwind** | `tailwindcss` | — | — | — |
| **Lua** | `lua_ls` | `stylua` | — | — |
| **Bash/sh** | `bashls` | `shfmt` | `shellcheck` | — |
| **YAML / K8s** | `yamlls` (+SchemaStore, k8s schema) | `yamlfmt` | `yamllint` | — |
| **Docker** | `dockerls` | — | — | — |
| **Markdown** | `marksman` | `prettier` | `markdownlint-cli2` | — |
| **TOML** | `taplo` | `taplo` | — | — |

**Server config notes (verified current):**

- **Python:** `basedpyright` for types/hover (set `disableOrganizeImports = true`,
  `diagnosticMode = "openFilesOnly"`); `ruff` LSP for diagnostics/code-actions; disable
  `ruff`'s hover (`client.server_capabilities.hoverProvider = false` on `LspAttach`) so
  basedpyright owns hover. **`ruff-lsp` is dead** — use the built-in `ruff server`.
- **TypeScript:** server name is **`ts_ls`** (renamed from `tsserver`). Mason package
  `typescript-language-server`.
- **Web:** `vscode-langservers-extracted` provides `cssls`/`html`/`jsonls`. Feed
  `require("schemastore").json.schemas()` to `jsonls`.
- **YAML:** `yamlls` with built-in store disabled
  (`settings.yaml.schemaStore = { enable = false, url = "" }`),
  `schemas = require("schemastore").yaml.schemas()`, plus a Kubernetes schema mapped to a
  manifest glob (e.g. `["kubernetes"] = { "k8s/**/*.yaml", "*.k8s.yaml" }`), and
  `keyOrdering = false`.
- **Lua:** `lua_ls` — NvChad's `defaults()` already configures the Neovim runtime/`vim`
  global; minimal extra config needed.

### Formatting & linting

- **conform.nvim** (ships with NvChad). Edit `lua/configs/conform.lua` to a full options
  table, enable `event = "BufWritePre"` on the spec, and use a **function-form
  `format_on_save`** guarded by `vim.g/vim.b.disable_autoformat`, with
  `:FormatDisable[!]` / `:FormatEnable` commands and a `<leader>tf` toggle. Use
  `lsp_format = "fallback"` (the old `lsp_fallback = true` is **deprecated**).
  Web/JSON/Markdown use `{ "prettierd", "prettier", stop_after_first = true }`.
- **nvim-lint** (added; NvChad doesn't ship it). Only for tools without a good LSP:
  `shellcheck`, `yamllint`, `markdownlint-cli2`. Triggered from a
  `BufWritePost`/`BufReadPost` autocmd via `try_lint()`. **Do not** double-lint Python/JS
  (already covered by `ruff`/`eslint` LSP).
- **mason-tool-installer.nvim** (added) declaratively installs the CLI tools: `stylua`,
  `ruff`, `prettierd`, `shfmt`, `shellcheck`, `yamlfmt`, `yamllint`, `markdownlint-cli2`,
  `taplo`.

### Debugging (DAP)

A single anchor `nvim-dap` spec in `lua/plugins/dap.lua` with all deps so load order is
correct:

- `mfussenegger/nvim-dap` (engine), `rcarriga/nvim-dap-ui` (**requires
  `nvim-neotest/nvim-nio`** — the #1 setup failure if omitted),
  `theHamsta/nvim-dap-virtual-text`, `jay-babu/mason-nvim-dap.nvim`,
  `mfussenegger/nvim-dap-python`.
- **Python:** point `dap-python.setup()` at the **Mason debugpy venv python**
  (`stdpath("data").."/mason/packages/debugpy/venv/bin/python"`), not the project venv, so it
  works everywhere; it still auto-detects the project venv for the debugged program.
- **JS/TS:** register the **`pwa-node` adapter directly** against the Mason-installed
  `js-debug-adapter/js-debug/src/dapDebugServer.js` (pass both `${port}` and `127.0.0.1`).
  **Do not** use the abandoned `mxsdev/nvim-dap-vscode-js` wrapper.
- Auto-open/close dap-ui via `dap.listeners` (`before.attach`/`before.launch` → open;
  `before.event_terminated`/`before.event_exited` → close), plus a `<leader>du` toggle.

## 7. Full-IDE quality-of-life layer

NvChad already ships: telescope, nvim-tree, treesitter, gitsigns, which-key, nvim-autopairs,
indent-blankline, nvim-colorizer, nvim-cmp (replaced by blink — see below). **Added only what's
missing:**

| Plugin | Repo | Purpose |
|---|---|---|
| blink.cmp | (NvChad import `nvchad.blink.lazyspec`) | Faster completion; disables nvim-cmp. |
| telescope-fzf-native | `nvim-telescope/telescope-fzf-native.nvim` | C sorter (needs `make`); wire into `M.telescope.extensions_list`. |
| telescope-ui-select | `nvim-telescope/telescope-ui-select.nvim` | Route `vim.ui.select` (code actions) through telescope. |
| trouble.nvim | `folke/trouble.nvim` | Diagnostics/symbols panel (the "Problems" tab). v3 subcommand API. |
| todo-comments.nvim | `folke/todo-comments.nvim` | TODO/FIX/HACK highlight + project search. |
| aerial.nvim | `stevearc/aerial.nvim` | Symbol outline (treesitter+LSP). |
| nvim-treesitter-textobjects | `nvim-treesitter/nvim-treesitter-textobjects` | Semantic text objects. **Version-sensitive — see §11.** |
| persistence.nvim | `folke/persistence.nvim` | Per-project session restore (manual, won't fight nvdash). |
| snacks.nvim (lazygit module) | `folke/snacks.nvim` | `Snacks.lazygit()` — auto-themed git TUI. Already a dep of claudecode.nvim. |

**Git:** use `Snacks.lazygit()` rather than a standalone wrapper, since snacks is already in the
tree via claudecode.nvim, and it auto-derives a Tokyo Night lazygit theme. Requires the
`lazygit` binary.

## 8. Keymaps

Leader = `<space>` (NvChad default). Added on top of NvChad defaults, chosen to avoid
collisions; the full set lives in the README cheatsheet.

| Group | Bindings |
|---|---|
| AI / Claude | `<leader>ac` toggle · `<leader>as` send selection (v) · `<leader>aa`/`<leader>ad` accept/deny diff · `<leader>ab` add buffer |
| Debug | `<leader>db` breakpoint · `<leader>dB` conditional · `<leader>dc` continue · `<leader>di`/`<leader>do`/`<leader>dO` step in/over/out · `<leader>dr` REPL · `<leader>du` UI toggle · `<leader>de` eval (n/v) · `<leader>dt` terminate |
| Diagnostics | `<leader>xx` Trouble diagnostics · `<leader>xX` buffer-only · `<leader>cs` symbols |
| Git | `<leader>gg` lazygit |
| Navigation | `<leader>o` outline · `<leader>ft` find TODOs · `<leader>qs` restore session |
| Formatting | `<leader>fm` format · `<leader>tf` toggle format-on-save |

## 9. Documentation plan

Matching the repo's documentation standard:

1. **Inline `why`-comments** in every Lua file at `.zshrc`/`.tmux.conf` density (e.g. *why*
   basedpyright's organizeImports is off, *why* the debugpy venv path, *why* `node` must be on
   PATH).
2. **`nvim/README.md`** — prerequisites table, install/symlink steps, the **no-API-key AI
   setup** explained (and the opt-in ACP path), language-support table, and a **keybinding
   cheatsheet** in the repo's table style.
3. **Main `README.md`** — a new *Neovim setup* section: `brew install neovim lazygit ripgrep
   fd`, the symlink line, and first-launch steps (`:MasonInstallAll` / lazy auto-sync,
   `:Lazy build telescope-fzf-native.nvim`).

## 10. Prerequisites & install

| Tool | Install | Why |
|---|---|---|
| Neovim 0.11+ | `brew install neovim` | Required (vim.uv, vim.lsp.enable). |
| lazygit | `brew install lazygit` | Git porcelain via Snacks. |
| ripgrep, fd | `brew install ripgrep fd` | Telescope live-grep / find-files. |
| C toolchain | Xcode CLT (`xcode-select --install`) | Build telescope-fzf-native. |
| Node | already via nvm | ts_ls, prettierd, js-debug, marksman. **See §11 PATH gotcha.** |
| `claude` CLI | already installed | AI integration (Team-plan auth). |
| FiraCode Nerd Font | already installed | Icons. |

Mason auto-installs all LSP servers, formatters, linters, and debug adapters on first launch.

## 11. Known risks / version-sensitive items

1. **Lazy-nvm PATH gotcha (must document):** `.zshrc` lazy-loads nvm via shell *functions*, so
   `node`/`npm` are **not real binaries on PATH**. Neovim spawns Mason/ts_ls/prettierd/js-debug
   directly (not through the shell), so they won't find `node`. Fix: set a default
   (`nvm alias default <version>`) and ensure that version's `bin` is on `PATH` non-lazily, or
   document the requirement clearly. This must be in `nvim/README.md`.
2. **`nvim-treesitter-textobjects` branch:** the new API lives on `branch=main`, but NvChad
   pins nvim-treesitter to a master-era revision. **Both must be on the same branch.** Verify
   NvChad's pinned treesitter branch (`:Lazy`) and either keep the legacy master-compatible
   config or move both to main together. This is the single most fragile item.
3. **claudecode.nvim is beta** — pin to a recent commit; expect occasional protocol churn (auth
   is unaffected since the CLI owns it). macOS large-paste bug (#161) workaround documented.
4. **Anthropic billing nuance** — interactive `claude` (claudecode.nvim) stays on the
   subscription pool; the ACP/CodeCompanion path moves to a separate metered Agent-SDK credit
   pool on June 15 2026. Documented so the user picks knowingly.

## 12. Non-goals (YAGNI)

- No Avante OAuth `max` hack (ToS-blocked).
- No `noice.nvim` (overlaps NvChad UI, experimental).
- No `neo-tree`/`neogit`/`lualine`/`bufferline`/`dressing` (NvChad already provides equivalents).
- No `null-ls`/`none-ls` (dead for this purpose).
- No unrelated refactoring of existing zsh/tmux/ghostty configs (beyond the documented `node`
  PATH note, which the nvim toolchain genuinely requires).

## 13. Verification

- `nvim --headless "+checkhealth" +qa` clean for the relevant providers.
- First-launch: lazy syncs, `:MasonInstallAll` completes, `:Lazy build` for fzf-native.
- Open a Python, a TS, a YAML (k8s), and a Lua file → LSP attaches, format-on-save works,
  diagnostics show.
- `<leader>ac` opens Claude using the Team plan with no API key; send-selection and diff
  accept/reject work.
- DAP: set a breakpoint and debug a Python file and a Node file.
- Theme matches the tmux/starship palette side by side.
