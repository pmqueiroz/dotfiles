#!/bin/bash
source dots/aliases.sh

source recipes/asdf.sh
source recipes/code.sh
source recipes/essentials.sh
source recipes/node.sh
source recipes/pnpm.sh

shopt -s expand_aliases

declare -A options;
for opt in $@; do 
   if [[ $opt == --* ]]; then
      options[${opt:2}]=true
   fi
done

logfile="peam_dotfiles_$(date +%Y%m%d_%H%M%S).log"

function _ {
   [ "$1" = log ] || log debug  -- "running command: $@" &>> $logfile
   [ "${options[verbose]}" = true ] && eval $@ || eval $@ &>> $logfile
}

function loader {
   if [[ -t 0 ]]; then
      gum spin -s minidot --title="" -- $@
   else
      eval $@
   fi
}

function render_string {
   local template=$(cat)
   while [ $# -gt 0 ]; do
      template=${template//\{\{$1\}\}/$2}
      shift 2
   done
   echo "$template"
}

if ! command -v brew &> /dev/null; then
   log fatal "brew is not installed. Please install Homebrew first."
   exit 1
fi

if ! command -v gum &> /dev/null; then
   log info "installing gum"
   _ brew install gum

   if [ $? -ne 0 ]; then
      log fatal "failed to install gum."
      exit 1
   fi
fi

gum style \
	--foreground 212 --border-foreground 212 --border rounded \
	--align center --width 50 --margin "1 2" --padding "1 4" \
	'DOTFILES' 'starting setup' 'made with <3 by peam'

user_name=$(gum input --placeholder 'username')
user_email=$(gum input --placeholder 'email@mail.com')
[ -z "$user_name" ] || [ -z "$user_email"  ] && exit 1 # prevent get stuck in ctrl+c

_ log debug 'starting setup with credentials:'
_ log debug "username: $user_name"
_ log debug "email $user_email"

function auth {
   passphrase=$(gum input --password --placeholder 'your sudo password')
   echo $passphrase | sudo -Sv -p ""

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

if [[ ${options[skip-sources]} != true ]]; then
   START_PATTERN="# ---BEGIN DOTFILES SOURCE---"
   END_PATTERN="# ---END DOTFILES SOURCE---"

   installed_sources=$(mktemp)
   awk "/${START_PATTERN}/,/${END_PATTERN}/" "$HOME/.bashrc" > $installed_sources

   if [ -s $installed_sources ];then
      installed_sum=$(checksum $installed_sources)
      sources_sum=$(checksum ./dots/sources.sh)

      if [ "$installed_sum" != "$sources_sum" ]; then
         log info "source file is outdated. overwriting"
         cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
         
         awk -v replacement="$(<"./dots/sources.sh")" '
            $0 ~ start {print replacement; skip = 1}
            $0 ~ end {skip = 0; next}
            !skip
         ' start="$START_PATTERN" end="$END_PATTERN" "$HOME/.bashrc.bak" > "$HOME/.bashrc"
      else
         log warn "installed sources is ok. skip bash sources"
      fi
   else
      log info "adding sources to bash config file"
      echo >> "$HOME/.bashrc"
      cat ./dots/sources.sh >> "$HOME/.bashrc"
   fi

   rm -rf $installed_sources
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
      cat ./dots/$dotfile | render_string username $user_name email $user_email > ./tmp/$dotfile
      sudo cp ./tmp/$dotfile $dotfile_path
      sudo chmod a+w $dotfile_path
      sudo chmod a+r $dotfile_path
   done
else
   log warn "skip settings install"
fi

gum confirm "Proceed with authentication?" --timeout 10s --default="No" || exit 0

function continue_auth {
   gum style --foreground 212	--margin 1 'Press any key to continue'
   read -n 1 -s -r
}

if [[ ${options[skip-ssh]} != true ]]; then
   log info "starting github ssh auth"

   ls $HOME/.ssh | grep -q id_ed25519
   if [ $? -ne 0 ]; then
      log info 'creating ssh key'
      ssh-keygen -t ed25519 -C $user_email -f $HOME/.ssh/id_ed25519 -q -N ""
   fi

   HEADER=$(gum style --foreground 212	--margin 1 'Copy this ssh key bellow')
   BODY=$(gum style --margin "0 1" --padding "1" --foreground 15 --background 10 "$(cat $HOME/.ssh/id_ed25519.pub)")
   FOOTER=$(gum join --align center --horizontal "$(gum style --foreground 212 --margin 1 'and paste on')" "$(gum style --foreground 222 --margin 1 'https://github.com/settings/ssh/new')")

   gum join --align center --vertical "$HEADER" "$BODY" "$FOOTER"
else
   log warn "skipping github ssh auth"
fi

continue_auth

if [[ ${options[skip-npm-token]} != true ]]; then
   gum join --align center --horizontal "$(gum style --foreground 212 --margin 1 'Generate a new token in')" "$(gum style --foreground 222 --margin 1 'https://github.com/settings/tokens/new')"
   gum style --foreground 212	--margin 1 'Input your generated password'
   inputed_password=$(gum input --placeholder 'gpg_...')

   npx npm-cli-login -u $user_name -p $inputed_password -e $user_email -r https://npm.pkg.github.com
else
   log warn "skipping npm token auth"
fi

continue_auth

if [[ ${options[skip-git-configuring]} != true ]]; then
   log info "generating gpg key"

   tmp_key_config=$(mktemp)

   cat ./dots/gpg_template.gpg | render_string username $user_name email $user_email passphrase $passphrase > $tmp_key_config

   _ gpg --batch --gen-key $tmp_key_config

   generated_gpg=$(gpg --list-secret-keys --keyid-format=long | perl -lne 'print $1 if /sec\s+rsa4096\/([0-9A-Z]{16} )/' | tail -n 1)

   HEADER=$(gum style --foreground 212	--margin 1 'Copy this gpg key bellow')
   BODY=$(gum style --margin "0 1" --padding "1" --foreground 15 --background 10 -- "$(gpg --armor --export $generated_gpg)")
   FOOTER=$(gum join --align center --horizontal "$(gum style --foreground 212 --margin 1 'and paste on')" "$(gum style --foreground 222 --margin 1 'https://github.com/settings/gpg/new')")

   gum join --align center --vertical "$HEADER" "$BODY" "$FOOTER"
else
   log warn "skipping git configuration"
fi

echo
echo

gum join --align center --vertical \
   "$(gum style --foreground 212 --bold DONE!)" \
   "$(gum style --foreground 211 --italic --faint 'do not forget to gimme a star on github')"

sudo --reset-timestamp
rm -rf ./tmp
