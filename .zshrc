export ZSH="/home/peam/.oh-my-zsh"
export PATH=$PATH:/usr/local/go/bin

ZSH_THEME="spaceship"

RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

plugins=(git)

source $ZSH/oh-my-zsh.sh

if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zdharma/fast-syntax-highlighting

LS_COLORS=$LS_COLORS:'ow=01;34:' ; export LS_COLORS

SPACESHIP_PROMPT_ORDER=(
  user      
  dir           
  host  
  git        
  package
  pyenv
  exec_time     
  line_sep  
  battery    
  vi_mode       
  jobs          
  exit_code     
  char          
)

SPACESHIP_USER_SHOW="false"

SPACESHIP_DIR_SUFFIX=" "
SPACESHIP_GIT_PREFIX="➜ "

SPACESHIP_GIT_STATUS_SHOW=false
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false 

SPACESHIP_PROMPT_PREFIXES_SHOW=true
SPACESHIP_PROMPT_SUFFIXES_SHOW=true
SPACESHIP_PROMPT_DEFAULT_PREFIX="via "
SPACESHIP_PROMPT_DEFAULT_SUFFIX=" "

SPACESHIP_PACKAGE_PREFIX=""
SPACESHIP_PACKAGE_COLOR="215"

SPACESHIP_EXIT_CODE_SYMBOL="✘ "
SPACESHIP_EXIT_CODE_SHOW="true"
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "

unsetopt PROMPT_SP

export PATH="$PATH:/opt/yarn-[version]/bin"
export PATH="$PATH:/linuxbrew/.linuxbrew/bin/brew"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

. $HOME/.asdf/asdf.sh

alias -g zshconfig="code ~/.zshrc"

function fpush() {
   branch=`git branch --show-current`
   echo "pushing and setting upstream to ${GREEN}${branch}${NOCOLOR}"

   git push $1 --set-upstream origin $branch $2
}

function commit() {
   git add .
   files=`git diff --name-only --cached`
   echo "commiting files:"
   echo
   echo "${GREEN}${files}${NOCOLOR}"
   
   if test -z "$1"
   then
      commitmsg=`git branch --show-current | awk '{gsub("/",": "); print}' | awk '{gsub("-"," "); print}'`
   else
      commitmsg="$1"
   fi
   
   echo
   echo "with message ${GREEN}${commitmsg}${NOCOLOR}"
   echo "${YELLOW}please confirm${NOCOLOR} [${GREEN}y${NOCOLOR}/${RED}n${NOCOLOR}]"

   if read -q "choice?"; then
      echo

      git commit -m "${commitmsg}"

   else
      echo
      echo "${RED}Exiting...${NOCOLOR}"
      git reset
   fi
}


function checkout() {
   git checkout master
   git pull --rebase --quiet
   git branch | xargs git branch -D
}


function chrome-dev() {
   echo "${GREEN}Running chrome in dev mode...${NOCOLOR}"
   google-chrome --args --user-data-dir="/home/$(whomai)" --multi-profiles --purge-memory-button --start-maximized --disable-translate --ignore-certificate-errors --disable-web-security http://localhost:3000
}

function unreleasedPrs() {
   git fetch --tags

   author=`git config user.email`

   if test -z "$1"
   then
      tag_to_compare=`git describe --abbrev=0 --tags`
   else
      tag_to_compare="$1"
   fi

   git log $tag_to_compare..master --oneline --author=$author
}
