# dotfiles

Terminal setup for macOS — zsh + tmux with a Tokyo Night-flavoured status bar.

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
brew install tmux starship zoxide fzf eza bat nvm
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
- `fast-syntax-highlighting` + `zsh-syntax-highlighting` — command colouring

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
| `tmux-continuum` | Auto-save sessions every 15 minutes |

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
