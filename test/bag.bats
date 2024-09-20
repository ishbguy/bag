#!/usr/bin/env bats

load bats-helper
load bag-helper

@test "bag no-such-cmd" {
    run bag
    assert_match "No such command"
    run bag no-such-cmd
    assert_match "No such command"
}

@test "bag version" {
    run bag version
    assert_match "$BAG_VERSION"
}

@test "bag help" {
    run bag help
    assert_match "https://github.com/ishbguy/bag"
}

@test "bag base" {
    local BAG_BASE_DIR="$HOME/.bag"
    run bag base
    assert_match "$HOME/.bag"

    (bag base "$PROJECT_TMP_DIR" && [[ $(bag base) == $PROJECT_TMP_DIR ]])

    run bag base one two
    assert_match "Usage: bag base \[dir\]"
}

@test "bag plug" {
    local -A BAG_PLUGINS=()

    run bag plug
    assert_output ""

    run bag plug not-dl-url
    assert_match "Usage: bag plug \[dl:url\]"

    bag plug gh:ishbguy/bag
    run bag plug
    assert_output "gh:ishbguy/bag"

    bag plug gh:ishbguy/bag # add the same bag for twice
    run bag plug
    assert_output "gh:ishbguy/bag"
}

@test "bag list" {
    local BAG_BASE_DIR
    bag base "$PROJECT_TMP_DIR"

    run bag list
    assert_output ""
    echo "gh:ishbguy/bag" > "$PROJECT_TMP_DIR/bags"
    run bag list
    assert_output "gh:ishbguy/bag"
}

@test "bag edit" {
    echo "gh:ishbguy/bag" > "$PROJECT_TMP_DIR/bags"
    local BAG_BASE_DIR
    bag base "$PROJECT_TMP_DIR"
    local EDITOR=cat
    run bag edit
    assert_output "gh:ishbguy/bag"
}

@test "bag install" {
    local -A BAG_PLUGINS
    local BAG_BASE_DIR
    bag base "$PROJECT_TMP_DIR"
    mkdir -p "$PROJECT_TMP_DIR"/XXXXXX/{A,B,C}/{autoload,bin}

    run bag install
    assert_success
    assert_output ""
    
    run bag install no-such-file-or-dir
    assert_match "Does not support"

    run bag install "local:$PROJECT_TMP_DIR/XXXXXX/A"
    assert_success
    run bag install "file:$PROJECT_TMP_DIR/XXXXXX/B"
    assert_success
    run bag install "link:$PROJECT_TMP_DIR/XXXXXX/C"
    assert_success
    run bag install gh:ishbguy/bag
    assert_success

    run bag install github:ishbguy/bag
    assert_match "Already exist bag"
}

@test "bag link" {
    local BAG_BASE_DIR
    local repo="$PROJECT_TMP_DIR"/XXXXXX/A
    bag base "$PROJECT_TMP_DIR"

    mkdir -p "$repo"/{autoload,bin}
    run bag link
    assert_match "No such path or invalid url"
    run bag link no-such-file-dir
    assert_match "No such path or invalid url"
    run bag link "$repo" invalid-url
    assert_match "No such path or invalid url"

    run bag link "$repo" "local:$repo"
    assert_match "Added link to bag list"
}

@test "bag update" {
    local -A BAG_PLUGINS
    local BAG_BASE_DIR repo
    bag base "$PROJECT_TMP_DIR"
    for repo in "$PROJECT_TMP_DIR"/XXXXXX/{A,B,C}; do
        mkdir -p "$repo"/{autoload,bin}
        BAG_PLUGINS[$repo]="local:$repo"
    done
    run bag install github:ishbguy/bag
    run bag install

    run bag update
    assert_success
    run bag update '[ABC]'
    assert_success
    run bag update no-such-bag
    assert_match "No such bag"
    rm -rf "$PROJECT_TMP_DIR/C"
    run bag update C
    assert_match "No such bag"
}

@test "bag uninstall & unlink" {
    local -A BAG_PLUGINS
    local BAG_BASE_DIR repo
    bag base "$PROJECT_TMP_DIR"
    for repo in "$PROJECT_TMP_DIR"/XXXXXX/{A,B,C}; do
        mkdir -p "$repo"/{autoload,bin}
        BAG_PLUGINS[$repo]="local:$repo"
    done
    run bag install
    run bag uninstall
    assert_match "Usage: bag uninstall <dl-url>"
    run bag uninstall A
    assert_match "Uninstall"
    run bag uninstall B C
    assert_match "Uninstall"
}

@test "bag load" {
    local -A BAG_PLUGINS
    local BAG_BASE_DIR
    local repo="$PROJECT_TMP_DIR"/XXXXXX/A
    bag base "$PROJECT_TMP_DIR"

    mkdir -p "$repo"/{autoload,bin}
    echo "echo 'echo Hello from $repo' > $repo/bin/hello.sh" > "$repo/autoload/gen-hello.sh"
    (bag plug "local:$repo" && bag install && bag load && [[ $PATH =~ $PROJECT_TMP_DIR/A/bin ]])
    run cat "$repo/bin/hello.sh"
    assert_match "Hello"
}

@test "bag agent" {
    local BAG_BASE_DIR
    local repo="$PROJECT_TMP_DIR"/XXXXXX/A
    bag base "$PROJECT_TMP_DIR"

    mkdir -p "$repo"/{autoload,bin}

    run bag agent help
    assert_match "bag agent <action>"

    run bag agent add
    assert_match "Need a specific cmd"
    run bag agent add 'echo Hello from bag agent'
    assert_match "Added agent"

    run bag agent list
    assert_match "Hello"

    local EDITOR=cat
    run bag agent edit
    assert_output "echo Hello from bag agent"

    run bag agent run
    assert_match "Hello"
    run bag agent run echo
    assert_match "Hello"
    run bag agent run '^e'
    assert_match "Hello"
    run bag agent echo
    assert_match "Hello"
    run bag agent run no-such-agent
    assert_match "No such agent"

    run bag agent del
    assert_match "Need a cmd pattern"
    run bag agent del echo
    assert_match "Deleted agent"
    run bag agent del no-such-agent
    assert_match "No such agent"
}

