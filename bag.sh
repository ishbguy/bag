#! /usr/bin/env bash
# Copyright (c) 2018-Present Herbert Shen <ishbguy@hotmail.com> All Rights Reserved.
# Released under the terms of the MIT License.

# source guard
[[ $BAG_SOURCED -eq 1 ]] && return
declare -gr BAG_SOURCED=1
declare -gr BAG_ABS_SRC="$(realpath "${BASH_SOURCE[0]}")"
declare -gr BAG_ABS_DIR="$(dirname "$BAG_ABS_SRC")"

shopt -s extglob

__bag_init_color() {
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
}

__bag_set_color() {
    local color="${BAG_ANSI_COLOR[default]}"
    __bag_has_map BAG_ANSI_COLOR "$1" && color="${BAG_ANSI_COLOR[$1]}"
    printf '\x1B[%sm' "$(__bag_has_map BAG_ANSI_COLOR "$2" \
        && echo "$color;${BAG_ANSI_COLOR[$2]}" || echo "$color")"
}
__bag_printc() {
    local color=default
    local format
    if __bag_has_map BAG_ANSI_COLOR "$1"; then
        color="$1"; shift;
        __bag_has_map BAG_ANSI_COLOR "$1" && { format="$1"; shift; }
    fi
    __bag_set_color "$color" "$format"
    echo -e "$@"
    __bag_set_color reset
}

__bag_warn() { __bag_printc yellow "$@" >&2; return 1; }
__bag_error() { __bag_printc red "$@" >&2; return 1; }
__bag_is_local_repo() { [[ $1 =~ ^/([[:alnum:]_/.-]+)*$ ]]; }
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
__bag_has_map() { local -n map="$1"; shift; [[ -n $1 && -n ${map[$1]} ]]; }
__bag_has_mapfunc() {
    local -n map="$1"
    __bag_has_map "$@" && __bag_defined_func "${map[$2]}"
}
__bag_require() {
    local -a missed=()
    for req in "$@"; do
        hash "$req" &>/dev/null || missed+=("$req")
    done
    local IFS=,
    [[ ${#missed[@]} -eq 0 ]] || __bag_error "bag needs: ${missed[*]}." || return 1
}
__bag_has_cmd() { __bag_has_mapfunc BAG_SUBCMDS "$1"; }
__bag_get_bag_name() {
    local bag_url="$(__bag_trim_space "$1")"
    bag_url="${bag_url%%+(/)}"
    echo "${bag_url##*/}"
}
__bag_has_bag() { [[ -n $1 && -d $BAG_BASE_DIR/$1 ]]; }

bag_version() { echo "$BAG_VERSION"; }
bag_help() {
    cat <<EOF
$BAG_PRONAME $BAG_VERSION
$BAG_PRONAME <subcmd> [somthing]

subcmds:
$(__bag_helper BAG_SUBCMDS_HELP)

downloaders:
$(__bag_helper BAG_DOWNLOADER_HELP)

bag proxy usage:

$(bag proxy help)

This program is released under the terms of MIT License.
Get more infomation from <$BAG_URL>.
EOF
}
bag_base() { [[ -n $1 ]] && __bag_is_local_repo "$1" && BAG_BASE_DIR="$1"; }
bag_plug() { [[ -n $1 ]] && BAG_PLUGINS+=("$1"); }
bag_list() { [[ -f $BAG_BASE_DIR/bags ]] && cat "$BAG_BASE_DIR/bags"; }
bag_edit() { [[ -f $BAG_BASE_DIR/bags ]] &&  "${EDITOR:-vim}" "$BAG_BASE_DIR/bags"; }

__bag_update_path() {
    local -a bags=($(bag list))
    for bag_url in "${bags[@]}"; do
        local bag="$BAG_BASE_DIR/$(__bag_get_bag_name "${bag_url##*:}")"
        [[ -d $bag/bin && ! $PATH =~ $bag/bin ]] && PATH+=":$bag/bin"
    done
    export PATH
}
__bag_load_plugins() {
    for plug_url in "${BAG_PLUGINS[@]}"; do
        local plug="$(__bag_get_bag_name "${plug_url##*:}")"
        [[ -e $BAG_BASE_DIR/$plug/autoload ]] || continue
        # FIXME: avoid to load a script for twice
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
    __bag_require git

    local bag_opt="$1"
    local bag_url="${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) git clone "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) (cd "$BAG_BASE_DIR/$bag" && git pull) ;;
        *) __bag_error "No such option: $bag_opt" ;;
    esac
}
bag_downloader_github() {
    __bag_require git

    local bag_opt="$1"
    local bag_url="https://github.com/${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) git clone "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) (cd "$BAG_BASE_DIR/$bag" && git pull) ;;
        *) __bag_error "No such option: $bag_opt" ;;
    esac
}
bag_downloader_gh() {
    bag_downloader_github "$@"
}
bag_downloader_local() {
    local bag_opt="$1"
    local bag_url="${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) cp -r "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) cp -r "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        *) __bag_error "No such option: $bag_opt" ;;
    esac
}
bag_downloader_file() {
    bag_downloader_local "$@"
}
bag_downloader_link() {
    local bag_opt="$1"
    local bag_url="${2#*:}"
    local bag=$(__bag_get_bag_name "$bag_url")

    case $bag_opt in
        install) ln -s "$bag_url" "$BAG_BASE_DIR/$bag" ;;
        update) ;;
        *) __bag_error "No such option: $bag_opt" ;;
    esac
}
__bag_init_downloader() {
    declare -gA BAG_DOWNLOADER_HELP
    BAG_DOWNLOADER_HELP[git]="downloader for git repo"
    BAG_DOWNLOADER_HELP[github]="downloader for github repo"
    BAG_DOWNLOADER_HELP[gh]="alias for github downloader"
    BAG_DOWNLOADER_HELP[local]="downloader for local file or directory"
    BAG_DOWNLOADER_HELP[file]="alias for local downloader"
    BAG_DOWNLOADER_HELP[link]="downloader for local file or directory as symbolic link"

    declare -gA BAG_DOWNLOADER
    for type in "${!BAG_DOWNLOADER_HELP[@]}"; do
        BAG_DOWNLOADER[$type]="bag_downloader_$type"
    done
}
__bag_has_downloader() { __bag_has_mapfunc BAG_DOWNLOADER "$1"; }

