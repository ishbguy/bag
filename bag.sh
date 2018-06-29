#! /usr/bin/env bash
# Copyright (c) 2018 Herbert Shen <ishbguy@hotmail.com> All Rights Reserved.
# Released under the terms of the MIT License.

# source guard
[[ $BAG_SOURCED -eq 1 ]] && return
declare -gr BAG_SOURCED=1
declare -gr BAG_ABS_SRC="$(realpath "${BASH_SOURCE[0]}")"
declare -gr BAG_ABS_DIR="$(dirname "$BAG_ABS_SRC")"

shopt -s extglob
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
BAG_SUBCMDS_HELP[update]="update a bag"
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
Get more infomation from <$BAG_URL>.
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

# ANSI 8 colors
declare -gA BAG_ANSI_COLOR
BAG_ANSI_COLOR[black]=30
BAG_ANSI_COLOR[red]=31
BAG_ANSI_COLOR[green]=32
BAG_ANSI_COLOR[yellow]=33
BAG_ANSI_COLOR[blue]=34
BAG_ANSI_COLOR[magenta]=35
BAG_ANSI_COLOR[cyan]=36
BAG_ANSI_COLOR[white]=37
BAG_ANSI_COLOR[default]=39

BAG_ANSI_COLOR[bg_black]=40
BAG_ANSI_COLOR[bg_red]=41
BAG_ANSI_COLOR[bg_green]=42
BAG_ANSI_COLOR[bg_yellow]=43
BAG_ANSI_COLOR[bg_blue]=44
BAG_ANSI_COLOR[bg_magenta]=45
BAG_ANSI_COLOR[bg_cyan]=46
BAG_ANSI_COLOR[bg_white]=47
BAG_ANSI_COLOR[bg_default]=49

# ANSI color set
BAG_ANSI_COLOR[bold]=1
BAG_ANSI_COLOR[dim]=2
BAG_ANSI_COLOR[underline]=4
BAG_ANSI_COLOR[blink]=5
BAG_ANSI_COLOR[invert]=7
BAG_ANSI_COLOR[hidden]=8

# ANSI color reset
BAG_ANSI_COLOR[reset]=0
BAG_ANSI_COLOR[reset_bold]=21
BAG_ANSI_COLOR[reset_dim]=22
BAG_ANSI_COLOR[reset_underline]=24
BAG_ANSI_COLOR[reset_blink]=25
BAG_ANSI_COLOR[reset_invert]=27
BAG_ANSI_COLOR[reset_hidden]=28

__bag_set_color() {
    local color="${BAG_ANSI_COLOR[default]}"
    __bag_has_map BAG_ANSI_COLOR "$1" && color="${BAG_ANSI_COLOR[$1]}"
    printf '\x1B[%sm' "$(__bag_has_map BAG_ANSI_COLOR "$2" \
        && echo "$color;${BAG_ANSI_COLOR[$2]}" || echo "$color")"
}
__bag_color_echo() {
    local color=default
    local format
    if __bag_has_map BAG_ANSI_COLOR "$1"; then
        color="$1"; shift;
        __bag_has_map BAG_ANSI_COLOR "$1" \
            && { format="${BAG_ANSI_COLOR[$1]}"; shift; }
    fi
    __bag_set_color "$color" "$format"
    echo -e "$@"
    __bag_set_color reset
}

__bag_warn() { __bag_color_echo red "$@" >&2; return 1; }
__bag_is_local_repo() { [[ $1 =~ ^/([[:alnum:]_-/.]+)*$ ]]; }
__bag_is_remote_repo() { [[ $1 =~ ^[[:alnum:]_-][[:alnum:]_-.]*/[[:alnum:]_-.]+$ ]]; }
__bag_is_repo() { __bag_is_local_repo "$1" || __bag_is_remote_repo "$1"; }
__bag_defined() { declare -p "$1" &>/dev/null; }
__bag_defined_func() { declare -f "$1" &>/dev/null; }
__bag_encode_name() { echo "${1//[^[:alnum:]]/_}"; }
__bag_trim_space() {
    local str="$1"
    str="${str%%+( )}"
    str="${str##+( )}"
    echo "$str"
}
__bag_get_bag_name() {
    local bag_url="$(__bag_trim_space "$1")"
    bag_url="${bag_url%%+(/)}"
    echo "${bag_url##*/}"
}
__bag_has_bag() { [[ -n $1 && -d $BAG_BASE_DIR/$1 ]]; }
__bag_has_map() { local -n map="$1"; shift; [[ -n $1 && -n ${map[$1]} ]]; }
__bag_has_mapfunc() {
    local -n map="$1"
    __bag_has_map "$@" && __bag_defined_func "${map[$2]}"
}
__bag_has_cmd() { __bag_has_mapfunc BAG_SUBCMDS "$1"; }
__bag_has_downloader() { __bag_has_mapfunc BAG_DOWNLOADER "$1"; }

declare -gar BAG_REQUIRES=(git)
for req in "${BAG_REQUIRES[@]}"; do
    hash "$req" &>/dev/null || __bag_warn "bag need '$req'." || return 1
