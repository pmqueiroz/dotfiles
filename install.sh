if ! command -v brew &> /dev/null; then
   log fatal "brew is not installed. Please install Homebrew first."
   exit 1
fi

if ! command -v gum &> /dev/null; then
   log info "installing gum"
   brew install gum

   if [ $? -ne 0 ]; then
      log fatal "failed to install gum."
      exit 1
   fi
fi


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
alias repo='gh repo view --web'
alias debug='gum log -s -t kitchen -l debug'
alias log='gum log -t kitchen -l'

function pr {
   gh pr view --json number -q '.number' &> /dev/null

   if [ $? -ne 0 ]; then
      title=$(commit_title $(git branch --show-current))
      gh pr create --assignee @me --title "$title" --web $@
      return 
   fi

   gh pr view --web
}

function commit_title {
   echo $1 | awk '{gsub("/",": "); print}' | awk '{gsub("-"," "); print}'
}

function git_style {
  gum style "$(gum style --foreground "#f14e32" '') $(gum style --bold --underline --foreground "#f14e32" "$@")"
}

function fpush {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      log error "not a git repository"
      return 128
   fi

   branch=`git branch --show-current`
   log info "pushing and setting upstream to $(git_style $branch)"

   git push $1 --set-upstream origin $branch $2
}

function commit {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      log error "not a git repository"
      return 128
   fi
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

   if test -z "$inputted_message"
   then
      commitmsg=`commit_title $(git branch --show-current)`
   else
      commitmsg="$inputted_message"
   fi

   log info "commiting files with message $(git_style "$commitmsg")"

   gum style --foreground 12 --margin "0 1" -- "$(git diff --name-only --cached)"

   gum confirm "confirm?" && git commit -m "${commitmsg}" ${commit_options[@]} || {
      log error exiting...
      git reset
   }
}

function checkout {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      log error "not a git repository"
      return 128
   fi

   current_branch=$(git branch --show-current)

   if test -z "$1"; then
      branch_to_checkout=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
   else
      branch_to_checkout="$1"
   fi

   if [ $current_branch != $branch_to_checkout ]; then
      log info "checking out to $(git_style $branch_to_checkout)"
      git checkout --quiet $branch_to_checkout
   fi

   log info 'updating branch'

   git pull --rebase --quiet

   local_branchs=$(git for-each-ref --format='%(refname:short)' refs/heads/ | sed s/$branch_to_checkout// )

   if test -n "$local_branchs"; then
      log info 'deleting other branches. was:'
      for branch in ${local_branchs[@]}; do 
         git_style $branch
      done

      echo $local_branchs | xargs git branch -q -D
   fi
}

function run_node {
   tmp_file=$(mktemp --suffix=.js)
   code $tmp_file --wait
   file_content=$(cat ${tmp_file})
   node -p -e "${file_content}"
   rm -rf $tmp_file
}

function checksum {
   md5sum $1 | awk '{ print $1 }'
}

function hot {
  if (( $# < 2 )); then
   log error 'USAGE: hot <command> <file1> [<file2> ... <fileN>]'
  else
   script=$1
   shift
   a='';

   while true; do
      b=`ls -l $*`
      [[ $a != $b ]] && a=$b && eval $script;
      sleep .5;
   done
  fi
}


shopt -s expand_aliases

function install_asdf {
   local asdf_folder=$HOME/.asdf

   if [ -d $asdf_folder ]; then
      log warn "asdf already installed. skipping"
   else 
      local asdf_version=$(curl -s https://api.github.com/repos/asdf-vm/asdf/releases | jq -r '.[0].tag_name')
      git config --global advice.detachedHead false
      _ git clone https://github.com/asdf-vm/asdf.git ~/.asdf --single-branch --branch $asdf_version
   fi
}
shopt -s expand_aliases

function install_code {
   if ! command -v code &> /dev/null; then
      log info downloading vscode
      loader curl -s -L -o "code_amd64.deb" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
      log info installing vscode
      _ sudo dpkg -i ./code_amd64.deb

      if [ $? -ne 0 ]; then
         log error "failed to install vscode"
         exit 1 # prevent installing extensions
      fi
   fi

   declare -a extensions;

   extensions+=( "naumovs.color-highlight" )
   extensions+=( "dracula-theme.theme-dracula" )
   extensions+=( "DaltonMenezes.aura-theme" )
   extensions+=( "pkief.material-icon-theme" )
   extensions+=( "styled-components.vscode-styled-components" )
   extensions+=( "wix.vscode-import-cost" )
   extensions+=( "streetsidesoftware.code-spell-checker" )
   extensions+=( "streetsidesoftware.code-spell-checker-portuguese-brazilian" )
   extensions+=( "eamodio.gitlens" )
   extensions+=( "moyu.snapcode" )
   extensions+=( "formulahendry.auto-rename-tag" )
   extensions+=( "dbaeumer.vscode-eslint" )
   extensions+=( "yoavbls.pretty-ts-errors" )
   extensions+=( "miguelsolorio.fluent-icons" )
   extensions+=( "drcika.apc-extension" )

   installed_extensions=$(code --list-extensions)

   for ext in "${extensions[@]}"; do
      echo "${installed_extensions[@]}" | grep -iq $ext
      already_installed=$?

      if [[ $already_installed -ne 0 ]]; then
         log action "installing $ext"
         code --install-extension $ext
      else
         log warn "code extension $ext already installed. skipping"
      fi
   done
}
shopt -s expand_aliases

function install_essentials {
   packages=(
      "xsel"
      "ripgrep"
      "neofetch"
      "tmux"
      "zoxide"
      "jq"
      "gh"
   )

   for pkg in "${packages[@]}"; do
      if ! command -v gum &> /dev/null; then
         _ brew install $pkg
         if [ $? -ne 0 ]; then
            log error "failed to install $pkg"
         fi
      else
         log warn "$pkg already installed. skipping"
      fi
   done
}
shopt -s expand_aliases

function install_node {
   _ asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
   _ asdf install nodejs lts
   _ asdf global nodejs lts
}
shopt -s expand_aliases

function install_pnpm {
   if ! command -v pnpm &> /dev/null; then
      _ asdf plugin-add pnpm
      _ asdf install pnpm latest
      _ asdf global pnpm latest
   else 
      log warn "pnpm already installed. skipping"
   fi
}

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

function post_install {
   echo
   echo

   gum join --align center --vertical \
      "$(gum style --foreground 212 --bold DONE!)" \
      "$(gum style --foreground 211 --italic --faint 'do not forget to gimme a star on github')" \
      "$(gum style --foreground 211 --italic --faint 'https://github.com/pmqueiroz/dotfiles')"

   sudo rm -rf ./tmp
   sudo --reset-timestamp
}

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

gum confirm "Proceed with authentication?" --timeout 10s --default="No" || {
   post_install
   exit 0
}

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

post_install