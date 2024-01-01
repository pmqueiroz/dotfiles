#!/bin/bash
source dots/helpers.sh
source dots/aliases.sh

source recipes/asdf.sh
source recipes/code.sh
source recipes/essentials.sh
source recipes/node.sh
source recipes/pnpm.sh

load_options $@

QUIETABLE=true

log_card info "starting setup"

log ask "input your username:"
read user_name
echo

log ask "input your email:"
read user_email
echo

log ask "input your sudo password:"
read sudo_password
echo

echo $sudo_password | sudo -S -v
authenticated=$?
if [ $authenticated -ne 0 ] ;then
   log error "wrong sudo password"
   exit 1
fi

if [[ ! -d "tmp" ]];then
   mkdir ./tmp
fi

has_installed_sources_before
has_installed=$?

if [[ $has_installed -ne 0 ]] && [[ ${options[skip-sources]} != true ]]; then
   log action "adding sources to bash config file"
   cat dots/sources.sh >> "$HOME/.bashrc"
else
   log skip "skip bash sources"
fi

if [[ ${options[skip-dependencies]} != true ]]; then
   log info "installing dependencies"

   declare -a dependencies;

   dependencies+=( "essentials" )
   dependencies+=( "asdf" )
   dependencies+=( "code" )
   dependencies+=( "pnpm" )
   dependencies+=( "node" )

   for dep in "${dependencies[@]}"; do 
      log action "running $dep recipe"
      eval install_$dep
      source $HOME/.bashrc
   done
else
   log skip "skip dependencies install"
fi

if [[ ${options[skip-dots]} != true ]]; then
   log info "configuring dotfiles"

   declare -A dots=( 
      ["vscode-settings.json"]="$HOME/.config/Code/User/settings.json"
      ["keybindings.json"]="$HOME/.config/Code/User/keybindings.json"
      [".gitconfig"]="$HOME/.gitconfig"
      ["aliases.sh"]="/usr/bin/peam-commands"
      [".inputrc"]="$HOME/.inputrc"
      [".tmux.config"]="$HOME/.tmux.config"
   )

   for dotfile in "${!dots[@]}"; do 
      dotfile_path=${dots[$dotfile]}
      mkdir -p $(dirname $dotfile_path)

      if git rev-parse --git-dir > /dev/null 2>&1; then
         cp dots/$dotfile ./tmp/$dotfile
      else
         log action "fetching dot $dotfile"
         curl -o ./tmp/$dotfile https://raw.githubusercontent.com/pmqueiroz/dotfiles/master/dots/$dotfile
      fi

      log action "setting dot $dotfile"
      cat ./tmp/$dotfile | render_string username $user_name email $user_email > ./tmp/$dotfile
      sudo cp ./tmp/$dotfile $dotfile_path
      sudo chmod a+w $dotfile_path
      sudo chmod a+r $dotfile_path
   done
else
   log skip "skip settings install"
fi

sudo --reset-timestamp
rm -rf ./tmp
