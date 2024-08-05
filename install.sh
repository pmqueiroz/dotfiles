#!/usr/bin/env bash
shopt -s expand_aliases
source dots/aliases.sh

if ! command -v brew &> /dev/null; then
   echo "[FATAL] brew is not installed. Please install Homebrew first."
   exit 1
fi

if ! command -v gum &> /dev/null; then
   echo "[INFO] installing gum"
   brew install gum

   if [ $? -ne 0 ]; then
      echo "[FATAL] failed to install gum."
      exit 1
   fi
fi

if ! command -v md5sum &> /dev/null; then
   echo "[INFO] installing coreutils"
   brew install coreutils

   if [ $? -ne 0 ]; then
      echo "[FATAL] failed to install coreutils."
      exit 1
   fi
fi

source recipes/asdf.sh
source recipes/code.sh
source recipes/essentials.sh
source recipes/node.sh
source recipes/pnpm.sh
source recipes/cask.sh
source recipes/gnome-terminal.sh

declare -A options;
for opt in $@; do 
   if [[ $opt == --* ]]; then
      options[${opt:2}]=true
   fi
done

logfile="peam_dotfiles_$(date +%Y%m%d_%H%M%S).log"

function _ {
   [ "$1" = gum_log ] || gum_log debug -- "running command: $@" &>> $logfile
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

function post_install {
   echo
   echo

   gum join --align center --vertical \
      "$(gum style --foreground 212 --bold DONE!)" \
      "$(gum style --foreground 211 --italic --faint 'do not forget to gimme a star on github')" \
      "$(gum style --foreground 211 --italic --faint 'https://github.com/pmqueiroz/dotfiles')"

   rm -rf ./tmp
   sudo --reset-timestamp
}

gum style \
	--foreground 212 --border-foreground 212 --border rounded \
	--align center --width 50 --margin "1 2" --padding "1 4" \
	'DOTFILES' 'starting setup' 'made with <3 by peam'

user_name=$(gum input --placeholder 'username')
user_email=$(gum input --placeholder 'email@mail.com')
[ -z "$user_name" ] || [ -z "$user_email"  ] && exit 1 # prevent get stuck in ctrl+c

_ gum_log debug 'starting setup with credentials:'
_ gum_log debug "username: $user_name"
_ gum_log debug "email $user_email"

function auth {
   passphrase=$(gum input --password --placeholder 'your sudo password')
   echo $passphrase | sudo -Sv -p ""

   authenticated=$?
   if [ $authenticated -ne 0 ] ;then
      gum_log error "wrong sudo password"
      auth
   fi
}

auth

if [[ ! -d "tmp" ]];then
   mkdir ./tmp
fi

if [ ! -f $HOME/dots-aliases.sh ]; then
   gum_log info "file $HOME/dots-aliases.sh does not exits. creating"

   if git rev-parse --git-dir > /dev/null 2>&1; then
      cp ./dots/aliases.sh ./tmp/dots-aliases.sh
   else
      gum_log info "fetching dotfiles-commands"
      curl -o ./tmp/dots-aliases.sh https://raw.githubusercontent.com/pmqueiroz/dotfiles/master/dots/aliases.sh
   fi

   sudo cp ./tmp/dots-aliases.sh $HOME/dots-aliases.sh
fi

SOURCE_START_PATTERN="# ---BEGIN DOTFILES SOURCE---"
SOURCE_END_PATTERN="# ---END DOTFILES SOURCE---"

function save_installed_sources {
   local file_to_save=$1
   local is_source=false

   mapfile -t installed_sources_lines < "$HOME/.bashrc"

   for line in "${installed_sources_lines[@]}"; do
      if [ "$line" == "$SOURCE_START_PATTERN" ]; then
         is_source=true
         continue
      elif [ "$line" == "$SOURCE_END_PATTERN" ]; then
         is_source=false
         continue
      fi

      if $is_source;then 
         echo "$line" >> "$file_to_save"
      fi
   done
}

function remove_installed_sources {
   local is_source=false
   local tmp_source=$(mktemp)

   mapfile -t installed_sources_lines < "$HOME/.bashrc"

   for line in "${installed_sources_lines[@]}"; do
      if [ "$line" == "$SOURCE_START_PATTERN" ]; then
         is_source=true
         continue
      elif [ "$line" == "$SOURCE_END_PATTERN" ]; then
         is_source=false
         continue
      fi

      if ! $is_source;then 
         echo "$line" >> "$tmp_source"
      fi
   done

   cp "$tmp_source" "$HOME/.bashrc"

   rm -rf "$tmp_source"
}

function install_sources {
   gum_log info "adding sources to bash config file"
   echo $SOURCE_START_PATTERN >> "$HOME/.bashrc" 
   cat ./dots/sources.sh >> "$HOME/.bashrc"
   echo $SOURCE_END_PATTERN >> "$HOME/.bashrc" 
}

if [[ ${options[skip-sources]} != true ]]; then
   installed_sources=$(mktemp)
   save_installed_sources "$installed_sources"

   if [ -s $installed_sources ];then
      installed_sum=$(checksum $installed_sources)
      sources_sum=$(checksum ./dots/sources.sh)

      if [ "$installed_sum" != "$sources_sum" ]; then
         gum_log warn "source file is outdated. overwriting"
         bashrc_bak_name=$HOME/.bashrc.$(date +%Y%m%d_%H%M%S).bak
         gum_log info "creating a backup of .bashrc in $bashrc_bak_name"
         
         cp "$HOME/.bashrc" "$bashrc_bak_name"

         remove_installed_sources

         install_sources
      else
         gum_log info "installed sources is up to date. skip bash sources"
      fi
   else
      install_sources
   fi

   rm -rf $installed_sources
else
   gum_log warn "skip bash sources"
fi

if [[ ${options[skip-dependencies]} != true ]]; then
   gum_log info "dependencies"
   gum_log info "selected dependencies to install"

   declare -a dependencies;

   dependencies+=( "essentials" )
   dependencies+=( "asdf" )
   dependencies+=( "node" )
   dependencies+=( "code" )
   dependencies+=( "pnpm" )

   declare -a additional_dependencies;

   additional_dependencies+=( "cask" )
   additional_dependencies+=( "android" )
   additional_dependencies+=( "gnome_terminal" )

   all_choices="${dependencies[@]} ${additional_dependencies[@]}"
   selected=$(printf '%s\n' "$(IFS=,; printf '%s' "${dependencies[*]}")")

   readarray -t choosen_dependencies <<< "$(echo "$all_choices" | xargs gum choose --selected=${selected} --no-limit --header "use arrow keys and space to select")"

   for dep in "${choosen_dependencies[@]}"; do 
      gum_log info "running $dep recipe"
      eval install_$dep
      . $HOME/.bashrc
   done
else
   gum_log warn "skip dependencies install"
fi

if [[ ${options[skip-dots]} != true ]]; then
   gum_log info "configuring dotfiles"

   if [ "$(uname)" == "Darwin" ]; then
      CODE_SETTINGS_PATH="$HOME/Library/Application Support/Code/User/settings.json"
      CODE_KEYBINDS_PATH="$HOME/Library/Application Support/Code/User/keybindings.json"
   else
      CODE_SETTINGS_PATH="$HOME/.config/Code/User/settings.json"
      CODE_KEYBINDS_PATH="$HOME/.config/Code/User/keybindings.json"
   fi

   declare -A dots=( 
      ["vscode-settings.json"]="$CODE_SETTINGS_PATH"
      ["keybindings.json"]="$CODE_KEYBINDS_PATH"
      [".gitconfig"]="$HOME/.gitconfig"
      [".tmux.config"]="$HOME/.tmux.config"
   )

   for dotfile in "${!dots[@]}"; do 
      dotfile_path=${dots[$dotfile]}
      mkdir -p $(dirname $dotfile_path)

      if git rev-parse --git-dir > /dev/null 2>&1; then
         cp dots/$dotfile ./tmp/$dotfile
      else
         gum_log info "fetching dot $dotfile"
         curl -o ./tmp/$dotfile https://raw.githubusercontent.com/pmqueiroz/dotfiles/master/dots/$dotfile
      fi

      gum_log info "setting dot $dotfile in $dotfile_path"
      cat "./dots/$dotfile" | render_string username $user_name email $user_email > ./tmp/$dotfile
      sudo cp "./tmp/$dotfile" "$dotfile_path"
      sudo chmod a+w "$dotfile_path"
      sudo chmod a+r "$dotfile_path"
   done
else
   gum_log warn "skip settings install"
fi

gum confirm "proceed with authentication?" --timeout 10s --default="No" || {
   post_install
   exit 0
}

function continue_auth {
   gum style --foreground 212	--margin 1 'Press any key to continue'
   read -n 1 -s -r
}

if [[ ${options[skip-ssh]} != true ]]; then
   gum_log info "starting github ssh auth"

   ls $HOME/.ssh | grep -q id_ed25519
   if [ $? -ne 0 ]; then
      gum_log info 'creating ssh key'
      ssh-keygen -t ed25519 -C $user_email -f $HOME/.ssh/id_ed25519 -q -N ""
   fi

   HEADER=$(gum style --foreground 212	--margin 1 'Copy this ssh key bellow')
   BODY=$(gum style --margin "0 1" --padding "1" --foreground 15 --background 10 "$(cat $HOME/.ssh/id_ed25519.pub)")
   FOOTER=$(gum join --align center --horizontal "$(gum style --foreground 212 --margin 1 'and paste on')" "$(gum style --foreground 222 --margin 1 'https://github.com/settings/ssh/new')")

   gum join --align center --vertical "$HEADER" "$BODY" "$FOOTER"
else
   gum_log warn "skipping github ssh auth"
fi


if [[ ${options[skip-npm-token]} != true ]]; then
   continue_auth

   gum join --align center --horizontal "$(gum style --foreground 212 --margin 1 'Generate a new token in')" "$(gum style --foreground 222 --margin 1 'https://github.com/settings/tokens/new')"
   gum style --foreground 212	--margin 1 'Input your generated password'
   inputed_password=$(gum input --placeholder 'gpg_...')

   npx npm-cli-login -u $user_name -p $inputed_password -e $user_email -r https://npm.pkg.github.com
else
   gum_log warn "skipping npm token auth"
fi

if [[ ${options[skip-git]} != true ]]; then
   continue_auth

   gum_log info "generating gpg key"

   tmp_key_config=$(mktemp)

   cat ./dots/gpg_template.gpg | render_string username $user_name email $user_email passphrase $passphrase > $tmp_key_config

   _ gpg --batch --gen-key $tmp_key_config

   generated_gpg=$(gpg --list-secret-keys --keyid-format=long | perl -lne 'print $1 if /sec\s+rsa4096\/([0-9A-Z]{16} )/' | tail -n 1)

   HEADER=$(gum style --foreground 212	--margin 1 'Copy this gpg key bellow')
   BODY=$(gum style --margin "0 1" --padding "1" --foreground 15 --background 10 -- "$(gpg --armor --export $generated_gpg)")
   FOOTER=$(gum join --align center --horizontal "$(gum style --foreground 212 --margin 1 'and paste on')" "$(gum style --foreground 222 --margin 1 'https://github.com/settings/gpg/new')")

   gum join --align center --vertical "$HEADER" "$BODY" "$FOOTER"
else
   gum_log warn "skipping git configuration"
fi

post_install
