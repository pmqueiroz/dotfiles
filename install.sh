shopt -s expand_aliases

shopt -s expand_aliases

alias glo='git log --oneline'
alias repo='gh repo view --web'
alias debug='gum log -s -t kitchen -l debug'
alias gum_log='gum log -t kitchen -l'

case "$OSTYPE" in
  darwin*)
   alias date='gdate'
   ;;
  linux*)
   alias date='date'
   ;;
  *)
   alias date='date'
   ;;
esac

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

function git_branch_style {
  gum style "🌿 $(gum style --bold --underline --foreground "#BD93F9" "$@")"
}

function git_pr_style {
  gum style "$(gum style --foreground "#FF79C6" '#')$(gum style --bold --underline --foreground "#BD93F9" "$@")"
}

function fpush {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      gum_log fatal "not a git repository"
      return 128
   fi

   branch=$(git branch --show-current)
   gum_log info "pushing and setting upstream to $(git_branch_style "$branch")"
   git push --set-upstream origin "$branch"
}

function commit {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      gum_log fatal "not a git repository"
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

   gum_log info "commiting files with message $(git_branch_style "$commitmsg")"

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

    repo_name=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
    branch_name=$(gh pr view "$pr_number" --json headRefName --repo "$repo_name" --jq '.headRefName' 2>/dev/null)

    if [ $? -ne 0 ]; then
        return 1
    fi

    echo "$branch_name"
}

