# utility functions that can be sourced by scripts

function hdr() {
    local msg="$1"
    printf "================================================================================\n"
    printf "%s\n" "$msg" | sed 's/^/=   /'
    printf "================================================================================\n"
}
function verbose () {
    [[ $_VERBOSITY -eq 1 ]] && return 0 || return 1
}
export -f hdr
