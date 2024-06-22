#!/usr/bin/env bash
shopt -s expand_aliases

function install_code {
   if ! command -v code &> /dev/null; then
      gum_log error "make sure vscode is installed and the code command is added to PATH"
      exit 1
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
   extensions+=( "miguelsolorio.fluent-icons" )
   extensions+=( "drcika.apc-extension" )
   extensions+=( "rust-lang.rust-analyzer" )

   installed_extensions=$(code --list-extensions)

   for ext in "${extensions[@]}"; do
      echo "${installed_extensions[@]}" | grep -iq $ext
      already_installed=$?

      if [[ $already_installed -ne 0 ]]; then
         gum_log info "installing $ext"
         code --install-extension $ext
      else
         gum_log warn "code extension $ext already installed. skipping"
      fi
   done
}
