#!/bin/bash

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
      brew install $pkg
   done
}
