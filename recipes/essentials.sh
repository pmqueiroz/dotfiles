#!/bin/bash
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
      if ! _ command -v gum; then
         _ brew install $pkg
         if [ $? -ne 0 ]; then
            log error "failed to install $pkg"
         fi
      else
         log warn "$pkg already installed. skipping"
      fi
   done
}
