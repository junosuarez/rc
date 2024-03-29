#! /bin/zsh
# Ensure this file is idempotent!
source ~/.rc/lib/mod.zsh

function __initModule() {
  local module=$1
  local modpath=$DOTFILES/modules/$module

  STEP: "$module"

  if grep -q GIT: "$modpath/info"; then
    # LOG: $module has git submodules
    $DOTFILES/lib/init-submod.zsh $module
  fi

   if [[ -f $modpath/init.zsh ]]; then
    LOG: " init"
    source $modpath/init.zsh

    for F in $modpath/bin/*(N.); do
      local bname=$(basename $F)
      LOG: " linking bin: $bname"
      ln -sf $F ~/bin/$bname
    done

  fi
}

############
##

:
STEP: init profile
ln -sf $DOTFILES/.zshrc ~/.zshrc
mkdir -p ~/.config ~/bin


:
STEP: modules

ENTRY=${1:-main_profile}

__walkModules $ENTRY
for m in ${(o)MOD_USES}; do
  __initModule $m
done

# case $(uname) in
#   Darwin)
#     ;;
#   Linux)
#     ;;
# esac

DONE: 'init ok. optional: `rc brew`'
