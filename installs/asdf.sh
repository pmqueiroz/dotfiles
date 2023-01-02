#!/bin/bash

git config --global advice.detachedHead false
# TODO find a way to grab the always grab the latest version
git clone --quiet https://github.com/asdf-vm/asdf.git ~/.asdf --single-branch --branch v0.10.2
