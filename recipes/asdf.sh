#!/bin/bash

function install_asdf {
   local asdf_version=$(curl -s https://api.github.com/repos/asdf-vm/asdf/releases | jq -r '.[0].tag_name')
   git config --global advice.detachedHead false
   git clone --quiet https://github.com/asdf-vm/asdf.git ~/.asdf --single-branch --branch $asdf_version
}
