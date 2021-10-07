#!/bin/bash

alias mv="mv -iv"
alias cp="cp -iv"

docker() {
 if [ "$*" == "ps" ]; then
  command docker ps --format "table {{.Image}}\t{{.Status}}\t{{.Names}}"
 else
  command docker "$@"
 fi
}

repeat() {
 [ "$#" -ne 1 ] && echo "Can only take one single-quoted argument" && return 1
 TempFile=$(mktemp)
 echo "#!/bin/bash" > "$TempFile"
 echo "$1" >> "$TempFile"
 chmod a+x "$TempFile"
 while true; do
   source "$TempFile"
   [ -z "$REPEATSILENT" ] && echo "** repeat: Command exited"
   sleep 2
 done
}

disk() {
 df -h | grep -e "/dev/sda1\|Filesystem"
}

rdisk() {
 REPEATSILENT="YES" repeat 'clear;disk'
}

ip() {
 ifconfig | grep --after 2 enp0s3
}

gitgrep() {
 echo "Use git log -p and '/' and 'n' for an interactive search"
}

gitsearch() {
 # Search git commit content
 commits=$(git log -S "$1" --oneline | awk '{print $1;}')
 for commit in $commits; do
  printf "\n"
  git show --quiet "$commit" --date=short --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'
  git log --patch --color=always "${commit}^..$commit" | grep --color=never "$1"
 done
}

title() {
 printf "\033]0; %s \a" "$1"
}

restartdisplaymanager() {
 sudo systemctl restart display-manager
}

setresolution() {
  Modeline=$(cvt "$1" "$2" | grep Modeline | cut -c10-)
  Mode=$(echo "$Modeline" | awk '{print $1;}')
  echo Configuring "$Mode" = "'""$Modeline""'"
  xrandr --newmode $Modeline &> /dev/null
  xrandr --addmode Virtual1 $Mode
  xrandr --output Virtual1 --mode $Mode
}

# Print disk usage when starting shell
disk
