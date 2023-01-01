#!/bin/bash
source helpers

load_options $@

log info "starting authentication"

if [[ ${options[skip-ssh]} != true ]]; then
   log info "creating github ssh auth"

   check_existing_ssh_key
   existing_ssh=$?

   if [[ $existing_ssh -ne 0 ]]; then
      log ask "input your email:"

      if [[ -z $user_email ]]; then
         log ask "input your email:"
         read user_email
         echo
      fi

      ssh-keygen -t ed25519 -C $user_email -f $HOME/.ssh/id_ed25519 -q -N ""
   fi

   log info "there is your ssh key: $GREEN$(cat $HOME/.ssh/id_ed25519.pub)$RESET copy and paste on $GREEN\https://github.com/settings/ssh/new$RESET"
else
   log info "github ssh auth skipping"
fi

if [[ ${options[skip-npm-token]} != true ]]; then
   log info "creating npm token auth"
   log ask "generate a new token in $GREEN\\https://github.com/settings/tokens/new$RESET"

   if [[ -z $user_email ]]; then
      log ask "input your email:"
      read user_email
      echo
   fi

   log ask "input your username:"
   read user_name
   echo

   log ask "input your generated password:"
   read inputed_password
   echo

   npx npm-cli-login -u $user_name -p inputed_password -e $user_email
else
   log info "npm token auth skipping"
fi
