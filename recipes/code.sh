#!/bin/bash

function install_code {
   gum spin \
      --spinner="minidot" \
      --align="right" \
      --title="$(log info downloading vscode)" \
      -- curl -s -L -o "code_amd64.deb" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
   _ sudo dpkg -i ./code_amd64.deb
   if [ $? -ne 0 ]; then
      log error "failed to install vscode"
      exit 1 # prevent installing extensions
   fi

   declare -a extensions;

   extensions+=( "naumovs.color-highlight" )
   extensions+=( "dracula-theme.theme-dracula" )
   extensions+=( "DaltonMenezes.aura-theme" )
   extensions+=( "pkief.material-icon-theme" )
   extensions+=( "styled-components.vscode-styled-components" )
   extensions+=( "wix.vscode-import-cost" )
   extensions+=( "streetsidesoftware.code-spell-checker" )
   extensions+=( "streetsidesoftware.code-spell-checker-portuguese-brazilian" )
   extensions+=( "eamodio.gitlens" )
   extensions+=( "moyu.snapcode" )
   extensions+=( "formulahendry.auto-rename-tag" )
   extensions+=( "dbaeumer.vscode-eslint" )
   extensions+=( "yoavbls.pretty-ts-errors" )

   installed_extensions=$(code --list-extensions)

   for ext in "${extensions[@]}"; do
      echo "${installed_extensions[@]}" | grep -iq $ext
      already_installed=$?

      if [[ $already_installed -ne 0 ]]; then
         log action "installing $ext"
         code --install-extension $ext
      else
         log warn "code extension $ext already installed. skipping"
      fi
   done
}
