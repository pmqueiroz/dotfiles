#!/usr/bin/env bash
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
