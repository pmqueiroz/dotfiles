#!/bin/bash
function install_pnpm {
   asdf plugin-add pnpm

   asdf install pnpm latest

   asdf global pnpm latest
}
