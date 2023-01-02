#!/bin/bash

GREEN="\u001b[32m"
MAGENTA="\u001b[35m"
CYAN="\u001b[36m"
YELLOW="\033[33m"
RESET="\033[0m"
RED="\033[0;31m"

declare -A options;

function load_options() {
   for opt in $@; do 
      if [[ $opt == --* ]]; then
         options[${opt:2}]=true
      fi
   done
}

function upper() {
   echo $1 | tr '[:lower:]' '[:upper:]'
}

function log() {
   declare -A levels=( ["info"]="$CYAN" ["error"]="$RED" ["action"]="$MAGENTA" ["ask"]="$YELLOW" )
   log_level=$1

   if [[ ${options[quiet]} == true ]] && [[ $log_level != "error" ]] ; then
      return 125 # operation canceled code
   fi

   display_level=$(upper $log_level)
   printf "${levels[$log_level]}[$display_level]$RESET ${@:2}\n\n"
}

function has_installed_sources_before() {
   cat "$HOME/.bashrc" | grep -q "INSTALLED_BY_DOTFILES"
   return $?
}

function check_existing_ssh_key() {
   ls $HOME/.ssh | grep -q id_ed25519
   return $?
}