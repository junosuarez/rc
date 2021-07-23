#!/bin/bash

set -x

MASTER_BRANCH="master"
CURRENT_BRANCH="$(git branch --show-current)"

# default to master branch
DEFAULT_MAIN_BRANCH=$MASTER_BRANCH
# if master branch does not exist, fallback to main
if [[ "$(git branch --list "$MASTER_BRANCH")" == "" ]]; then
  DEFAULT_MAIN_BRANCH="main"
fi

TARGET_BRANCH=${1:-$CURRENT_BRANCH}
SOURCE_BRANCH=${2:-$DEFAULT_MAIN_BRANCH}

if [[ "$CURRENT_BRANCH" == "$MASTER_BRANCH" ]]; then
  git pull --no-tags origin "$SOURCE_BRANCH"
else
  git fetch --no-tags origin "$SOURCE_BRANCH":"$SOURCE_BRANCH"
fi

git rebase "$SOURCE_BRANCH" "$TARGET_BRANCH"
