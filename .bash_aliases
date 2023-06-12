#!/bin/bash

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

repeat_fast() {
 [ "$#" -ne 1 ] && echo "Can only take one single-quoted argument" && return 1
 TempFile=$(mktemp)
 echo "#!/bin/bash" > "$TempFile"
 echo "$1" >> "$TempFile"
 chmod a+x "$TempFile"
 while true; do
   source "$TempFile"
   [ -z "$REPEATSILENT" ] && echo "** repeat: Command exited"
   sleep 0.1
 done
}

disk() {
 df -h | grep --color=never -e "% /workspace\|Filesystem"
}

rdisk() {
 REPEATSILENT="YES" repeat 'clear;disk'
}

ipecho() {
  wget -qO- http://ipecho.net/plain
  echo
}
