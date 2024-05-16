#!/usr/bin/env bash
shopt -s expand_aliases

function install_node {
   _ asdf plugin add nodejs
   _ asdf install nodejs 18.20.2
   _ asdf global nodejs 18.20.2
}
