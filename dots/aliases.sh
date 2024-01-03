#!/bin/bash

RAW_GREEN="\[\e[0;32m\]"
GREEN="\u001b[32m"
MAGENTA="\u001b[35m"
CYAN="\u001b[36m"
YELLOW="\033[33m"
ORANGE="\e[38;2;255;165;0m"
RED="\033[0;31m"
BLUE="\[\e[1;34m\]"
RESET="\033[0m"

alias glo='git log --oneline'
alias repo='gh repo view --web'
alias debug='gum log -s -t kitchen -l debug'
alias log='gum log -t kitchen -l'

function pr {
   gh pr view --json number -q '.number' &> /dev/null

   if [ $? -ne 0 ]; then
      title=$(commit_title $(git branch --show-current))
      gh pr create --assignee @me --title "$title" --web $@
      return 
   fi

   gh pr view --web
}

function commit_title {
   echo $1 | awk '{gsub("/",": "); print}' | awk '{gsub("-"," "); print}'
}

function git_style {
  gum style "$(gum style --foreground "#f14e32" '') $(gum style --bold --underline --foreground "#f14e32" "$@")"
}

function fpush {
   branch=`git branch --show-current`
   log info "pushing and setting upstream to $(git_style $branch)"

   git push $1 --set-upstream origin $branch $2
}

function commit {
   declare -a commit_options;
   declare -a inputted_message;

   for arg in $@; do
      if [[ $arg == -* ]]; then
         commit_options+=( "$arg" )
      else
         inputted_message+=( "$arg" )
      fi
      shift
   done

   inputted_message="${inputted_message[@]}"

   git add .

   if test -z "$inputted_message"
   then
      commitmsg=`commit_title $(git branch --show-current)`
   else
      commitmsg="$inputted_message"
   fi

   log info "commiting files with message $(git_style "$commitmsg")"

   gum style --foreground 12 --margin "0 1" -- "$(git diff --name-only --cached)"

   gum confirm "confirm?" && git commit -m "${commitmsg}" ${commit_options[@]} || {
      log error exiting...
      git reset
   }
}

function checkout {
   current_branch=$(git branch --show-current)

   if test -z "$1"; then
      branch_to_checkout=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
   else
      branch_to_checkout="$1"
   fi

   if [ $current_branch != $branch_to_checkout ]; then
      log info "checking out to $(git_style $branch_to_checkout)"
      git checkout --quiet $branch_to_checkout
   fi

   log info 'updating branch'

   git pull --rebase --quiet

   local_branchs=$(git for-each-ref --format='%(refname:short)' refs/heads/ | sed s/$branch_to_checkout// )

   if test -n "$local_branchs"; then
      log info 'deleting other branches. was:'
      for branch in ${local_branchs[@]}; do 
         git_style $branch
      done

      echo $local_branchs | xargs git branch -q -D
   fi
}

function run_node {
   tmp_file=$(mktemp --suffix=.js)
   code $tmp_file --wait
   file_content=$(cat ${tmp_file})
   node -p -e "${file_content}"
   rm -rf $tmp_file
}

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

function git_branch {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
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

   PS1+="$DEFAULT_PS1 \$(git_branch) $ran_time❯ "
}

trap '__before_command' DEBUG
PROMPT_COMMAND=__after_command
