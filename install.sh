#!/bin/bash

dir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd -P "${dir}" || exit 1
BASH_LOADED_FILE=${BASH_LOADED_FILE:-${BASH_SOURCE[0]}}

cd ..

# Link dotfiles
declare dotfilesDir=dotfiles
[ -d .dotfiles ] && dotfilesDir=.dotfiles

if [ -d "${dotfilesDir}" ]; then

ln -sf "${dotfilesDir}"/.bash_aliases .bash_aliases

# Get default git settings.
GIT_USER_EMAIL=$(git config user.email)
GIT_USER_NAME=$(git config user.name)
GIT_CRED_HELPER=$(git config credential.helper)

cp -f "${dotfilesDir}"/.gitconfig .gitconfig

# Reset to default git configs.
git config --global user.email "${GIT_USER_EMAIL}"
git config --global user.name "${GIT_USER_NAME}"
git config --global credential.helper "${GIT_CRED_HELPER}"
git config --global init.defaultBranch main
git config --global pull.ff only

fi
