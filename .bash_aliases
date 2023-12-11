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
        [        "$#" -ne 1 ] && echo "Can only take one single-quoted argument" && return 1
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

duh() {
        sudo du -h --max-depth 1 . | sort -h --reverse
}

disk() {
        df -h | grep --color=never -e "% /workspace\|Filesystem"
}

rdisk() {
        REPEATSILENT="YES" repeat 'clear;disk'
}

ipecho() {
        wget -qO- http://ipecho.net/
        echo
}

# Alias trunk to run in the nearest found directory.
trunk() {
        # Find a file path by traversing parent directories.
        findparentfile() {
                path=${PWD}
                while [ "${path}" != "" ] && [ ! -f "${path}/$1" ]; do path=${path%/*}; done
                echo "${path}/$1"
        }
        declare TRUNK= && TRUNK=$(findparentfile trunk)
        if [ -f "${TRUNK}" ]; then
                "${TRUNK}" "$@"
        else
                echo No trunk found with path: "${PWD}"
        fi
}

# Alias template_update to run from cmd-one_time_setup.
template_update() {
        # Find a file path by traversing parent directories.
        findparentfile() {
                path=${PWD}
                while [ "${path}" != "" ] && [ ! -f "${path}/$1" ]; do path=${path%/*}; done
                echo "${path}/$1"
        }
        declare DEVCONTAINERFILE= && DEVCONTAINERFILE=$(findparentfile .devcontainer/devcontainer.json)
        declare PROJECTDIR= && PROJECTDIR="$(realpath "$(dirname "${DEVCONTAINERFILE}")/..")"

        "${PROJECTDIR}"/.devcontainer/scripts/cmd-one_time_setup.sh -- update
}

# Alias version_check to run from cmd-one_time_setup.
version_checks() {
        # Find a file path by traversing parent directories.
        findparentfile() {
                path=${PWD}
                while [ "${path}" != "" ] && [ ! -f "${path}/$1" ]; do path=${path%/*}; done
                echo "${path}/$1"
        }
        declare DEVCONTAINERFILE= && DEVCONTAINERFILE=$(findparentfile .devcontainer/devcontainer.json)
        declare PROJECTDIR= && PROJECTDIR="$(realpath "$(dirname "${DEVCONTAINERFILE}")/..")"

        POST=1 "${PROJECTDIR}"/.devcontainer/scripts/cmd-one_time_setup.sh -- version_checks
}

# Alias tldr to update before use.
tldr() {
        command tldr --update &>/dev/null
        command tldr "$@"
}

# Interactively search commit content with the less pager.
gitsearch() {
        [ -z "$*" ] && echo Missing arguments to less. && return 1
        git log -p --color=always | less -Rc -p "$*"
}

# Commit log and diff preview.
gitlg() {
        # trunk-ignore(shellcheck/SC2016)
        declare PREVIEW_CMD='f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] && return 0; git show --color=always $1 ; }; f {}'
        git log --graph --color=always --format="%C(auto)%h %s %C(green)(%cr)" |
                fzf --ansi --no-sort --layout=reverse --tiebreak=index \
                        --bind "alt-k:preview-half-page-up,alt-j:preview-half-page-down" --header 'Press Alt + K and J to page up/down the preview' \
                        --preview "${PREVIEW_CMD}" --preview-window=right:60%
}

# Fuzzy search git messages and commit diffs.
gitf() {
        declare INITIAL_QUERY="$*"
        read -r FZF_DEFAULT_COMMAND <<'EOF'
git log -p --unified=0 --color=never --format="%H,%C(auto)%h %s %C(green)(%cr)" | awk -F, --re-interval '{if($1~/^[0-9a-f]{40}$/){h=$1}else{printf substr(h,0,7)}print}' | sed 's/^[0-9a-f]\{40\},//'
EOF
        # trunk-ignore-begin(shellcheck/SC2016)
        declare PREVIEW_CMD='f() { set -- $(echo -- "$@" | grep -o "[0-9a-f]\{7\}"); [ $# -eq 0 ] && return 0; git show --color=always $1; }; f {}'
        # trunk-ignore-end(shellcheck/SC2016)
        fzf --no-sort --ansi --layout=reverse \
                --bind "alt-k:preview-half-page-up,alt-j:preview-half-page-down" --header 'Press Alt + K and J to page up/down the preview' \
                --query "${INITIAL_QUERY}" \
                --preview "${PREVIEW_CMD}"
}

# Grep for strings (case-insensitive) in messages and commit diffs.
gitgrep() {
        # For some reason, the awk part of the command does not work when passed to fzf's change:reload:, meaning
        # that commit hashes disappear, so to make best use of this command an argument should be passed.
        [ -z "$*" ] && echo Missing arguments to less. && return 1
        declare INITIAL_QUERY="$*"
        read -r PREFIX <<'EOF'
git log -p --unified=0 --color=never --format="%H,%C(auto)%h %s %C(green)(%cr)" | awk -F, --re-interval '{if($1~/^[0-9a-f]{40}$/){h=$1}else{printf substr(h,0,7)}print}' | grep --color=always --ignore-case -F
EOF
        read -r POSTFIX <<'EOF'
| sed 's/^[0-9a-f]\{40\},//'
EOF
        # trunk-ignore-begin(shellcheck/SC2016)
        declare PREVIEW_CMD='f() { set -- $(echo -- "$@" | grep -o "[0-9a-f]\{7\}"); [ $# -eq 0 ] && return 0; git show --color=always $1; }; f {}'
        # trunk-ignore-end(shellcheck/SC2016)
        FZF_DEFAULT_COMMAND="${PREFIX} '${INITIAL_QUERY}' ${POSTFIX}" \
                fzf --disabled --ansi --layout=reverse \
                --bind "change:reload:${PREFIX} '{q}' ${POSTFIX}" \
                --bind "alt-k:preview-half-page-up,alt-j:preview-half-page-down" --header 'Press Alt + K and J to page up/down the preview' \
                --query "${INITIAL_QUERY}" \
                --preview "${PREVIEW_CMD}"
}

# Help output colorizer with bat.
help() {
        "$@" --help 2>&1 | bat --plain --language=help
}

# Watch memory of processes.
mem() {
        procs --sortd rss -w
}

# Watch cpu of processes.
cpu() {
        procs --sortd cpu --insert rss -w
}

# Simple process list with fzf, from https://github.com/junegunn/fzf.
psi() {
        # trunk-ignore-begin(shellcheck/SC2016)
        FZF_DEFAULT_COMMAND='ps -ef' \
                fzf --header-lines=1 --layout=reverse \
                --bind 'ctrl-r:reload(eval "$FZF_DEFAULT_COMMAND")' \
                --header 'Press CTRL-R to reload' --height=50%
        # trunk-ignore-end(shellcheck/SC2016)
}

# Ripgrep interactive search (from pwd by default) with fzf. Asks what to do with the file after.
rgi() {
        declare INITIAL_QUERY=""
        declare PREFIX="rg --hidden --column --line-number --no-heading --color=always --smart-case "
        declare PREVIEW_CMD=
        # trunk-ignore-begin(shellcheck/SC2016)
        PREVIEW_CMD=$(printf "%s" 'bat --color=always --style=numbers ' \
                '--highlight-line $(echo {} | cut -d: -f2) ' \
                '--line-range ' \
                '"$(( ($(echo {} | cut -d: -f2) - 10) > 0 ? ($(echo {} | cut -d: -f2) - 10) : 0 ))"' \
                ':"$(( $(echo {} | cut -d: -f2) + 10))" ' \
                '"$(echo {} | cut -d: -f1)"')
        # trunk-ignore-end(shellcheck/SC2016)
        declare selectedPath=
        selectedPath="$(FZF_DEFAULT_COMMAND="${PREFIX} '${INITIAL_QUERY}' '${1:-.}'" \
                fzf --disabled --ansi --layout=reverse --keep-right \
                --bind "change:reload:${PREFIX} {q} '${1:-.}' || true" \
                --bind "alt-k:preview-half-page-up,alt-j:preview-half-page-down" --header 'Press Alt + K and J to page up/down the preview' \
                --query "${INITIAL_QUERY}" \
                --preview "${PREVIEW_CMD}")"
        [ -z "${selectedPath}" ] && return 0
        # trunk-ignore(shellcheck/SC2001)
        selectedPath="$(echo "${selectedPath}" | sed 's/\([^:]*\).*/\1/')"
        printf "%s: Command to run with this argument?\n" "${selectedPath}"
        read -ra Command
        "${Command[@]}" "${selectedPath}"
}

# fd interactive search with fzf. Asks what to do with the file after.
fdi() {
        declare FD_ARGS= && [ -n "$1" ] && [ "$1" != "." ] && FD_ARGS="'$1'"
        declare stripCwdPrefix= && [ -z "${FD_ARGS}" ] && stripCwdPrefix="--strip-cwd-prefix "
        declare INITIAL_QUERY=""
        declare PREFIX="fd --hidden --exclude '.git' --exclude '.tmp' --exclude 'tmp' --no-ignore ${stripCwdPrefix}"
        declare PREVIEW_CMD="bat --color=always --style=numbers {}"
        declare selectedPath=
        selectedPath="$(FZF_DEFAULT_COMMAND="${PREFIX} '${INITIAL_QUERY}' ${FD_ARGS}" \
                fzf --disabled --ansi --layout=reverse --keep-right \
                --bind "change:reload:${PREFIX} {q} ${FD_ARGS} || true" \
                --bind "alt-k:preview-half-page-up,alt-j:preview-half-page-down" --header 'Press Alt + K and J to page up/down the preview' \
                --query "${INITIAL_QUERY}" \
                --preview "${PREVIEW_CMD}")"
        [ -z "${selectedPath}" ] && return 0
        # trunk-ignore(shellcheck/SC2001)
        selectedPath="$(echo "${selectedPath}" | sed 's/\([^:]*\).*/\1/')"
        printf "%s: Command to run with this argument?\n" "${selectedPath}"
        read -ra Command
        "${Command[@]}" "${selectedPath}"
}