done

bag_version() { echo "$BAG_VERSION"; }
bag_help() { echo "$BAG_HELP"; }
bag_base() { [[ -n $1 ]] && __bag_is_local_repo "$1" && BAG_BASE_DIR="$1"; }
bag_plug() { [[ -n $bag ]] && BAG_PLUGINS+=("$bag"); }
bag_list() { [[ -f $BAG_BASE_DIR/bags ]] && cat "$BAG_BASE_DIR/bags"; }

__bag_update_path() {
    local -a bags=($(bag list))
    for bag_url in "${bags[@]}"; do
        local bag="$BAG_BASE_DIR/$(__bag_get_bag_name "${bag_url##*:}")"
        PATH+=":$bag"
        [[ -d $bag/bin ]] && PATH+=":$bag/bin"
    done
    export PATH
}

__bag_load_plugins() {
    for plug_url in "${BAG_PLUGINS[@]}"; do
        local plug="$(__bag_get_bag_name "${plug_url##*:}")"
        [[ -e $BAG_BASE_DIR/$plug/autoload ]] || continue
        for script in "$BAG_BASE_DIR/$plug"/autoload/*.sh; do
            [[ -f $script ]] && source "$script"
        done
    done
}

bag_load() {
    __bag_update_path
    __bag_load_plugins
}

bag_downloader_git() {
    local bag_opt="$1"
    local bag_url="${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) git clone "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) (cd "$BAG_BASE_DIR/$bag" && git pull) ;;
        *) __bag_warn "No such option: $bag_opt" ;;
    esac
}

bag_downloader_github() {
    local bag_opt="$1"
    local bag_url="https://github.com/${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) git clone "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) (cd "$BAG_BASE_DIR/$bag" && git pull) ;;
        *) __bag_warn "No such option: $bag_opt" ;;
    esac
}

bag_downloader_local() {
    local bag_opt="$1"
    local bag_url="${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) cp -r "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) cp -r "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        *) __bag_warn "No such option: $bag_opt" ;;
    esac
}

bag_downloader_link() {
    local bag_opt="$1"
    local bag_url="${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) ln -s "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) ;;
        *) __bag_warn "No such option: $bag_opt" ;;
    esac
}

bag_install() {
    local -a bags=("$@")
    [[ ${#bags[@]} -eq 0 ]] && bags=("${BAG_PLUGINS[@]}")
    [[ -d $BAG_BASE_DIR ]] || mkdir "$BAG_BASE_DIR"
    for bag_url in "${bags[@]}"; do
        bag_url="${bag_url%%+(/)}"
        local bag="$(__bag_get_bag_name "${bag_url##*:}")"

        __bag_has_downloader "${bag_url%%:*}" \
            || __bag_warn "Does not support '${bag_url%%:*}' to download." || continue
        ! __bag_has_bag "$bag" \
            || __bag_warn "Already exist bag: $bag" || continue

        __bag_color_echo yellow "Install $bag_url..."
        "${BAG_DOWNLOADER[${bag_url%%:*}]}" install "$bag_url" \
            && echo "$bag_url" >>"$BAG_BASE_DIR/bags" \
            || __bag_warn "Failed to install $bag_url"
    done
}

bag_update() {
    local -a bags=("$@")
    [[ ${#bags[@]} -eq 0 ]] && bags=($(bag list))
    for bag_url in "${bags[@]}"; do
        local bag="$(__bag_get_bag_name "${bag_url##*:}")"
        local bag_old="$(sed -rn '/'"\\/$bag"'/p' "$BAG_BASE_DIR/bags" 2>/dev/null)"

        __bag_has_downloader "${bag_old%%:*}" \
            || __bag_warn "Does not support '${bag_old%%:*}' to download." || continue
        [[ $bag_old =~ ${bag_url%%/} ]] && __bag_has_bag "$bag" \
            || __bag_warn "No such bag: $bag_url" || continue

        __bag_color_echo yellow "Update $bag_old..."
        "${BAG_DOWNLOADER[${bag_old%%:*}]}" update "$bag_old" \
            || __bag_warn "Failed to update $bag_old"
    done
}

bag_uninstall() {
    for bag_url in "$@"; do
        local bag="$(__bag_get_bag_name "$bag_url")"
        __bag_has_bag "$bag" || __bag_warn "No such bag: $bag" || continue
        __bag_color_echo yellow "Uninstall $bag..."
        rm -rf "$BAG_BASE_DIR/$bag" && sed -ri '/'"\\/$bag"'$/d' "$BAG_BASE_DIR/bags"
    done
}

bag() {
    local cmd="$1"; shift
    __bag_has_cmd "$cmd" \
        || { __bag_warn "No such command: '$cmd'"; "${BAG_SUBCMDS[help]}"; return 1; }
    "${BAG_SUBCMDS[$cmd]}" "$@"
}

[[ ${FUNCNAME[0]} == "main" ]] \
    && bag "$@"

# vim:set ft=sh ts=4 sw=4:
