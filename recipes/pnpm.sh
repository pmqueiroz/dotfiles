#!/bin/bash
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
