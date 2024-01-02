#!/bin/bash
source dots/helpers.sh
source dots/aliases.sh

source recipes/asdf.sh
source recipes/code.sh
source recipes/essentials.sh
source recipes/node.sh
source recipes/pnpm.sh

if ! _ command -v brew; then
   log fatal "brew is not installed. Please install Homebrew first."
   exit 1
fi

if ! _ command -v gum; then
   log info "installing gum"
   _ brew install gum

   if [ $? -ne 0 ]; then
      log fatal "failed to install gum."
      exit 1
   fi
fi

load_options $@

QUIETABLE=true

gum style \
	--foreground 212 --border-foreground 212 --border rounded \
	--align center --width 50 --margin "1 2" --padding "1 4" \
	'starting setup ' 'made with <3 by peam'

user_name=$(gum input --placeholder 'username')
user_email=$(gum input --placeholder 'email@mail.com')

_ echo "${user_name}_$user_email"

function auth {
   gum input --password --placeholder 'your sudo password' | sudo -Sv -p ""

   authenticated=$?
   if [ $authenticated -ne 0 ] ;then
      log error "wrong sudo password"
      auth
   fi
}

auth

if [[ ! -d "tmp" ]];then
   mkdir ./tmp
fi

has_installed_sources_before
has_installed=$?

if [[ $has_installed -ne 0 ]] && [[ ${options[skip-sources]} != true ]]; then
   log info "adding sources to bash config file"
   cat dots/sources.sh >> "$HOME/.bashrc"
else
   log warn "skip bash sources"
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
      log info "running $dep recipe"
      eval install_$dep
      source $HOME/.bashrc
   done
else
   log warn "skip dependencies install"
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
         log info "fetching dot $dotfile"
         curl -o ./tmp/$dotfile https://raw.githubusercontent.com/pmqueiroz/dotfiles/master/dots/$dotfile
      fi

      log info "setting dot $dotfile"
      cat ./tmp/$dotfile | render_string username $user_name email $user_email > ./tmp/$dotfile
      sudo cp ./tmp/$dotfile $dotfile_path
      sudo chmod a+w $dotfile_path
      sudo chmod a+r $dotfile_path
   done
else
   log warn "skip settings install"
fi

exit 1

if [[ ${options[skip-ssh]} != true ]]; then
   log info "creating github ssh auth"

   check_existing_ssh_key
   existing_ssh=$?

   if [[ $existing_ssh -ne 0 ]]; then
      ssh-keygen -t ed25519 -C $user_email -f $HOME/.ssh/id_ed25519 -q -N ""
   fi

   log info "there is your ssh key: $GREEN$(cat $HOME/.ssh/id_ed25519.pub)$RESET copy and paste on $GREEN\https://github.com/settings/ssh/new$RESET"
else
   log warn "skipping github ssh auth"
fi

if [[ ${options[skip-npm-token]} != true ]]; then
   log info "creating npm token auth"
   log ask "generate a new token in $GREEN\\https://github.com/settings/tokens/new${RESET}"

   log ask "input your generated password:"
   read inputed_password
   echo

   npx npm-cli-login -u $user_name -p $inputed_password -e $user_email -r https://npm.pkg.github.com
else
   log warn "skipping npm token auth"
fi

if [[ ${options[skip-git-configuring]} != true ]]; then
   log info "generating gpg key enter the passphrase"

   tmp_key_config=$(mktemp)

   cat >> $tmp_key_config << EOF
   Key-Type: 1
   Key-Length: 4096
   Subkey-Type: 1
   Subkey-Length: 4096
   Name-Real: $user_name
   Name-Email: $user_email
   Expire-Date: 0
EOF

   gpg --batch --gen-key $tmp_key_config

   generated_gpg=$(gpg --list-secret-keys --keyid-format=long | perl -lne 'print $1 if /sec\s+rsa4096\/([0-9A-Z]{16} )/' | tail -n 1)
   
   exported_gpg=$(gpg --armor --export $generated_gpg)

   log info "now you can add this gpg to$GREEN https://github.com/settings/gpg/new$RESET"

   log info "$exported_gpg"
else
   log warn "skipping git configuration"
fi

log info "done!"

sudo --reset-timestamp
rm -rf ./tmp
