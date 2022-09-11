
# dotfiles management workflow
MAIN_BRANCH="main"
alias gitrc="git --git-dir=$DOTFILES/.git --work-tree=$DOTFILES"
alias pullrc="gitrc pull origin $MAIN_BRANCH"

function desc() {
  ## this abuses the aliases as an exported hashtable, since you cant well use env
  if [[ $# -eq 1 ]]; then
    # get
    echo $(alias -m "desc-$1*") | sed -e "s/desc-$1=//" -e "s/'//g"
  else
    # set
    alias "desc-$1"="$2"
  fi
}

desc rc-source "reload dotfile (alias: rcs)"
function rc-source () {
  source ~/.zshrc
  MARK dotfiles.resource
  printf "reloaded ~/.zshrc in %sms\n" $DOTFILES_SPAN_START_MS
}
alias rcs="rc source"

desc rc-edit "edit dotfiles (alias: rce)"
function rc-edit () {
  edit $DOTFILES
}
alias rce="rc edit"

desc rc-profile "reload shell with profiling"
function rc-profile () {
  DOTFILES_PROFILE=true
  rc-source
}

function _rc-commit () {
  message="${1:-save settings}"
  gitrc commit --quiet -am "$message" || return 1
  MARK dotfiles.saved
}
alias pushrc="gitrc push origin $MAIN_BRANCH"

desc rc-todo "see list (empty) or add a todo item (vararg)"
function rc-todo () {
  if [[ $# -eq 0 ]]; then
    # get
    command cat $DOTFILES/TODO
  else
    # add
    local todo="$@"
    echo "- [] $todo" >> $DOTFILES/TODO
    _rc-commit "todo: $todo" && echo added
  fi
}

function rc-commit() {
  local untracked=$(gitrc status --porcelain=1 | grep -e '^??')
  if [[ $untracked != "" ]]; then
    gitrc status
    echo
    echo "use 'gitrc add -A' if you want to continue"
    return 1
  fi

  # grab all args as one to allow for use without quotes
  local message="$*"
  _rc-commit "$message" || return 1
}
alias rcc="rc-commit"

desc rc-tip "show a random cool thing these dotfiles can do"
function rc-tip () {
  # ugh what a silly way to shell unescape... works for now though
  local aliases=$(alias | grep -v desc- | sed -E "s|^([^=]*)='?([^'].*[^'])'?\$|alias: \1 \t [\2]|")
  local tips=$(cat $DOTFILES/modules/rc/tips.txt)
  echo ""
  echo "    拾 $(echo "$aliases$tips" | shuf -n 1 -)"
  echo ""
}

desc rc-sync "do some things"
function rc-sync () {
  # TODO: this doesnt work, need to make an inner rc-source # ensure we have the latest
  local untracked=$(gitrc status --porcelain=1 | grep -e '^??')
  if [[ $untracked != "" ]]; then
    gitrc status
    echo
    echo "use 'gitrc add -A' if you want to continue"
    return 1
  fi

  local om1=$(gitrc rev-parse origin/$MAIN_BRANCH)
  gitrc fetch origin $MAIN_BRANCH --quiet
  local om2=$(gitrc rev-parse origin/$MAIN_BRANCH)
  if [[ $om1 != $om2 ]]; then
    echo updating with remote changes
    gitrc rebase origin/$MAIN_BRANCH
    rc-init # TODO: detect when this is necessary
    rc-source
  fi
  rc-commit "$*"
  pushrc
  return 0
}

function rc-subsync () {
  local message="$*"
  #TODO maybe be safer adding? show which modules affected?
  git submodule foreach git add -A
  git submodule foreach git commit -am "$message"
  git submodule foreach git push
  rc-commit "$message"
  pushrc
}

desc rc-graph "see modules with graphviz"
function rc-graph () {
  zsh $DOTFILES/lib/graph.zsh $@
}

desc rc-init "initialize modules"
function rc-init() {
  zsh $DOTFILES/init.zsh $@
}

desc rc-brew "install brew dependencies"
function rc-brew() {
  zsh $DOTFILES/lib/brew.zsh $@
}

desc rc-check "validate modules"
function rc-check() {
  zsh $DOTFILES/lib/check.zsh
}

desc rc-log "see changes to dotfiles"
function rc-log() {
  local format='%C(dim white)%h%Creset %C(bold white)%>(15)%ar%Creset %Cgreen%d%Creset %s'
  gitrc log --pretty=format:"$format" --color=always
}


desc rc-new "scaffold a new module"
function rc-new() {
  local name=$1
  if [[ $name == "" ]]; then
    echo "usage: rc-new <name>"
    return 1
  fi

  if [[ -d $DOTFILES/modules/$name ]]; then
    echo $name already exists
    return 1
  fi

  mkdir -p $DOTFILES/modules/$name
  touch $DOTFILES/modules/$name/info
  touch $DOTFILES/modules/$name/profile.zsh
  touch $DOTFILES/modules/$name/alias.zsh
  touch $DOTFILES/modules/$name/init.zsh
}


## the base command for managing dotfiles
function rc() {
  local command="$1"
  [[ $# -gt 0 ]] && shift

  if [[ "$command" == "" || "$command" =~ "help" ]]; then
    echo "usage: rc <command>"
    echo
    echo "  manage dotfiles, see https://github.com/junosuarez/rc"
    echo
    echo "commands:"
    for fn in ${(ok)functions[(I)rc-*]}; do
      local name=$(echo $fn | sed 's/rc-//')
      echo "  ${(r:8:)name}\t$(desc $fn)"
    done
    return 0
  fi

  "rc-$command" $@
}
