#! /usr/bin/env bash
# Copyright (c) 2018 Herbert Shen <ishbguy@hotmail.com> All Rights Reserved.
# Released under the terms of the MIT License.

# source guard
[[ $BAG_SOURCED -eq 1 ]] && return
declare -gr BAG_SOURCED=1
declare -gr BAG_ABS_SRC="$(realpath "${BASH_SOURCE[0]}")"
declare -gr BAG_ABS_DIR="$(dirname "$BAG_ABS_SRC")"

declare -g  BAG_AUTHOR=ishbguy
declare -g  BAG_PRONAME=bag
declare -g  BAG_VERSION='v0.0.1'
declare -g  BAG_URL='https://github.com/ishbguy/bag'
declare -g  BAG_BASE_DIR="$HOME/.$BAG_PRONAME"
declare -g  BAG_CONFIG="$HOME/.${BAG_PRONAME}rc"
declare -ga BAG_PLUGINS
declare -gA BAG_SUBCMDS_HELP
BAG_SUBCMDS_HELP[help]="show help message, like this output"
BAG_SUBCMDS_HELP[version]="show version number"
BAG_SUBCMDS_HELP[base]="change bags' download directory"
BAG_SUBCMDS_HELP[plug]="add a bag plugin"
BAG_SUBCMDS_HELP[load]="load all plugins and update PATH"
BAG_SUBCMDS_HELP[install]="install a bag"
BAG_SUBCMDS_HELP[uninstall]="uninstall a bag"
BAG_SUBCMDS_HELP[list]="list installed bags"
__bag_subcmds_help() {
    local -n __subcmds="$1"
    local -a sorted=($(echo "${!__subcmds[@]}" | sed -r 's/\s+/\n/g' | sort))
    for cmd in "${sorted[@]}"; do
        printf '    %-10s %s\n' "$cmd" "${__subcmds[$cmd]}"
    done
}
declare -g  BAG_HELP=$(cat <<EOF
$BAG_PRONAME $BAG_VERSION
$BAG_PRONAME <subcmd> [somthing]

subcmds:
$(__bag_subcmds_help BAG_SUBCMDS_HELP)

This program is released under the terms of MIT License.
EOF
)
declare -gA BAG_SUBCMDS
for cmd in "${!BAG_SUBCMDS_HELP[@]}"; do
    BAG_SUBCMDS[$cmd]="bag_$cmd"
done
declare -gA BAG_DOWNLOADER
BAG_DOWNLOADER[git]="bag_downloader_git"
BAG_DOWNLOADER[github]="bag_downloader_github"
BAG_DOWNLOADER[gh]="bag_downloader_github"
BAG_DOWNLOADER[file]="bag_downloader_local"
BAG_DOWNLOADER[local]="bag_downloader_local"
BAG_DOWNLOADER[link]="bag_downloader_link"

__bag_warn() { echo "$@" >&2; return 1; }
__bag_is_local_repo() { [[ $1 =~ ^/([[:alnum:]_-/.]+)*$ ]]; }
__bag_is_remote_repo() { [[ $1 =~ ^[[:alnum:]_-][[:alnum:]_-.]*/[[:alnum:]_-.]+$ ]]; }
__bag_is_repo() { __bag_is_local_repo "$1" || __bag_is_remote_repo "$1"; }
__bag_defined() { declare -p "$1" &>/dev/null; }
__bag_defined_func() { declare -f "$1" &>/dev/null; }
__bag_encode_name() { echo "${1//[^[:alnum:]]/_}"; }
__bag_trim() {
    local str="$1"
    str="${str%%+( )}"
    str="${str##+( )}"
    echo "$str"
}

declare -gar BAG_REQUIRES=(git)
for req in "${BAG_REQUIRES[@]}"; do
    hash "$req" &>/dev/null || __bag_warn "bag need '$req'." || return 1
done


bag_help() { echo "$BAG_HELP"; }
bag_version() { echo "$BAG_VERSION"; }

bag_base() {
    [[ -n $1 && -d $1 ]] || __bag_warn "No such directory: $1" || return 1
    BAG_BASE_DIR="$1"
}

