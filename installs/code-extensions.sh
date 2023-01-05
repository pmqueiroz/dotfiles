#!/bin/bash
source helpers.sh

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
extensions+=( "GitHub.copilot" )
extensions+=( "formulahendry.auto-rename-tag" )

installed_extensions=$(code --list-extensions)

for ext in "${extensions[@]}"; do
    log action "trying to install $ext"

    echo "${installed_extensions[@]}" | grep -iq $ext
    already_installed=$?

    if [[ $already_installed -ne 0 ]]; then
        code --install-extension $ext
    else
        log error "code extension $ext already installed. skipping"
    fi
done