function checkout {
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
      gum_log fatal "not a git repository"
      return 128
   fi

   current_branch=$(git branch --show-current)

   if test -z "$1"; then
      branch_to_checkout=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
   else
      if [[ $1 =~ ^[0-9]+$ ]]; then
         gum_log info "fetching branch to $(git_pr_style "$1")"
          branch_by_number=$(get_branch_by_number "$1")

         if [ $? -ne 0 ]; then
            gum_log fatal "could not determine branch to $(git_pr_style "$1")"
            return 1
         fi

         branch_to_checkout="$branch_by_number"
      else
         branch_to_checkout="$1"
      fi
   fi

   if [ "$current_branch" != "$branch_to_checkout" ]; then
      gum_log info "checking out to $(git_branch_style "$branch_to_checkout")"
      git checkout --quiet "$branch_to_checkout"
   fi

   gum_log info "updating current branch"

   git pull --rebase --quiet

   local_branchs=$(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -v "^$branch_to_checkout$")

   if test -n "$local_branchs"; then
      gum_log info 'deleting other branches. was:'
      for branch in "${local_branchs[@]}"; do 
         git_branch_style "$branch"
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

function penv() {
  local offset=8
  local splitted_offset=$((offset / 2))
  local env=$1
  local length=${#env}

  if [ "$length" -lt $offset ]; then
    echo "Env var is too short"
    return
  fi

  local stars
  stars="$(printf "%0.s*" $(seq 1 $((length - offset))))"
  echo "${env:0:splitted_offset}${stars}${env: -splitted_offset}"
}

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


shopt -s expand_aliases 

function install_asdf {
   local asdf_folder=$HOME/.asdf

   if [ -d "$asdf_folder" ]; then
      gum_log warn "asdf already installed. skipping"
   else 
      local asdf_version=$(curl -s https://api.github.com/repos/asdf-vm/asdf/releases | jq -r '.[0].tag_name')
      git config --global advice.detachedHead false
      _ git clone https://github.com/asdf-vm/asdf.git ~/.asdf --single-branch --branch "$asdf_version"

      echo 'source $HOME/.asdf/asdf.sh' >> "$HOME"/.bashrc
   fi
}
shopt -s expand_aliases

function install_code {
   if ! command -v code &> /dev/null; then
      gum_log error "make sure vscode is installed and the code command is added to PATH"
      exit 1
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
   extensions+=( "rust-lang.rust-analyzer" )

   installed_extensions=$(code --list-extensions)

   for ext in "${extensions[@]}"; do
      echo "${installed_extensions[@]}" | grep -iq $ext
      already_installed=$?

      if [[ $already_installed -ne 0 ]]; then
         gum_log info "installing $ext"
         code --install-extension $ext
      else
         gum_log warn "code extension $ext already installed. skipping"
      fi
   done
}
shopt -s expand_aliases

function install_essentials {
   packages=(
      "xsel"
      "rg"
      "neofetch"
      "tmux"
      "zoxide"
      "jq"
      "gh"
      "glow"
      "fzf"
      "gpg"
   )

   for pkg in "${packages[@]}"; do
      if ! command -v $pkg &> /dev/null; then
         gum_log info "installing $pkg"
         _ brew install $pkg
         if [ $? -ne 0 ]; then
            gum_log error "failed to install $pkg"
         fi
      else
         gum_log warn "$pkg already installed. skipping"
      fi
   done
}
shopt -s expand_aliases

function install_node {
   _ asdf plugin add nodejs
   _ asdf install nodejs 18.20.2
   _ asdf global nodejs 18.20.2
}
shopt -s expand_aliases

function install_pnpm {
   if ! command -v pnpm &> /dev/null; then
      _ asdf plugin-add pnpm
      _ asdf install pnpm latest
      _ asdf global pnpm latest
   else 
      gum_log warn "pnpm already installed. skipping"
   fi
}

shopt -s expand_aliases

function install_cask {
  cask=(
    "slack"
    "visual-studio-code"
    "warp"
    "firefox"
    "obs"
    "figma"
  )

  for pkg in "${cask[@]}"; do
    brew install --cask $pkg
  done
}

shopt -s expand_aliases

function install_gnome_terminal {
  if [[ "$(uname -s)" == "Linux" ]]; then
    if [[ "$DESKTOP_SESSION" == "gnome" || "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
      cat "./dots/gnome-terminal-profile.dconf" | render_string username $user_name email $user_email > ./tmp/gnome-terminal-profile.dconf
      dconf load /org/gnome/terminal/legacy/profiles:/ < ./tmp/gnome-terminal-profile.dconf
    else
      gum_log error "GNOME is not the desktop environment. Failed to install gnome-terminal profile"
    fi
  else
    gum_log error "os is not Linux. Failed to install gnome-terminal profile"
  fi
}

declare -A options;
for opt in $@; do 
   if [[ $opt == --* ]]; then
      options[${opt:2}]=true
   fi
done

logfile="peam_dotfiles_$(date +%Y%m%d_%H%M%S).log"

function _ {
   [ "$1" = gum_log ] || gum_log debug -- "running command: $@" &>> "$logfile"
   [ "${options[verbose]}" = true ] && eval $@ || eval $@ &>> "$logfile"
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
   echo "$passphrase" | sudo -Sv -p ""

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

if [ ! -f "$HOME"/dots-aliases.sh ]; then
   gum_log info "file $HOME/dots-aliases.sh does not exits. creating"

   if git rev-parse --git-dir > /dev/null 2>&1; then
      cp ./dots/aliases.sh ./tmp/dots-aliases.sh
   else
      gum_log info "fetching dotfiles-commands"
      curl -o ./tmp/dots-aliases.sh https://raw.githubusercontent.com/pmqueiroz/dotfiles/master/dots/aliases.sh
   fi

   sudo cp ./tmp/dots-aliases.sh "$HOME"/dots-aliases.sh
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
   echo "$SOURCE_START_PATTERN" >> "$HOME/.bashrc" 
   cat ./dots/sources.sh >> "$HOME/.bashrc"
   echo "$SOURCE_END_PATTERN" >> "$HOME/.bashrc" 
}

if [[ ${options[skip-sources]} != true ]]; then
   installed_sources=$(mktemp)
   save_installed_sources "$installed_sources"

   if [ -s "$installed_sources" ];then
      installed_sum=$(checksum "$installed_sources")
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

   rm -rf "$installed_sources"
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

   readarray -t choosen_dependencies <<< "$(echo "$all_choices" | xargs gum choose --selected="${selected}" --no-limit --header "use arrow keys and space to select")"

   for dep in "${choosen_dependencies[@]}"; do 
      gum_log info "running $dep recipe"
      eval install_"$dep"
      . "$HOME"/.bashrc
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
      mkdir -p $(dirname "$dotfile_path")

      if git rev-parse --git-dir > /dev/null 2>&1; then
         cp dots/"$dotfile" ./tmp/"$dotfile"
      else
         gum_log info "fetching dot $dotfile"
         curl -o ./tmp/"$dotfile" https://raw.githubusercontent.com/pmqueiroz/dotfiles/master/dots/"$dotfile"
      fi

      gum_log info "setting dot $dotfile in $dotfile_path"
      cat "./dots/$dotfile" | render_string username "$user_name" email "$user_email" > ./tmp/"$dotfile"
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

   ls "$HOME"/.ssh | grep -q id_ed25519
   if [ $? -ne 0 ]; then
      gum_log info 'creating ssh key'
      ssh-keygen -t ed25519 -C "$user_email" -f "$HOME"/.ssh/id_ed25519 -q -N ""
   fi

   HEADER=$(gum style --foreground 212	--margin 1 'Copy this ssh key bellow')
   BODY=$(gum style --margin "0 1" --padding "1" --foreground 15 --background 10 "$(cat "$HOME"/.ssh/id_ed25519.pub)")
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

   npx --yes npm-cli-login -u "$user_name" -p "$inputed_password" -e "$user_email" -r https://npm.pkg.github.com
else
   gum_log warn "skipping npm token auth"
fi

if [[ ${options[skip-git]} != true ]]; then
   continue_auth

   gum_log info "generating gpg key"

   tmp_key_config=$(mktemp)

   cat ./dots/gpg_template.gpg | render_string username "$user_name" email "$user_email" passphrase "$passphrase" > "$tmp_key_config"

   _ gpg --batch --gen-key "$tmp_key_config"

   generated_gpg=$(gpg --list-secret-keys --keyid-format=long | perl -lne 'print $1 if /sec\s+rsa4096\/([0-9A-Z]{16} )/' | tail -n 1)

   HEADER=$(gum style --foreground 212	--margin 1 'Copy this gpg key bellow')
   BODY=$(gum style --margin "0 1" --padding "1" --foreground 15 --background 10 -- "$(gpg --armor --export "$generated_gpg")")
   FOOTER=$(gum join --align center --horizontal "$(gum style --foreground 212 --margin 1 'and paste on')" "$(gum style --foreground 222 --margin 1 'https://github.com/settings/gpg/new')")

   gum join --align center --vertical "$HEADER" "$BODY" "$FOOTER"
else
   gum_log warn "skipping git configuration"
fi

post_install