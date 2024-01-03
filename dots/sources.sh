# ---BEGIN DOTFILES SOURCE---
source /usr/bin/peam-commands
source $HOME/.asdf/asdf.sh
source $HOME/.asdf/completions/asdf.bash

eval "$(zoxide init bash)"
shopt -s autocd;

export HISTSIZE=
export HISTFILESIZE=

# if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#    tmux attach -t default || tmux new -s default
# fi

DEFAULT_PS1="\[\e]0;@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]"

function format_time_diff {
   if [[ $1 -lt 3 ]]; then
      echo ""
      return 0
   fi

   if [[ $1 -lt 60 ]]; then
      echo "${1}s"
      return 0
   fi

   if [[ $1 -lt 3600 ]]; then
      minutes=$(( $1 / 60 ))
      seconds=$(( $1 % 60 ))
      echo "${minutes}m${seconds}s"
      return 0
   fi

   hours=$(( $1 / 3600 ))
   minutes=$(( ($1 % 3600) / 60 ))
   seconds=$(( $1 % 60 ))
   echo "${hours}h${minutes}m${seconds}s"
}

function __before_command {
   if [[ $BASH_COMMAND != *"__after_command"* && $BASH_COMMAND != *"_zoxide_hook"* ]]; then
      first_command=$(date +%s)
   fi
}

function __after_command {
   ran_time=""
   local EXIT_CODE="$?"
   PS1=""

   if [ $EXIT_CODE != 0 ]; then
      PS1+="${RED}\u${RESET}"
   else
      PS1+="${RAW_GREEN}\u${RESET}"
   fi

   if ! [ -z $first_command ]; then
      current_command=$(date +%s)
      time_diff=$(( current_command - first_command ))
      formatted_time=$(format_time_diff $time_diff)
      first_command=
   fi

   if [ -n "$formatted_time" ]; then
      ran_time="${YELLOW}took ${formatted_time} ${RESET}"
      formatted_time=
   fi

   PS1+="$DEFAULT_PS1 \$(git_style $(git branch --show-current)) $ran_time❯ "
}

trap '__before_command' DEBUG
PROMPT_COMMAND=__after_command
# ---END DOTFILES SOURCE---
