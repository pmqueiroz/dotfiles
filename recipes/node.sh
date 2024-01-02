#!/bin/bash

function install_node {
   _ asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
   _ asdf install nodejs lts
   _ asdf global nodejs lts
}
