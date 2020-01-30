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

df -h | grep -e "/dev/sda1\|Filesystem"

