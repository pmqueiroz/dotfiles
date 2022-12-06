export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

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
