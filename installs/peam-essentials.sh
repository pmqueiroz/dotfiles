#!/bin/bash

function grab_config() {
   config_name=$1

   cat $build_config | grep "^$config_name: " | cut -d:  -f2 | sed -e s/[[:space:]]//
}

sudo apt install -y gdebi-core

build_config="$(pwd)/peam-essentials/DEBIAN/control"
current_version=$(grab_config Version)
packagename=$(grab_config Package)

echo "building version $current_version of $packagename"

dpkg --build peam-essentials

deb_file="${packagename}.deb"

echo "installing $packagename"

sudo gdebi "$deb_file"
