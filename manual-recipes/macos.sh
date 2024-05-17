#!/usr/bin/env bash
cask=(
  "slack"
  "visual-studio-code"
  "warp"
  "firefox"
  "android-studio"
  "obs"
  "figma"
)

for pkg in "${cask[@]}"; do
  brew install --cask $pkg
done
