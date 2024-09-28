#!/usr/bin/env bash

setup() {
    # guard against executing this block twice due to bats internals
    if [ -z "$PROJECT_TMP_DIR" ]; then
        PROJECT_TMP_DIR="${BATS_TMPDIR}/project"
        # shellcheck disable=SC2155
        export PROJECT_TMP_DIR="$(mktemp -d "${PROJECT_TMP_DIR}.XXX" 2>/dev/null || echo "$PROJECT_TMP_DIR")"
        # shellcheck disable=SC2155
        export PROJECT_TMP_DIR="$(readlink -f "$PROJECT_TMP_DIR" 2>/dev/null || echo "$PROJECT_TMP_DIR")"
    fi
}
teardown() {
    rm -rf "$PROJECT_TMP_DIR"
}

abspath() {
    readlink -f "$1"
}
suitedir() {
    dirname "$(abspath "$BATS_TEST_FILENAME")"
}
suitename() {
    basename "$BATS_TEST_FILENAME" .bats | sed 's:^[0-9][0-9]-::'
}
puts() {
    printf "%s\n" "$@"
}
pass() {
    true
}
fail() {
    false
}
flunk() {
    {
        if [ "$#" -eq 0 ]; then
            cat -
        else
            echo "$@"
        fi
    } >&2
    return 1
}
assert() {
    if ! "$@"; then
        flunk "failed: $*"
    fi
}
assert_equal() {
    if [ "$1" != "$2" ]; then
        {
            echo "expected: $1"
            echo "actual:   $2"
        } | flunk
    fi
}
assert_regexp() {
    if [[ ! $2 =~ $1 ]]; then
        {
            echo "expected: $1"
            echo "actual:   $2"
        } | flunk
    fi
}
assert_output() {
    local expected
    if [ $# -eq 0 ]; then
        expected="$(cat -)"
    else
        expected="$1"
    fi
    assert_equal "$expected" "$output"
}
assert_match() {
    local expected
    if [ $# -eq 0 ]; then
        expected="$(cat -)"
    else
        expected="$1"
    fi
    assert_regexp "$expected" "$output"
}
assert_success() {
    if [ "$status" -ne 0 ]; then
        flunk "command failed with exit status $status"
    elif [ "$#" -gt 0 ]; then
        assert_output "$1"
    fi
}
assert_failure() {
    if [ "$status" -eq 0 ]; then
        flunk "expected failed exit status"
    elif [ "$#" -gt 0 ]; then
        assert_output "$1"
    fi
}
assert_line() {
    if [ "$1" -ge 0 ] 2>/dev/null; then
        assert_equal "$2" "${lines[$1]}"
    else
        local line
        for line in "${lines[@]}"; do
            if [ "$line" = "$1" ]; then return 0; fi
        done
        flunk "expected line '$1'"
    fi
}
refute_line() {
    if [ "$1" -ge 0 ] 2>/dev/null; then
        local num_lines="${#lines[@]}"
        if [ "$1" -ne "$num_lines" ]; then
            flunk "output has $num_lines lines"
        fi
    else
        local line
        for line in "${lines[@]}"; do
            if [ "$line" = "$1" ]; then
                flunk "expected to not find line '$line'"
            fi
        done
    fi
}
refute_match() {
    if [ "$1" -ge 0 ] 2>/dev/null; then
        local num_lines="${#lines[@]}"
        if [ "$1" -ne "$num_lines" ]; then
            flunk "output has $num_lines lines"
        fi
    else
        local line
        for line in "${lines[@]}"; do
            if [[ "$line" =~ "$1" ]]; then
                flunk "expected to not find line '$line'"
            fi
        done
    fi
}
