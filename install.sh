#!/bin/bash

# Link dotfiles
ln -s .dotfiles/.bash_aliases .bash_aliases

cp -f .dotfiles/.gitconfig .gitconfig

# Reset to default git configs.
git config --global --unset credential.helper
git config --global credential.helper "/usr/bin/gp credential-helper"
git config --global user.email "${GITPOD_GIT_USER_EMAIL}"
git config --global user.name "${GITPOD_GIT_USER_NAME}"
git config --global init.defaultBranch main
git config --global pull.ff only
