#!/usr/bin/env bash

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
