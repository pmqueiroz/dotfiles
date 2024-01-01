
#########################
# INSTALLED_BY_DOTFILES #
#########################
source /usr/bin/peam-commands
source $HOME/.asdf/asdf.sh
source $HOME/.asdf/completions/asdf.bash

eval "$(zoxide init bash)"
shopt -s autocd;

export HISTSIZE=
export HISTFILESIZE=

if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach -t default || tmux new -s default
fi
##########################
