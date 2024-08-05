#!/usr/bin/env bash

shopt -s expand_aliases

function install_gnome_terminal {
  if [[ "$(uname -s)" == "Linux" ]]; then
    if [[ "$DESKTOP_SESSION" == "gnome" || "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
      cat "./dots/gnome-terminal-profile.dconf" | render_string username $user_name email $user_email > ./tmp/gnome-terminal-profile.dconf
      dconf load /org/gnome/terminal/legacy/profiles:/ < ./tmp/gnome-terminal-profile.dconf
    else
      gum_log error "GNOME is not the desktop environment. Failed to install gnome-terminal profile"
    fi
  else
    gum_log error "os is not Linux. Failed to install gnome-terminal profile"
  fi
}
