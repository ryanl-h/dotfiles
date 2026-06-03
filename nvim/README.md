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
| tree-sitter CLI | `brew install tree-sitter-cli` | Compiles treesitter parsers (nvim-treesitter's main branch needs it). |
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

On first launch, wait for lazy to finish, then run:

- `:MasonToolsInstall` — install LSP servers, formatters, linters
- `:TSInstallAll` — compile the treesitter parsers (needs the `tree-sitter` CLI)
- `:Lazy build telescope-fzf-native.nvim` — compile the fuzzy sorter

Restart. Parsers install to `~/.local/share/nvim/site/parser/`.

## In-editor Claude (no API key)

`coder/claudecode.nvim` drives the **interactive `claude` CLI**, which is already
logged into your Team subscription. The plugin never touches Anthropic auth — it
just opens a local WebSocket the CLI connects to — so all usage stays on your
**interactive subscription pool**.

- **Do not set `ANTHROPIC_API_KEY`** — it overrides subscription auth and switches
  you to pay-as-you-go API billing.
- macOS: `Cmd-V` of large pastes into the Claude terminal could truncate on
  Neovim < 0.12.2 ([#161](https://github.com/coder/claudecode.nvim/issues/161));
  this setup targets ≥ 0.12.2, so it's a non-issue (right-click paste otherwise).

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
| Text objects | `af`/`if` function · `ac`/`ic` class · `aa`/`ia` argument · `]m`/`[m` next/prev function · `]]`/`[[` next/prev class |

## Node on PATH

`.zshrc` lazy-loads nvm via shell functions, so `node` isn't a real binary on
`PATH`. Neovim spawns Mason/ts_ls/prettierd directly, so `.zshrc` prepends the
newest installed node's `bin` to `PATH` (cheaply, no `nvm.sh` sourcing). If the
JS toolchain can't find node, install one (`nvm install --lts`), run
`nvm alias default <version>`, and restart the shell.

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
│       ├── init.lua      # blink, conform, lspconfig deps, treesitter (+textobjects)
│       ├── tooling.lua   # Mason tool auto-install
│       ├── format-lint.lua
│       ├── dap.lua
│       ├── ai.lua
│       └── editor.lua
```

> Treesitter runs on the `main`-branch nvim-treesitter API that NvChad v2.5
> targets; parsers install via NvChad's `:TSInstallAll` / FileType autocmd.
