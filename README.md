# [bag](https://github.com/ishbguy/bag)

[![Version][versvg]][ver] [![License][licsvg]][lic]

[versvg]: https://img.shields.io/badge/version-v0.0.1-lightgrey.svg
[ver]: https://img.shields.io/badge/version-v0.0.1-lightgrey.svg
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
> + `realpath`

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

After login `bash`, you can use `bag` command to manage packges and plugins.

## :memo: Configuration

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
