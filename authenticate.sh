#!/bin/bash
source helpers.sh

load_options $@

log info "starting authentication"

log ask "input your email:"
read user_email
echo

log ask "input your username:"
read user_name
echo

if [[ ${options[skip-ssh]} != true ]]; then
   log info "creating github ssh auth"

   check_existing_ssh_key
   existing_ssh=$?

   if [[ $existing_ssh -ne 0 ]]; then
      ssh-keygen -t ed25519 -C $user_email -f $HOME/.ssh/id_ed25519 -q -N ""
   fi

   log info "there is your ssh key: $GREEN$(cat $HOME/.ssh/id_ed25519.pub)$RESET copy and paste on $GREEN\https://github.com/settings/ssh/new$RESET"
else
   log info "skipping github ssh auth"
fi

if [[ ${options[skip-npm-token]} != true ]]; then
   log info "creating npm token auth"
   log ask "generate a new token in $GREEN\\https://github.com/settings/tokens/new$RESET"

   log ask "input your generated password:"
   read inputed_password
   echo

   npx npm-cli-login -u $user_name -p inputed_password -e $user_email
else
   log info "skipping npm token auth"
fi

if [[ ${options[skip-git-configuring]} != true ]]; then
   log info "generating gpg key"

   gpg --full-generate-key

   generated_gpg=$(gpg --list-secret-keys --keyid-format=long | perl -lne 'print $1 if /sec\s+rsa4096\/([0-9A-Z]{16} )/')
   
   exported_gpg=$(gpg --armor --export $generated_gpg)

   log info "now you can add this gpg to$GREEN https://github.com/settings/gpg/new$RESET"

   log info "$exported_gpg"

   git config --global user.name $user_name
   git config --global user.email $user_email
   git config --global core.editor code
   git config --global advice.detachedhead false
   git config --global commit.gpgsign true

   log info "configuring git"
else
   log info "skipping git configuration"
fi

log info "done!"