bag_plug() {
    local bag="$(__bag_trim "$1")"
    bag="${bag%%/}"
    [[ -n $bag ]] && BAG_PLUGINS+=("$bag")
}

bag_update_path() {
    local -a bags=($(bag list))
    for bag in "${bags[@]}"; do
        bag="$BAG_BASE_DIR/$(basename "${bag#*:}")"
        PATH+=":$bag"
        [[ -d $bag/bin ]] && PATH+=":$bag/bin"
    done
    export PATH
}

bag_load_plugins() {
    for plug in "${BAG_PLUGINS[@]}"; do
        plug="$(basename "${plug#*:}")"
        [[ -e $BAG_BASE_DIR/$plug/autoload ]] || continue
        for script in "$BAG_BASE_DIR/$plug"/autoload/*.sh; do
            [[ -f $script ]] && source "$script"
        done
    done
}

bag_load() {
    bag_update_path
    bag_load_plugins
}

bag_downloader_git() {
    local bag_url="${1#*:}"
    local bag_name=$(basename "$bag_url")
    local base_dir="$2"

    git clone "$bag_url" "$base_dir/$bag_name"
}

bag_downloader_github() {
    local repo="${1#*:}"
    local bag_name=$(basename "$repo")
    local base_dir="$2"

    git clone "https://github.com/$repo" "$base_dir/$bag_name"
}

bag_downloader_local() {
    local bag_path="${1#*:}"
    local bag_name=$(basename "$bag_path")
    local base_dir="$2"

    echo "Copy $bag_path to $base_dir/$bag_name"
    cp -r "$bag_path" "$base_dir/$bag_name"
}

bag_downloader_link() {
    local bag_path="${1#*:}"
    local bag_name=$(basename "$bag_path")
    local base_dir="$2"

    echo "Link $bag_path to $base_dir/$bag_name"
    ln -s "$bag_path" "$base_dir/$bag_name"
}

bag_install() {
    local -a bags=("$@")
    [[ ${#bags[@]} -eq 0 ]] && bags=("${BAG_PLUGINS[@]}")
    for bag in "${bags[@]}"; do
        bag="$(__bag_trim "$bag")"
        bag="${bag%%/}"
        bag_name="$(basename "$bag")"

        [[ -n ${BAG_DOWNLOADER[${bag%%:*}]} ]] \
            && __bag_defined_func "${BAG_DOWNLOADER[${bag%%:*}]}" \
            || __bag_warn "Does not support '${bag%%:*}' to download." || continue

        [[ -d $BAG_BASE_DIR ]] || mkdir "$BAG_BASE_DIR"
        [[ ! -e $BAG_BASE_DIR/$bag_name ]] \
            || __bag_warn "Already exist bag: $bag_name" || continue

        "${BAG_DOWNLOADER[${bag%%:*}]}" "$bag" "$BAG_BASE_DIR" \
            && echo "$bag" >>"$BAG_BASE_DIR/bags"
    done
}

bag_uninstall() {
    for bag in "$@"; do
        bag="$(__bag_trim "$bag")"
        bag="${bag%%/}"
        bag_name="$(basename "$bag")"

        [[ -d $BAG_BASE_DIR/$bag_name ]] || __bag_warn "No such bag: $1" || continue

        rm -rf "$BAG_BASE_DIR/$bag_name" \
            && sed -ri '/'"$bag_name"'$/d' "$BAG_BASE_DIR/bags"
    done
}

bag_list() { [[ -f $BAG_BASE_DIR/bags ]] && cat "$BAG_BASE_DIR/bags"; }

bag() {
    local cmd="$1"; shift
    [[ -z $cmd ]] \
        && { __bag_warn "Need at least a command."; "${BAG_SUBCMDS[help]}"; return 1; }
    [[ -z ${BAG_SUBCMDS[$cmd]} ]] \
        && { __bag_warn "No such command: $cmd"; "${BAG_SUBCMDS[help]}"; return 1; }

    __bag_defined_func "${BAG_SUBCMDS[$cmd]}" \
        && "${BAG_SUBCMDS[$cmd]}" "$@"
}

[[ ${FUNCNAME[0]} == "main" ]] \
    && bag "$@"

# vim:set ft=sh ts=4 sw=4:
