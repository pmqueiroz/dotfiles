#!/bin/bash
source helpers.sh

load_options $@

QUIETABLE=true

log_card info "starting setup - do not forget to run apt update before running this script"

if [[ ! -d "tmp" ]];then
   mkdir ./tmp
fi

has_installed_sources_before
has_installed=$?

if [[ $has_installed -ne 0 ]] && [[ ${options[skip-sources]} != true ]]; then
   log action "adding sources to bash config file"
   cat sources >> "$HOME/.bashrc"
else
   log skip "skip bash sources"
fi

if [[ ${options[skip-fonts]} != true ]]; then
   log info "installing fonts"

   fonts_paths="$HOME/.local/share/fonts"
   mkdir -p $fonts_paths

   for font in ./fonts/*.ttf
   do
      log action "installing font $font"

      cp $font $fonts_paths
   done

   log action "restarting fonts cache"

   fc-cache -f -v > /dev/null
else
   log skip "skip fonts install"
fi

if [[ ${options[skip-adornments]} != true ]]; then
   log info "installing adornments"
   if [[ -d "tmp" ]];then
      rm -rf tmp/reversal
   fi


   log info "install gtk theme"
   curl -L -o "tmp/dracula-gtk.zip" https://github.com/dracula/gtk/archive/master.zip
   sudo unzip ./tmp/dracula-gtk.zip -d /usr/share/themes/
   gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
   gsettings set org.gnome.desktop.wm.preferences theme "Dracula"

   exit 0
   log info "installing icons"
   git clone https://github.com/yeyushengfan258/Reversal-icon-theme.git ./tmp/reversal --depth=1

   bash tmp/reversal/install.sh -purple

   gsettings set org.gnome.desktop.interface icon-theme "Reversal-purple-dark"

   log info "installing background"
   sudo cp background.jpg /usr/share/backgrounds/dotfiles-background.jpg

   gsettings set org.gnome.desktop.background picture-uri file:////usr/share/backgrounds/dotfiles-background.jpg
else
   log skip "skip icons install"
fi

if [[ ${options[skip-dependencies]} != true ]]; then
   log info "installing dependencies"

   declare -A dependencies=(
      ["peam-essentials"]="./scripts/peam-essentials.sh"
      ["asdf"]="./scripts/asdf.sh"
      ["code"]="./scripts/code.sh"
      ["code-extensions"]="./scripts/code-extensions.sh"
      ["zsh"]="./scripts/zsh.sh"
      ["pnpm"]="./scripts/pnpm.sh"
      ["node"]="./scripts/node.sh"
      ["gnome-terminal-profile"]="./scripts/gnome-terminal-profile.sh"
   );
   declare -a deps_orders;

   deps_orders+=( "peam-essentials" )
   deps_orders+=( "asdf" )
   deps_orders+=( "code" )
   deps_orders+=( "code-extensions" )
   deps_orders+=( "pnpm" )
   deps_orders+=( "node" )
   deps_orders+=( "gnome-terminal-profile" )

   for dep in "${deps_orders[@]}"; do 
      log info "trying to install $dep"

      exists=$(which $dep)
      check_install_exit=$?

      if [ $check_install_exit -ne 0 ] ;then
         log action "running ${dependencies[$dep]} script"

         ${dependencies[$dep]}
      else
         log skip "$dep already registered; skipping";
      fi
   done
else
   log skip "skip dependencies install"
fi

if [[ ${options[skip-settings]} != true ]]; then
   log info "configuring settings"

   declare -A settings=( 
      ["vscode-settings.json"]="$HOME/.config/Code/User/settings.json"
      ["keybindings.json"]="$HOME/.config/Code/User/keybindings.json"
      [".gitconfig"]="$HOME/.gitconfig"
      ["bash-commands"]="/usr/bin/peam-commands"
      [".inputrc"]="$HOME/.inputrc"
      [".tmux.config"]="$HOME/.tmux.config"
   )

   declare -a settings_orders;

   settings_orders+=( "vscode-settings.json" )
   settings_orders+=( "keybindings.json" )
   settings_orders+=( ".gitconfig" )
   settings_orders+=( "bash-commands" )
   settings_orders+=( ".inputrc" )
   settings_orders+=( ".tmux.config" )

   sudo -v; # just for grab previous permissions

   for setting_file in "${settings_orders[@]}"; do 
      log action "installing setting $setting_file"

      mkdir -p $(dirname ${settings[$setting_file]})

      sudo cp settings/$setting_file ${settings[$setting_file]}

      sudo chmod a+w ${settings[$setting_file]}
      sudo chmod a+r ${settings[$setting_file]}
   done
else
   log skip "skip settings install"
fi
