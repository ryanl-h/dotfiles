
. "$HOME/.local/bin/env"

zmodload zsh/mapfile

# Enable zsh completion
autoload -Uz compinit
compinit

# Zinit
source ~/.local/share/zinit/zinit.git/zinit.zsh

# Fast plugin loading
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-syntax-highlighting

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# fzf integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# git
alias g="git"
alias gs="git status"
alias gc="git commit"
alias gp="git push"

# kubernetes
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"

# python
alias py="python3.14"
alias venv="python3.14 -m venv .venv"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk


alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias cat="bat"

export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh
export KUBECONFIG=~/.kube/config

export PATH="/opt/homebrew/bin:$PATH"

DISABLE_AUTO_TITLE="true"

# Added by Antigravity
export PATH="/Users/ryan/.antigravity/antigravity/bin:$PATH"

# opencode
export PATH=/Users/ryan/.opencode/bin:$PATH
