# utility functions that can be sourced by scripts

function hdr() {
    printf "================================================================================\n"
    sed 's/^/=   /' <<<"$1"
    printf "================================================================================\n"
}
function verbose () {
    [[ $_VERBOSITY -eq 1 ]] && return 0 || return 1
}
export -f hdr
