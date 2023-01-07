#!/bin/bash

source $HOME/.bashrc

asdf plugin-add pnpm

asdf install pnpm latest

asdf global pnpm latest
