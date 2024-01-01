#!/bin/bash
source $HOME/.bashrc

function install_pnpm {
   asdf plugin-add pnpm

   asdf install pnpm latest

   asdf global pnpm latest
}
