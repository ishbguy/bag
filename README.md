# [bag](https://github.com/ishbguy/bag)

[![Version][versvg]][ver] [![License][licsvg]][lic]

[versvg]: https://img.shields.io/badge/version-v1.0.0-lightgrey.svg
[ver]: https://img.shields.io/badge/version-v1.0.0-lightgrey.svg
[licsvg]: https://img.shields.io/badge/license-MIT-green.svg
[lic]: https://github.com/ishbguy/bag/blob/master/LICENSE

**bag** is a bash package and plugin manager which inspired by [vim-plug](https://github.com/junegunn/vim-plug).

## Table of Contents

+ [:art: Features](#art-features)
+ [:straight_ruler: Prerequisite](#straight_ruler-prerequisite)
+ [:rocket: Installation](#rocket-installation)
+ [:notebook: Usage](#notebook-usage)
+ [:memo: Configuration](#memo-configuration)
+ [:hibiscus: Contributing](#hibiscus-contributing)
+ [:boy: Authors](#boy-authors)
+ [:scroll: License](#scroll-license)

## :art: Features

+ Basic packges and plugins management: install, update or uninstall.
+ Customizable to support different downloader: local repos, git repos or cloud drive repos.

## :straight_ruler: Prerequisite

> + `bash` 4.2 or later
> + `git`

## :rocket: Installation

``` bash
$ git clone https://github.com/ishbguy/bag /path/to/bag
```
or
```bash
$ curl -fLo /path/to/bag.sh --create-dirs \
         https://raw.githubusercontent.com/ishbguy/bag/master/bag.sh
```

## :notebook: Usage

The only action you need to do is to add below instruction in your bash config file: `~/.bashrc` or `~/.bash_profile`:

```bash
[[ -f /path/to/bag.sh ]] && source /path/to/bag.sh
```

After login `bash`, you can use `bag` command to manage packges and plugins. `bag help` will print usage.

```
bag v1.0.0
bag <subcmd> [somthing]

subcmds:
    base       <path>          change bags' download directory
    edit                       edit bag list
    help                       show help message, like this output
    install    [dl:url]        install a bag
    link       <path> <dl:url> add an existed package or repo by symbolic link
    list                       list installed bags
    load                       load all plugins and update PATH
    plug       <dl:url>        add a bag plugin
    proxy                      proxy an package or repo operation cmd
    uninstall  <dl:url>        uninstall a bag
    update     [pat]           update one or more bags
    version                    show version number

<dl:url> like 'gh:ishbguy/bag' means that it will install or update bag
from https://github.com/ishbguy/bag by github downloader.

downloaders:
    file                       alias for local downloader
    gh                         alias for github downloader
    git                        downloader for git repo
    github                     downloader for github repo
    link                       downloader for local file or directory as symbolic link
    local                      downloader for local file or directory

bag proxy usage:

bag proxy <action> [args..]

actions:
    add <cmd>       add a proxy cmd, need to be quoted
    del <cmd-pat>   delete a proxy cmd, need to be quoted
    run [cmd-pat]   run all or a pattern matched proxy cmd
    edit            edit the proxy file
    list            list all added proxy cmd
    help            print the bag proxy help message like this

This program is released under the terms of MIT License.
Get more infomation from <https://github.com/ishbguy/bag>.
```

### Examples

1. Using bag like other package management tools:

```bash
bag install gh:ishbguy/bag
bag update gh:ihsbguy/bag
bag uninstall gh:ishbguy/bag
```

2. Using bag as a plugin management tool, you need to add instructions to `~/.bashrc` or `~/.bash_profile`:

```bash
bag base $HOME/.bags
bag plug gh:ishbguy/bag
bag install
bag load
```

## :memo: Configuration

The default `BAG_BASE_DIR` is `$HOME/.bags`, you can change it by `bag base <dir-path>` or `export BAG_BASE_DIR=$DIR_PATH`.

## :hibiscus: Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## :boy: Authors

+ [ishbguy](https://github.com/ishbguy)

## :scroll: License

Released under the terms of [MIT License](https://opensource.org/licenses/MIT).
