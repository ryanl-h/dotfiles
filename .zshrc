
. "$HOME/.local/bin/env"

zmodload zsh/mapfile

# History — effectively unlimited
HISTFILE=~/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
setopt EXTENDED_HISTORY        # save timestamps
setopt INC_APPEND_HISTORY      # append as commands run, not at shell exit
setopt SHARE_HISTORY           # share between concurrent sessions
setopt HIST_IGNORE_DUPS        # don't record an entry that duplicates the previous
setopt HIST_REDUCE_BLANKS      # strip superfluous whitespace before saving
setopt HIST_VERIFY             # don't auto-execute on history expansion (!!), edit first

# Directory navigation
setopt AUTO_CD                 # `mydir` instead of `cd mydir`
setopt AUTO_PUSHD              # `cd` pushes to the dir stack, use `cd -<TAB>` to jump back
setopt PUSHD_IGNORE_DUPS

# Dedupe PATH (and other arrays) so repeated sourcing doesn't bloat it
typeset -U path PATH

# Up/Down arrow: search history by current prefix (pairs well with infinite history)
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Completion: menu-select + case-insensitive matching
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Enable zsh completion
autoload -Uz compinit
compinit

# Zinit
source ~/.local/share/zinit/zinit.git/zinit.zsh

# Fast plugin loading
# Note: fast-syntax-highlighting supersedes zsh-syntax-highlighting — don't load both
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zdharma-continuum/fast-syntax-highlighting

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

# Lazy-load nvm — sourcing nvm.sh eagerly costs ~200ms per shell start
export NVM_DIR="$HOME/.nvm"
_nvm_lazy() {
    unset -f nvm node npm npx _nvm_lazy
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"
}
nvm()  { _nvm_lazy; nvm  "$@"; }
node() { _nvm_lazy; node "$@"; }
npm()  { _nvm_lazy; npm  "$@"; }
npx()  { _nvm_lazy; npx  "$@"; }
export KUBECONFIG=~/.kube/config

export PATH="/opt/homebrew/bin:$PATH"

DISABLE_AUTO_TITLE="true"

# Added by Antigravity
export PATH="/Users/ryan/.antigravity/antigravity/bin:$PATH"

# opencode
export PATH=/Users/ryan/.opencode/bin:$PATH
