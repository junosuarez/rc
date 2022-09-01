## navigation
##
alias ls="CLICOLOR_FORCE=1 ls -p -G" # show slashes after folders and color
alias ls="lsd --classify --group-dirs first " # https://github.com/Peltoche/lsd
alias less="less -R" # enable color
alias cls="clear && echo 🔎 && ls"
alias la="ls -a"
alias ll="ls -al"
alias ld="ls -A | grep -e ^\\." # list dotfiles
alias l="ls"
alias tarls="tar -tvf"
alias lst="tarls"
alias cd..="cd .."

## jump
##
alias co="cd ~/Code"
alias cj="cd ~/Code/junosuarez"
function ghub() {
  open "https://ghub.io/$1"
}
alias s="cd ~/workspace/source"
alias sw="cd ~/workspace/web"
alias sp="cd ~/Desktop/Projects"




## files
##
alias cat=bat # https://github.com/sharkdp/bat
alias batdiff="git diff --name-only --diff-filter=d | xargs bat --diff"


alias jid="jid > /dev/null" # https://github.com/simeji/jid

## code
##

alias edit=code
alias code-stable="$(which code)"
#alias code=code-insiders
alias c=code
alias c.="c ."
alias ij=intellij

## misc
##
alias blah="head /dev/urandom | base64"
alias lc="wc -l" #line count
alias join="paste -sd ',' -"

## docker
##
alias dps="docker ps --format 'table {{.Names}}\t{{.RunningFor}}' | (read; sort)"
alias dls="docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}' | (head; sort)"
