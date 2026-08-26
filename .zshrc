export PATH="$HOME/.local/bin:$PATH"

# Unity CLI
. "/Users/christian/.unity/env"

#------Aliases

alias cd="z"
alias ls="eza -l --icons=always --no-symlinks -h --no-permissions --no-user --color=always"
alias cat="bat"
alias top="btop"
alias disk="dua i"


#------Terminal tools
eval "$(zoxide init zsh)"

eval "$(starship init zsh)"

#------ZSH Plugins
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

#------Inkwell
# Open file(s) in Inkwell via LaunchServices — the same route Finder uses.
# `inkwell tab open` is vault-scoped and rejects outside paths with
# "Path is outside vault boundary"; `open` has no such restriction.
# It also resolves paths against $PWD and errors on missing files.
ink() {
  if (( $# == 0 )); then
    print -u2 "usage: ink <file> [file ...]"
    return 1
  fi
  open -a Inkwell "$@"
}
