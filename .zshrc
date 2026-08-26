
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