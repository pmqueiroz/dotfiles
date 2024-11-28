#!/usr/bin/env bash

shopt -s expand_aliases

alias glo='git log --oneline'
alias repo='gh repo view --web'
alias debug='gum log -s -t kitchen -l debug'
alias gum_log='gum log -t kitchen -l'

function pr {
   gh pr view --json number -q '.number' &> /dev/null

   if [ $? -ne 0 ]; then
      title=$(commit_title $(git branch --show-current))
      gh pr create --assignee @me --title "$title" --web "$@"
      return 
   fi

   gh pr view --web
}

function commit_title {
   echo "$1" | awk '{gsub("/",": "); print}' | awk '{gsub("-"," "); print}'
}

function git_style {
  gum style "$(gum style --foreground "#f14e32" '') $(gum style --bold --underline --foreground "#f14e32" "$@")"
}

function fpush {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      gum_log error "not a git repository"
      return 128
   fi

   branch=$(git branch --show-current)
   gum_log info "pushing and setting upstream to $(git_style "$branch")"

   git push "$1" --set-upstream origin "$branch" "$2"
}

function commit {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      gum_log error "not a git repository"
      return 128
   fi
   declare -a commit_options;
   declare -a inputted_message;

   for arg in "$@"; do
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
      commitmsg=$(commit_title "$(git branch --show-current)")
   else
      commitmsg="$inputted_message"
   fi

   gum_log info "commiting files with message $(git_style "$commitmsg")"

   gum style --foreground 12 --margin "0 1" -- "$(git diff --name-only --cached)"

   gum confirm "confirm?" && git commit -m "${commitmsg}" "${commit_options[@]}" || {
      gum_log error exiting...
      git reset
   }
}

function get_branch_by_number {
    local pr_number=$1
    local repo_name
    local branch_name

    repo_name=$(gh repo view --json name --jq '.name')
    branch_name=$(gh pr view "$pr_number" --json headRefName --repo "$repo_name" --jq '.headRefName')

    if [ $? -ne 0 ]; then
        echo "Error retrieving branch name for PR #$pr_number"
        return 1
    fi

    echo "$branch_name"
}

function checkout {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      gum_log error "not a git repository"
      return 128
   fi

   current_branch=$(git branch --show-current)

   if test -z "$1"; then
      branch_to_checkout=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
   else
      if [[ $1 =~ ^[0-9]+$ ]]; then
         branch_by_number=$(get_branch_by_number "$1")

         if [ $? -ne 0 ]; then
            return 1
         fi

         branch_to_checkout="$branch_by_number"
      else
         branch_to_checkout="$1"
      fi
   fi

   if [ "$current_branch" != "$branch_to_checkout" ]; then
      gum_log info "checking out to $(git_style "$branch_to_checkout")"
      git checkout --quiet "$branch_to_checkout"
   fi

   gum_log info 'updating branch'

   git pull --rebase --quiet

   local_branchs=$(git for-each-ref --format='%(refname:short)' refs/heads/ | sed /^"$branch_to_checkout"\$/d)

   if test -n "$local_branchs"; then
      gum_log info 'deleting other branches. was:'
      for branch in "${local_branchs[@]}"; do 
         git_style "$branch"
      done

      echo "$local_branchs" | xargs git branch -q -D
   fi
}

function run_node {
   tmp_file=$(mktemp --suffix=.js)
   code "$tmp_file" --wait
   file_content=$(cat "${tmp_file}")
   node -p -e "${file_content}"
   rm -rf "$tmp_file"
}

function checksum {
   md5sum "$1" | awk '{ print $1 }'
}

function hot {
  if (( $# < 2 )); then
   gum_log error 'USAGE: hot <command> <file1> [<file2> ... <fileN>]'
  else
   script=$1
   shift
   a='';

   while true; do
      b=$(ls -l "$*")
      [[ $a != $b ]] && a=$b && eval "$script";
      sleep .5;
   done
  fi
}