bag_install() {
    local -a bags=("$@")
    [[ ${#bags[@]} -eq 0 ]] && bags=("${BAG_PLUGINS[@]}")
    [[ -d $BAG_BASE_DIR ]] || mkdir -p "$BAG_BASE_DIR"
    for bag_url in "${bags[@]}"; do
        bag_url="${bag_url%%+(/)}"
        local bag="$(__bag_get_bag_name "${bag_url##*:}")"

        __bag_has_downloader "${bag_url%%:*}" \
            || __bag_error "Does not support '${bag_url%%:*}' to download." || continue
        ! __bag_has_bag "$bag" \
            || __bag_error "Already exist bag: $bag" || continue

        __bag_printc yellow "Installing $bag_url..."
        "${BAG_DOWNLOADER[${bag_url%%:*}]}" install "$bag_url" \
            && echo "$bag_url" >>"$BAG_BASE_DIR/bags" \
            || __bag_error "Failed to install $bag_url"
    done
}

bag_update() {
    local -a bags=("$@")
    [[ ${#bags[@]} -eq 0 ]] && bags=($(bag list))
    for bag_url in "${bags[@]}"; do
        local bag="$(__bag_get_bag_name "${bag_url##*:}")"
        local bag_old="$(sed -rn '/'"\\/$bag"'/p' "$BAG_BASE_DIR/bags" 2>/dev/null)"

        __bag_has_downloader "${bag_old%%:*}" \
            || __bag_error "Does not support '${bag_old%%:*}' to download." || continue
        [[ $bag_old =~ ${bag_url%%/} ]] && __bag_has_bag "$bag" \
            || __bag_error "No such bag: $bag_url" || continue

        __bag_printc yellow "Updating $bag_old..."
        "${BAG_DOWNLOADER[${bag_old%%:*}]}" update "$bag_old" \
            || __bag_error "Failed to update $bag_old"
    done
}

bag_uninstall() {
    for bag_url in "$@"; do
        local bag="$(__bag_get_bag_name "$bag_url")"
        __bag_has_bag "$bag" || __bag_error "No such bag: $bag" || continue
        __bag_printc yellow "Uninstall $bag..."
        rm -rf "$BAG_BASE_DIR/$bag" && sed -ri '/'"\\/$bag"'$/d' "$BAG_BASE_DIR/bags"
    done
}

bag_proxy() {
    local prx_opt="$1"
    local prx_cmd="$2"
    local prx_help="$(cat <<EOF
bag proxy <action> [args..]

actions:
    add <cmd>       add a proxy cmd, need to be quoted
    del <cmd-pat>   delete a proxy cmd, need to be quoted
    run [cmd-pat]   run all or a pattern matched proxy cmd
    edit            edit the proxy file
    list            list all added proxy cmd
    help            print the bag proxy help message like this
EOF
)"

    [[ -f $BAG_BASE_DIR/proxy ]] || { mkdir -p "$BAG_BASE_DIR" && touch "$BAG_BASE_DIR/proxy"; }

    case $prx_opt in
        add)
            [[ -n $prx_cmd ]] || __bag_error "Need a specific cmd, usage: bag proxy add <cmd>" || return 1
            echo "$prx_cmd" >>"$BAG_BASE_DIR/proxy" \
            && __bag_printc green "Added proxy: ${prx_cmd@Q}" \
            || __bag_error "Failed to add proxy: ${prx_cmd@Q}" ;;
        del)
            local IFS=,
            [[ -n $prx_cmd ]] || __bag_error "Need a cmd pattern, usage: bag proxy del <cmd-pat>" || return 1
            mapfile -t found <<<"$(sed -rn  "/${prx_cmd//\//\\\/}/p" "$BAG_BASE_DIR/proxy")"
            sed -ri "/${prx_cmd//\//\\\/}/d" "$BAG_BASE_DIR/proxy" \
            && __bag_printc green "Deleted proxy: ${found[*]@Q}" \
            || __bag_error "Failed to del proxy: ${found[*]@Q}"
            unset found ;;
        run)
            mapfile -t cmds <"$BAG_BASE_DIR/proxy"
            [[ -n $prx_cmd ]] && mapfile -t cmds < <(grep -iE "$prx_cmd" "$BAG_BASE_DIR/proxy")
            for cmd in "${cmds[@]}"; do
                __bag_printc yellow "Running ${cmd@Q}..."
                (eval "eval ${cmd@Q}")
            done
            unset cmds ;;
        edit)  "${EDITOR:-vim}" "$BAG_BASE_DIR/proxy" ;;
        list) cat "$BAG_BASE_DIR/proxy" ;;
        help) echo "$prx_help" ;;
        *) __bag_error "No such option: ${prx_opt@Q}" ;;
    esac
}

__bag_helper() {
    local -n help_array="$1"
    local -a sorted=($(echo "${!help_array[@]}" | sed -r 's/\s+/\n/g' | sort))
    for type in "${sorted[@]}"; do
        printf '    %-10s %s\n' "$type" "${help_array[$type]}"
    done
}
__bag_init_subcmd() {
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
    BAG_SUBCMDS_HELP[edit]="edit bags list"
    BAG_SUBCMDS_HELP[proxy]="proxy an package or repo operation cmd"

    declare -gA BAG_SUBCMDS
    for cmd in "${!BAG_SUBCMDS_HELP[@]}"; do
        BAG_SUBCMDS[$cmd]="bag_$cmd"
    done
}

bag_init() {
    declare -g  BAG_AUTHOR=ishbguy
    declare -g  BAG_PRONAME="$(basename "${BAG_ABS_SRC}" .sh)"
    declare -g  BAG_VERSION='v1.0.0'
    declare -g  BAG_URL='https://github.com/ishbguy/bag'
    declare -g  BAG_BASE_DIR="${BAG_BASE_DIR:-$HOME/.$BAG_PRONAME}"
    declare -g  BAG_CONFIG="${BAG_CONFIG:-$HOME/.${BAG_PRONAME}rc}"
    declare -ga BAG_PLUGINS=()

    __bag_init_color
    __bag_init_subcmd
    __bag_init_downloader
}
bag() {
    local cmd="$1"; shift
    __bag_has_cmd "$cmd" \
        || { __bag_error "No such command: '$cmd'"; "${BAG_SUBCMDS[help]}"; return 1; }
    "${BAG_SUBCMDS[$cmd]}" "$@"
}

bag_init

[[ -z ${FUNCNAME[0]} || ${FUNCNAME[0]} == "main" ]] && bag "$@"

# vim:set ft=sh ts=4 sw=4:
