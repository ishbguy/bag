#! /usr/bin/env bash
# Copyright (c) 2018-Present Herbert Shen <ishbguy@hotmail.com> All Rights Reserved.
# Released under the terms of the MIT License.

# source guard
[[ $BAG_SOURCED -eq 1 ]] && return
declare -gr BAG_SOURCED=1
declare -gr BAG_ABS_SRC="$(readlink -f "${BASH_SOURCE[0]}")"
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
        color="$1"
        shift
        __bag_has_map BAG_ANSI_COLOR "$1" && {
            format="$1"
            shift
        }
    fi
    __bag_set_color "$color" "$format"
    echo -e "$@"
    __bag_set_color reset
}

__bag_ok() { __bag_printc green "$@"; }
__bag_info() { __bag_printc yellow "$@";  }
__bag_warn() { __bag_printc magenta "$@" >&2 && return 1; }
__bag_error() { __bag_printc red "$@" >&2 && return 1; }
__bag_is_local_repo() { [[ -d $1 ]]; }
__bag_is_remote_repo() { [[ $1 =~ ^[[:alnum:]_-][[:alnum:]._-]*:[[:alnum:]./_-]+$ ]]; }
__bag_is_repo() { __bag_is_local_repo "$1" || __bag_is_remote_repo "$1"; }
__bag_defined() { declare -p "$1" &> /dev/null; }
__bag_defined_func() { declare -f "$1" &> /dev/null; }
__bag_encode_name() { echo "${1//[^[:alnum:]]/_}"; }
__bag_trim_space() {
    local str="$1"
    str="${str%%+( )}"
    str="${str##+( )}"
    echo "$str"
}
__bag_has_map() { local -n map="$1" && shift && [[ -n $1 && -n ${map[$1]} ]]; }
__bag_has_mapfunc() {
    local -n map="$1"
    __bag_has_map "$@" && __bag_defined_func "${map[$2]}"
}
__bag_require() {
    local -a missed=()
    for req in "$@"; do
        hash "$req" &> /dev/null || missed+=("$req")
    done
    local IFS=,
    [[ ${#missed[@]} -eq 0 ]] || __bag_error "bag needs: ${missed[*]}."
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
    cat << EOF
$BAG_PRONAME $BAG_VERSION
$BAG_PRONAME <subcmd> [somthing]

subcmds:
$(__bag_helper BAG_SUBCMDS_HELP)

<dl:url> like 'gh:ishbguy/bag' means that it will install or update bag
from $BAG_URL by github downloader.

downloaders:
$(__bag_helper BAG_DOWNLOADER_HELP)

$(bag list help)

$(bag agent help)

This program is released under the terms of MIT License.
Get more infomation from <$BAG_URL>.
EOF
}
bag_base() {
    if [[ $# -eq 0 ]]; then
        echo "$BAG_BASE_DIR"
    elif [[ $# -eq 1 && -n $1 && -d $1 ]]; then
        BAG_BASE_DIR="$1"
    else
        __bag_error "Usage: bag base [dir]"
    fi
}
bag_plug() {
    if [[ $# -eq 0 ]]; then
        local IFS=$'\n'
        echo "${BAG_PLUGINS[*]}"
    elif [[ $# -eq 1 && -n $1 ]] && __bag_is_remote_repo "$1"; then
        BAG_PLUGINS[$1]="$1"
    else
        __bag_error "Usage: bag plug [dl:url]"
    fi
}
bag_list() {
    local list_help="$(
        cat << EOF
bag list usage:

bag list [options]

options:
                               list without option will list all bags <dl-url>
    -a|--all|all               list all bags include autoload notation(@)
                               and post install cmd(#!)
    -@|@|--autoload|autoload   list autoload bags without '@' or '#!' string
    -p|--post|post             list bags configured post install cmd but
                               without '#!' cmd string
    -h|--help|help             print this help message
EOF
    )"
    local opt=$1

    [[ $opt =~ (-h|--help|help) ]] && echo "$list_help" && return 0

    [[ -f $BAG_BASE_DIR/bags ]] || return 1

    if [[ $# -eq 0 ]]; then
        sed -r 's/^@//g;s/#!.*$//g' "$BAG_BASE_DIR/bags"
    else
        case $opt in
            -a|--all|all) cat "$BAG_BASE_DIR/bags" ;;
            -@|@|--autoload|autoload)
                sed -rn '/^@/p'  "$BAG_BASE_DIR/bags" | sed -r 's/^@//g;s/#!.*$//g'
                ;;
            -p|--post|post)
                sed -rn '/#!.*$/p' "$BAG_BASE_DIR/bags" | sed -r 's/^@//g;s/#!.*$//g'
                ;;
            -h|--help|help) echo "$list_help" ;;
            *) __bag_error "$list_help" ;;
        esac
    fi
}
bag_edit() { [[ -f $BAG_BASE_DIR/bags ]] && "${EDITOR:-vim}" "$BAG_BASE_DIR/bags"; }

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
    __bag_require git || return 1

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
    __bag_require git || return 1

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

__bag_post_install_hook() {
    local -n cmds=$1
    local bag
    for bag in "${!cmds[@]}" ; do
        local cmd="${cmds[$bag]}"
        [[ -n $cmd ]] || continue
        local bag_path="$BAG_BASE_DIR/$(__bag_get_bag_name "$bag")"
        (cd "$bag_path"; eval "$cmd")
    done
}
bag_install() {
    local -a bags=("$@")
    local -A post_cmds
    local bag_line

    [[ ${#bags[@]} -eq 0 ]] && bags=("${BAG_PLUGINS[@]}")
    [[ -d $BAG_BASE_DIR ]] || mkdir -p "$BAG_BASE_DIR"

    for bag_line in "${bags[@]}"; do
        local bag_url dloader bag cmd

        bag_url="$bag_line"
        bag_url="${bag_url/#@/}"   # remove beginning '@'
        bag_url="${bag_url/%#!*/}" # remove tailing '#!' cmd string
        bag_url="${bag_url%%+(/)}" # remove tailing '/'
        
        dloader="${bag_url%%:*}"
        bag="$(__bag_get_bag_name "${bag_url##*:}")"

        [[ $bag_line =~ '#!' ]] && cmd="${bag_line##*\#!}" || cmd=""

        __bag_has_downloader "$dloader" \
            || __bag_error "Does not support ${dloader@Q} to download." || continue
        ! __bag_has_bag "$bag" || __bag_error "Already exist bag: $bag" || continue

        __bag_info "Installing $bag_url..."
        if "${BAG_DOWNLOADER[$dloader]}" install "$bag_url"; then
            echo "$bag_line" >> "$BAG_BASE_DIR/bags" && post_cmds[$bag_url]="$cmd"
        else
            __bag_error "Failed to install $bag_url"
        fi
    done

    # running post-install hooks
    __bag_post_install_hook post_cmds
}

bag_update() {
    local -a bag_pats=("$@") bags=()
    local -A post_cmds
    local bag_line

    [[ ${#bag_pats[@]} -eq 0 ]] && bag_pats=($(bag list))

    for bag_pat in "${bag_pats[@]}"; do
        mapfile -t bags < <(grep -iE "$bag_pat" "$BAG_BASE_DIR/bags")
        [[ ${#bags[@]} -ne 0 ]] || __bag_error "No such bag: ${bag_pat@Q}" || continue
        for bag_line in "${bags[@]}"; do
            local bag_url dloader bag cmd

            bag_url="$bag_line"
            bag_url="${bag_url/#@/}"   # remove beginning '@'
            bag_url="${bag_url/%#!*/}" # remove tailing '#!' cmd string
            bag_url="${bag_url%%+(/)}" # remove tailing '/'
            
            dloader="${bag_url%%:*}"
            bag="$(__bag_get_bag_name "${bag_url##*:}")"

            [[ $bag_line =~ '#!' ]] && cmd="${bag_line##*\#!}" || cmd=""

            __bag_has_downloader "$dloader" \
                || __bag_error "Does not support ${dloader@Q} to download." || continue
            __bag_has_bag "$bag" || __bag_error "No such bag: $bag_url" || continue

            __bag_info "Updating $bag_url..."
            if "${BAG_DOWNLOADER[$dloader]}" update "$bag_url"; then
                post_cmds[$bag_url]="$cmd"
            else
                __bag_error "Failed to update $bag_url"
            fi
        done
    done

    # running post-update hooks, same as post-install hooks
    __bag_post_install_hook post_cmds
}

bag_uninstall() {
    [[ $# -ne 0 ]] || __bag_error "Usage: bag uninstall <dl-url>"
    for bag_url in "$@"; do
        local bag="$(__bag_get_bag_name "$bag_url")"
        __bag_has_bag "$bag" || __bag_error "No such bag: $bag" || continue
        __bag_info "Uninstall $bag..."
        rm -rf "$BAG_BASE_DIR/$bag" && sed -ri '/'"\\/$bag"'/d' "$BAG_BASE_DIR/bags"
    done
}

bag_agent() {
    local agt_opt="$1"
    local agt_cmd="$2"
    local agt_help="$(
        cat << EOF
bag agent usage:

bag agent <action> [args..]

actions:
    add <cmd>       add an agent cmd, need to be quoted
    del <cmd-pat>   delete an agent cmd, need to be quoted
    run [cmd-pat]   run all or a pattern matched agent cmd
    edit            edit the agent file
    list            list all added agent cmd
    help            print the bag agent help message like this
EOF
    )"

    [[ -f $BAG_BASE_DIR/agent ]] || { mkdir -p "$BAG_BASE_DIR" && touch "$BAG_BASE_DIR/agent"; }

    case $agt_opt in
        add)
            [[ -n $agt_cmd ]] || __bag_error "Need a specific cmd, usage: bag agent add <cmd>" || return 1
            echo "$agt_cmd" >> "$BAG_BASE_DIR/agent" \
                && __bag_ok "Added agent: ${agt_cmd@Q}" \
                || __bag_error "Failed to add agent: ${agt_cmd@Q}"
            ;;
        del)
            local IFS=,
            [[ -n $agt_cmd ]] || __bag_error "Need a cmd pattern, usage: bag agent del <cmd-pat>" || return 1
            mapfile -t found < <(sed -rn "/${agt_cmd//\//\\\/}/p" "$BAG_BASE_DIR/agent")
            [[ ${#found[@]} -ne 0 ]] || __bag_error "No such agent: ${agt_cmd@Q}" || return 1
            echo "${#found[@]} ${found[*]}"
            sed -ri "/${agt_cmd//\//\\\/}/d" "$BAG_BASE_DIR/agent" \
                && __bag_ok "Deleted agent: ${found[*]@Q}" \
                || __bag_error "Failed to del agent: ${found[*]@Q}"
            unset found
            ;;
        run)
            mapfile -t cmds < "$BAG_BASE_DIR/agent"
            [[ -n $agt_cmd ]] && mapfile -t cmds < <(grep -iE "$agt_cmd" "$BAG_BASE_DIR/agent")
            [[ ${#cmds[@]} -ne 0 ]] || __bag_error "No such agent: ${agt_cmd@Q}" || return 1
            for cmd in "${cmds[@]}"; do
                __bag_info "Running ${cmd@Q}..."
                (eval "eval ${cmd@Q}")
            done
            unset cmds
            ;;
        edit) "${EDITOR:-vim}" "$BAG_BASE_DIR/agent" ;;
        list) cat "$BAG_BASE_DIR/agent" ;;
        help) echo "$agt_help" ;;
        *) bag_agent run "$agt_opt" ;;
    esac
}
bag_link() {
    local path=$1 url=$2 bag_name
    path="$(readlink -f "$path" 2> /dev/null)"
    if __bag_is_local_repo "$path" && __bag_is_remote_repo "$url"; then
        bag_name="$(__bag_get_bag_name "$url")"
        ln -s "$path" "$BAG_BASE_DIR/$bag_name" && echo "$url" >> "$BAG_BASE_DIR/bags" \
            && __bag_ok "Added link to bag list: ${path@Q}"
    else
        __bag_error "No such path or invalid url: ${path@Q}, ${url@Q}"
    fi
}
bag_unlink() {
    bag_uninstall "$@"
}

__bag_helper() {
    local -n help_array="$1"
    local -a sorted=($(echo "${!help_array[@]}" | sed -r 's/\s+/\n/g' | sort))
    for type in "${sorted[@]}"; do
        local arg="" msg="${help_array[$type]}"
        if [[ ${help_array[$type]} =~ @ ]]; then
            arg="${help_array[$type]%%@*}"
            msg="${help_array[$type]##*@}"
        fi
        printf '    %-10s %-15s %s\n' "$type" "$arg" "$msg"
    done
}
__bag_init_subcmd() {
    declare -gA BAG_SUBCMDS_HELP
    BAG_SUBCMDS_HELP[help]="show help message, like this output"
    BAG_SUBCMDS_HELP[version]="show version number"
    BAG_SUBCMDS_HELP[base]="[path]@change or list bags download directory"
    BAG_SUBCMDS_HELP[plug]="[dl:url]@add a bag plugin or list all plugins"
    BAG_SUBCMDS_HELP[load]="load all plugins and update PATH"
    BAG_SUBCMDS_HELP[install]="[dl:url]@install a bag"
    BAG_SUBCMDS_HELP[uninstall]="<dl:url>@uninstall a bag"
    BAG_SUBCMDS_HELP[update]="[pat]@update one or more bags"
    BAG_SUBCMDS_HELP[list]="list installed bags"
    BAG_SUBCMDS_HELP[edit]="edit bag list"
    BAG_SUBCMDS_HELP[agent]="agent for other package or repo operation cmd"
    BAG_SUBCMDS_HELP[link]="<path> <dl:url>@add an existed package or repo by symbolic link"
    BAG_SUBCMDS_HELP[unlink]="<dl:url>@unlink a bag, just like uninstall"

    declare -gA BAG_SUBCMDS
    for cmd in "${!BAG_SUBCMDS_HELP[@]}"; do
        BAG_SUBCMDS[$cmd]="bag_$cmd"
    done
}

bag_init() {
    declare -g BAG_AUTHOR=ishbguy
    declare -g BAG_PRONAME="$(basename "${BAG_ABS_SRC}" .sh)"
    declare -g BAG_VERSION='v1.0.0'
    declare -g BAG_URL="https://github.com/$BAG_AUTHOR/$BAG_PRONAME"
    declare -g BAG_BASE_DIR="${BAG_BASE_DIR:-$HOME/.$BAG_PRONAME}"
    declare -g BAG_CONFIG="${BAG_CONFIG:-$HOME/.${BAG_PRONAME}rc}"
    declare -gA BAG_PLUGINS

    __bag_init_color
    __bag_init_subcmd
    __bag_init_downloader
}
bag() {
    local cmd="$1" && shift
    if ! __bag_has_cmd "$cmd"; then
        __bag_error "No such command: '$cmd'"
        "${BAG_SUBCMDS[help]}"
        return 1
    fi
    "${BAG_SUBCMDS[$cmd]}" "$@"
}

bag_init

[[ -n ${FUNCNAME[0]} && ${FUNCNAME[0]} != "main" ]] || bag "$@"

# vim:set ft=sh ts=4 sw=4:
