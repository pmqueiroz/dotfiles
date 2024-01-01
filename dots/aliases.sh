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
alias pr='gh pr view --web'
alias repo='gh repo view --web'

declare -A log_levels_map=( 
   ["info"]="$CYAN"
   ["error"]="$RED"
   ["action"]="$MAGENTA"
   ["ask"]="$YELLOW"
   ["skip"]="$ORANGE"
)

function branch_name {
   echo $1 | awk '{gsub(": ","/"); print}' | awk '{gsub(" ", "-"); print}'
}

function commit_title {
   echo $1 | awk '{gsub("/",": "); print}' | awk '{gsub("-"," "); print}'
}

function upper {
   echo $1 | tr '[:lower:]' '[:upper:]'
}

function log {
   log_level=$1
   shift
   
   if [[ $QUIETABLE == true ]] && [[ ${options[quiet]} == true ]] && [[ $log_level != "error" ]]; then
      return 125 # operation canceled code
   fi

   display_level=$(upper $log_level)

   printf "${log_levels_map[$log_level]}[$display_level]$RESET $@"
   if [[ $log_level != "ask" ]]; then
      echo
   fi
}

function fpush {
   branch=`git branch --show-current`
   display_branch=$(upper $branch)
   log info "pushing and setting upstream to $GREEN${display_branch}$RESET"

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

   log info "commiting files\n"

   printf "$GREEN"
   git diff --name-only --cached
   printf "\n$RESET"


   if test -z "$inputted_message"
   then
      commitmsg=`commit_title $(git branch --show-current)`
   else
      commitmsg="$inputted_message"
   fi

   log info "with message$GREEN $commitmsg$RESET"

   log ask "please confirm [Y/n]"
   
   read -p "" -n 1 -r
   if [[ $REPLY =~ ^[Yy]$ ]]
   then
      git commit -m "${commitmsg}" ${commit_options[@]}
   else
      echo
      log error "exiting..."
      git reset
   fi
}

function checkout {
   current_branch=$(git branch --show-current)

   if test -z "$1"; then
      branch_to_checkout=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
   else
      branch_to_checkout="$1"
   fi

   if [ $current_branch != $branch_to_checkout ]; then
      git checkout $branch_to_checkout
   fi

   git pull --rebase --quiet

   local_branchs=$(git for-each-ref --format='%(refname:short)' refs/heads/ | sed s/$branch_to_checkout// )

   if test -n "$local_branchs"; then
      echo $local_branchs | xargs git branch -D
   fi
}

function git_branch {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function generate_card {
   RIGHT_BOTTOM_CORNER='───╯'
   RIGHT_TOP_CORNER='───╮'
   LEFT_BOTTOM_CORNER='╰───'
   LEFT_TOP_CORNER='╭───'
   SIDE_CHAR='│'
   LINE_CHAR='─'
   BLANK=' '
   MAX_LINE_WIDTH=45

   function fill_n_times {
      result=""
      i=1
      while [[ $i -le $1 ]]
      do
         result="$result$2"
         ((i = i + 1))
      done

      echo "${result}"
   }

   function padding {
      length=$1
      text=$2

      total_space=$(( $length - ${#text} ))
      remaining_side_length=$(( $total_space / 2 ))
      remaining_side_space=$(fill_n_times $remaining_side_length ${BLANK})

      final_text="$remaining_side_space${text}$remaining_side_space"

      remaining_length=$(( $length - ${#final_text} ))
      remaining_space=$(fill_n_times $remaining_length ${BLANK})
      side_spaces=$(fill_n_times 3 ${BLANK})

      echo "$side_spaces$final_text$side_spaces$remaining_space"
   }

   inputed_message=$@

   if test -z "$inputed_message"; then
      echo "no message provided"
      exit 1
   fi

   declare -a lines
   current_index=0

   for word in $inputed_message; do
      current_line=${lines[$current_index]}
      current_line_width=${#current_line}
      current_word_width=${#word}
      next_line="$current_line $word"

      if [[ ${#next_line} < $MAX_LINE_WIDTH ]]; then
         lines[$current_index]="$current_line$word "
      else
         ((current_index=current_index+1))
         lines[$current_index]="$word "
      fi
   done

   for line_index in ${!lines[@]}; do
      curr_line=${lines[$line_index]}
      trimmed_lime=$(echo $curr_line | sed 's/\s$//')
      lines[$line_index]=$trimmed_lime
   done

   higher_line_width=0

   for line_index in ${!lines[@]}; do
      line=${lines[$line_index]}

      if [[ ${#line} > $higher_line_width ]]; then
         higher_line_width=${#line}
      fi
   done

   headline="$LEFT_TOP_CORNER$(fill_n_times $higher_line_width $LINE_CHAR)$RIGHT_TOP_CORNER"
   tailline="$LEFT_BOTTOM_CORNER$(fill_n_times $higher_line_width $LINE_CHAR)$RIGHT_BOTTOM_CORNER"
   placeholder_line="$SIDE_CHAR$(padding $higher_line_width)$SIDE_CHAR"

   echo $headline
   echo $placeholder_line

   for line_index in ${!lines[@]}; do
      line=${lines[$line_index]}
      echo "$SIDE_CHAR$(padding $higher_line_width "$line")$SIDE_CHAR"
   done

   echo $placeholder_line
   echo $tailline
   echo " "
}

function log_card {
   log_level=$1
   shift

   CARD=$(generate_card "$1")

   printf "\n${log_levels_map[$log_level]}"
   printf "$CARD"
   printf "$RESET\n"
}

function run_node {
   tmp_file=$(mktemp --suffix=.js)
   code $tmp_file --wait
   file_content=$(cat ${tmp_file})
   node -p -e "${file_content}"
   rm -rf $tmp_file
}

function create_pr {
   title=$(commit_title $(git branch --show-current))

   gh pr create --assignee @me --title "$title" --web $@
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
