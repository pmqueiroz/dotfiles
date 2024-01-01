#!/bin/bash
declare -A options;

function load_options() {
   for opt in $@; do 
      if [[ $opt == --* ]]; then
         options[${opt:2}]=true
      fi
   done
}

function has_installed_sources_before() {
   cat "$HOME/.bashrc" | grep -q "INSTALLED_BY_DOTFILES"
   return $?
}

function check_existing_ssh_key() {
   ls $HOME/.ssh | grep -q id_ed25519
   return $?
}

function render_string {
   local template=$(cat)
   while [ $# -gt 0 ]; do
      template=${template//\{\{$1\}\}/$2}
      shift 2
   done
   echo "$template"
}
