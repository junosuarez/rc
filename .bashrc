alias edit=subl
alias ls="ls -p" # show slashes after folders
alias ld="ls -A | grep -e ^\\." # list dotfiles
alias s=edit
alias s.="s ." # edit current directory

alias resource="source ~/.bashrc && echo loaded .bashrc"
DOTFILES="$HOME/.dotfiles"
alias editrc="edit $DOTFILES"
alias gitrc="git --git-dir=$DOTFILES/.git --work-tree=$DOTFILES"
alias pullrc="gitrc pull origin master"
alias commitrc="gitrc commit -am 'save settings'"
alias pushrc="gitrc push origin master"
alias syncrc="pullrc && commitrc && pushrc"

alias bode="babel-node -r"

alias cd..="cd .."

function cdl () {
  cd $1
  ls
}

alias timestamp="node -p 'Date.now()'"

alias g=git
alias gst="git status"
alias glog="git log"
alias gpom="git pull origin master"
alias whatbranch="git rev-parse --abbrev-ref HEAD"
alias save="git commit -am"
alias pwb="git rev-parse --abbrev-ref HEAD" #print working branch
alias cb="git checkout" #change branch

function pull () {
  git pull origin $(whatbranch)
}
function push () {
  git push origin $(whatbranch)
}

alias kapow="push && git checkout master && git merge ci && push && git checkout ci"

# eg `release major`, `release minor`, `release patch`
function release () {
  npm version $1
  git push origin master `git describe --tags`
}


alias npms="npm install --save"
alias npmr="npm run"
alias npmsd="npm install --save-dev"
alias dev="cd ~/dev; ls"


function whichVersion() {
  which $1
  $1 --version
}
alias wh=whichVersion

#work
alias deva="cd ~/dev/agilemd; ls; source ~/agile-env/apici.sh"
alias adenv="env | grep AD_"

function log() {
  local serial=$(ls | grep "$1" | wc -l | sed -e "s/\s*//")
  local file="$1.$serial.log"
  date "+%c" > $file
  echo "$*" >> $file
  echo "---" >> $file
  $* 2>&1 | tee -a $file ; local exitCode=${PIPESTATUS[0]}
  echo "---" >> $file
  echo "⇒ E$exitCode" >> $file
  return $exitCode
}

function error() {
  return $1
}

function npmrc() {
  local usage=`cat << EOF
  npmrc : list available profiles
  npmrc <name> : switch profile
  npmrc -c <name> : create a new profile
EOF`
  local user=$1
  if [ $# -eq 0 ]; then
    echo "$usage"
    echo 
    echo available profiles:
    ls ~/.npmrcs
    return 1
  fi

  if [ $user == "-c" ]; then
    local user=$2
    echo "making new user $user"
    touch ~/.npmrcs/$user
  fi

  if [ -e ~/npmrcs/$user ]; then
    echo "switching to user $user"
    ln -sf ~/.npmrcs/$user ~/.npmrc
  else
    echo "'$user' does not exist. use 'npmrc -c $user' to create it"
    return 1
  fi
}