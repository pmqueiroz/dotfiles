#!/bin/bash
shopt -s expand_aliases

function install_pnpm {
   _ asdf plugin-add pnpm
   _ asdf install pnpm latest
   _ asdf global pnpm latest
}
