alias mv="mv -iv"
alias cp="cp -iv"

docker() {
 if [[ $@ == "ps" ]]; then
  command docker ps --format "table {{.Image}}\t{{.Status}}\t{{.Names}}"
 else
  command docker "$@"
 fi
}

gitgrep() {
 echo Use git log -p and '/' and 'n' for an interactive search
 git log -G $1
}

gs() {
 git status
}

repeat() {
 [ "$#" -ne 1 ] && echo "Can only take one single-quoted argument" && return 1
 TempFile=$(tempfile)
 echo "#!/bin/bash" > "$TempFile"
 echo $1 >> "$TempFile"
 chmod a+x "$TempFile"
 while true; do
   source $TempFile
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

gitsearch() {
 commits=$(git log -S $1 --oneline | awk '{print $1;}')
 for commit in $commits; do
  printf "\n"
  git show --quiet --oneline $commit
  git log --patch --color=always ${commit}^..$commit | grep --color=never $1
 done
}

disk
