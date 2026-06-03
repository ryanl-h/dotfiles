# dotfiles

Terminal setup for macOS — zsh + tmux + Neovim with a Tokyo Night-flavoured status bar.

## Prerequisites

### Fonts

Install [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads) — required for icons in the tmux status bar and `eza` output:

```sh
brew install --cask font-fira-code-nerd-font
```

Without this font, icons will render as boxes or question marks.

### Homebrew tools

Install [Homebrew](https://brew.sh), then the required tools:

```sh
brew install tmux starship zoxide fzf eza bat nvm neovim lazygit ripgrep fd tree-sitter-cli
```

Install `kubectl` if you use the Kubernetes aliases:

```sh
brew install kubectl
```

## Symlink configs

From the root of this repo:

```sh
ln -sf "$PWD/.zshrc"                          ~/.zshrc
ln -sf "$PWD/.tmux.conf"                      ~/.tmux.conf
ln -sf "$PWD/starship.toml"                   ~/.config/starship.toml
mkdir -p ~/.config/ghostty
ln -sf "$PWD/ghostty/config"                  ~/.config/ghostty/config
ln -sf "$PWD/nvim"                            ~/.config/nvim
```

---

## zsh setup

### Install Zinit

```sh
bash -c "$(curl --fail --show-error --silent --location \
  https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
```

Restart your shell — Zinit will automatically install the plugins declared in `.zshrc` on first load:

- `zsh-autosuggestions` — inline command suggestions
- `fzf-tab` — fzf-powered tab completion
- `fast-syntax-highlighting` — command colouring

### fzf shell integration

```sh
$(brew --prefix)/opt/fzf/install
```

### Starship prompt

The prompt is initialised via `eval "$(starship init zsh)"`. Starship uses `~/.config/starship.toml` for configuration — see [starship.rs/config](https://starship.rs/config/) for options.

### Tools used by aliases

| Alias | Tool | Install |
|-------|------|---------|
| `ls` / `ll` | [eza](https://eza.rocks) | `brew install eza` |
| `cat` | [bat](https://github.com/sharkdp/bat) | `brew install bat` |
| `z` | [zoxide](https://github.com/ajeetdsouza/zoxide) | `brew install zoxide` |

### Shell behaviour

- **Unlimited history** — `HISTSIZE` / `SAVEHIST` set to 1B, shared across concurrent sessions, with timestamps.
- **Up-arrow prefix search** — type the start of a previous command, press ↑ to cycle matches.
- **`AUTO_CD`** — type a directory name to `cd` into it; `cd -<TAB>` jumps through the dir stack.
- **Lazy nvm** — `nvm`/`node`/`npm`/`npx` source `nvm.sh` on first use, saving ~200ms per shell start.
- **Case-insensitive completion** with a selectable menu.

---

## tmux setup

### Install TPM (Tmux Plugin Manager)

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Install plugins

Start a tmux session, then press:

```
Ctrl-a  I
```

TPM will install:

| Plugin | Purpose |
|--------|---------|
| `tmux-sensible` | Sane default settings |
| `tmux-resurrect` | Save and restore sessions across restarts |
| `tmux-continuum` | Auto-save sessions every 15 minutes; auto-restores on tmux start (`@continuum-restore on`) |

Other tweaks: truecolor enabled via `terminal-overrides`, `focus-events on` for editor integration, and `mode-keys vi` so copy mode uses vi keys to match the vim-style pane bindings below.

---

## Ghostty setup

Config is at `ghostty/config` and sets the font to FiraCode Nerd Font Mono at size 13. Symlink it as shown in the [Symlink configs](#symlink-configs) section above, then restart Ghostty.

---

### Key bindings

| Binding | Action |
|---------|--------|
| `Ctrl-a` | Prefix (replaces default `Ctrl-b`) |
| `prefix \|` | Split pane horizontally |
| `prefix -` | Split pane vertically |
| `prefix h/j/k/l` | Move between panes (vim-style) |
| `prefix r` | Reload tmux config |

---

## Neovim setup

A Tokyo Night [NvChad](https://nvchad.com) IDE with full LSP/DAP, format-on-save,
fuzzy finding, git, and an in-editor Claude that runs on a Claude Team plan with
**no API key**.

Full documentation — prerequisites, keybindings, language support, and the AI
setup — lives in [`nvim/README.md`](nvim/README.md).

```sh
ln -sf "$PWD/nvim" ~/.config/nvim
nvim                       # first launch bootstraps lazy.nvim + NvChad
```

Then in nvim: `:MasonToolsInstall`, `:TSInstallAll`, `:Lazy build telescope-fzf-native.nvim`, restart.

> Note: `node` must be a real binary on `PATH` for the JS toolchain (`.zshrc` handles this — see [Shell behaviour](#shell-behaviour)). nvim spawns those tools directly, not through the shell.

### Key bindings

Leader is `Space`. NvChad defaults apply (`<leader>ff` find files, `<leader>fw` live grep, `<C-n>` file tree, `<leader>th` themes). Added on top:

| Binding | Action |
|---------|--------|
| `<leader>ac` | Toggle in-editor Claude (Team plan, no API key) |
| `<leader>as` | Send visual selection to Claude |
| `<leader>aa` / `<leader>ad` | Accept / reject Claude's proposed diff |
| `<leader>gg` | LazyGit |
| `<leader>fm` / `<leader>tf` | Format buffer / toggle format-on-save |
| `<leader>db` / `<leader>dc` | DAP breakpoint / continue (debug) |
| `<leader>du` / `<leader>de` | DAP toggle UI / eval |
| `<leader>xx` | Diagnostics panel (Trouble) |
| `<leader>o` | Symbol outline (Aerial) |
| `<leader>ft` | Find TODOs |
| `af`/`if` · `ac`/`ic` · `aa`/`ia` | Text objects: function · class · argument |

Format-on-save is on by default (ruff/prettierd/stylua/shfmt/…); `<leader>tf` disables it per session. Full reference — language support, the AI setup, and the file layout — is in [`nvim/README.md`](nvim/README.md).
