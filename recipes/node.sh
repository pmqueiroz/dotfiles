#!/bin/bash

function install_node {
   asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

   asdf install nodejs lts

   asdf global nodejs lts
}
