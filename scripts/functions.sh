# POSIX-compliant utility functions that can be sourced by scripts

hdr() {
    local msg="$1"
    printf "================================================================================\n"
    printf "%s\n" "$msg" | sed 's/^/=   /'
    printf "================================================================================\n"
}
verbose () {
    [[ $_VERBOSITY -eq 1 ]] && return 0 || return 1
}
step() {
    printf "\n${BLUE}%s${RESET}\n" "$@"
}
fatal() {
    printf "FATAL: ${RED}${BOLD}%s${RESET}\n" "$@"
    exit 1
}
dumpfile() {
    printf "\n%s:\n" "$1"
    sed 's/^/    /' "$1"
}
assert_pwd_is_root() {
    # Validate we're in root path of repo working tree 
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    if [ "$ROOT_DIR" != "$(pwd)" ]; then
        echo "ERROR: pwd must be the root of the containing repository (expected $ROOT_DIR, got $(pwd))!"
        exit 1
    fi
}
