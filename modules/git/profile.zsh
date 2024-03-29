#!/bin/zsh

## git completions
# SOURCE "$DOTFILES/scripts/.git-completion.bash"
# SOURCE "$DOTFILES/scripts/hub.bash_completion.sh"
SOURCE "$DOTFILES/scripts/git-prompt.sh"

## git aliases

alias gfg="git ls-files | grep"
alias gfp="gfg package.json"

alias hgo=github_go
alias hpr="hub pull-request"
alias prs="hub pr list"

# set $MAIN_BRANCH env based on the current git repo
function update_main_branch() {
  # first check for explicit config
  local explicit;
  explicit=$(git config --get x.main 2>/dev/null)
  if [[ $? -eq 0 ]]; then
    export MAIN_BRANCH=$explicit
    return
  fi

  # second, infer from present branches
  local branches;
  branches=("${(@f)$(git branch --list --no-color --format='%(refname:short)' 'ma*' 2>/dev/null)}")

  if (($branches[(Ie)main])); then
    export MAIN_BRANCH=main
    return
  fi

  if (($branches[(Ie)master])); then
    export MAIN_BRANCH=master
    return
    # if both are defined, prefer main.
    # if you need to override, set `git config x.main`
  fi

  export MAIN_BRANCH=$(git config --get init.defaultBranch || echo "main")
}
update_main_branch
autoload -U add-zsh-hook
add-zsh-hook chpwd update_main_branch

function git-reset-main () {
  local MESSAGE
  local OUT
  MESSAGE="${*:-RESET} - rsm $(whatbranch)@$(git rev-parse --short HEAD) $(date +'%Y-%m-%dT%l:%M%z')"
  git stash push --include-untracked -m "$MESSAGE"
  git -c core.hooksPath=/dev/null checkout $MAIN_BRANCH # skip post-checkout hooks

  OUT=$(git fetch --force --tags origin $MAIN_BRANCH 2>&1)
  if [[ "$OUT" =~ "Could not resolve host" ]]; then
    if ! grep -q .biz /etc/resolv.conf; then
      echo "not connected to vpn"
      return 1
    fi
  fi
  git reset origin/$MAIN_BRANCH --hard
  git checkout # trigger post-checkout again
}
alias rsm="git-reset-main"



#plumbing
function is-git-clean () {
  if [[ $(git status --short 2>/dev/null | wc -l) -eq 0 ]]; then
    return
  fi
  return 1
}

# commands
function cam () {
  npm test &&
  git commit -am "$1"
}
function pull () {
  git pull origin $(whatbranch)
}
function push () {
  git push origin $(whatbranch)
}
function fush () {
  if [ $(whatbranch) == $MAIN_BRANCH ]; then
    echo "don't fush to $MAIN_BRANCH"
    printf '\a'
    return 1
  fi
  read -r -p "Really force push to $(whatbranch)? [y/N] " response
  case $response in
      [yY][eE][sS]|[yY])
          git push origin $(whatbranch) --force-with-lease
          ;;
      *)
          # do nothing
          return 1
          ;;
  esac
}
alias afush="git commit -a --amend && fush"
alias amf=afush

function tpush () {
  npm test &&
  git push origin $(whatbranch)
}

alias gsf="git show --name-only" # git show files



function workon () {
  # sanitize for $1 = asana url
  URL="$1"
  if [[ $1 == "" ]]; then
    read -p "Enter the asana task url: "
    URL="$REPLY"
  fi

  if [[ $URL != https://app.asana.com/* ]]; then
    echo not asana url
    return 1
  fi;

  TASK="$(basename $URL)"
  BRANCH="a$TASK"

  MARK work.workon -m "$URL"

  git fetch origin $MAIN_BRANCH >/dev/null 2>&1

  git branch | grep $BRANCH > /dev/null
  if [[ $? == 0 ]]; then
    # if branch exists, switch to it and fetch / rebase origin $MAIN_BRANCH
    git checkout $BRANCH
    git rebase origin/$MAIN_BRANCH
  else
    # if branch doesnt exist, init
    git checkout origin/$MAIN_BRANCH
    git checkout -b $BRANCH
    git commit --allow-empty -m "$USER began work on $URL"
  fi

}

function github_go(){
  git_root=$(git rev-parse --show-toplevel)
  case $git_root in
    "$CODE_HOME"*)
      repo=$(echo $git_root | sed "s|$CODE_HOME/||")
      echo going to $repo on github
      ;;
    "") # not git
      return 1
      ;;
    *)
      echo not in code home
      return 1;
      ;;
  esac

  if [[ $1 != "" ]]; then
    # with number, go to that PR
    url="https://github.com/$repo/pull/$1"
    echo opening $url
    open $url
    return
  fi

  #otherwise try opening the path
  branch=$(whatbranch)
  relpath=$(pwd | sed "s|$git_root/||")
  echo relpath $relpath
  url="https://github.com/$repo/tree/$branch/$relpath"
  echo opening $url
  open $url
  return
}
