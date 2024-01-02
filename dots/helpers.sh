#!/bin/bash
declare -A options;

function load_options() {
   for opt in $@; do 
      if [[ $opt == --* ]]; then
         options[${opt:2}]=true
      fi
   done
}

logfile="peam_dotfiles_$(date +%Y%m%d_%H%M%S).log"

function _ {
   [ "${options[verbose]}" = true ] && eval $@ || eval $@ &>> $logfile
}

function loader {
   if [[ -t 0 ]]; then
      gum spin -s minidot --title="" -- $@
   else
      eval $@
   fi
}

function render_string {
   local template=$(cat)
   while [ $# -gt 0 ]; do
      template=${template//\{\{$1\}\}/$2}
      shift 2
   done
   echo "$template"
}
