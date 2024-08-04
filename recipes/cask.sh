#!/usr/bin/env bash

shopt -s expand_aliases

function install_cask {
  cask=(
    "slack"
    "visual-studio-code"
    "warp"
    "firefox"
    "obs"
    "figma"
  )

  for pkg in "${cask[@]}"; do
    brew install --cask $pkg
  done
}
