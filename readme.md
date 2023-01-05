<!-- VARS -->
[git-url]: https://git-scm.com/
[curl-url]: https://curl.se/
[aptitude-url]: https://wiki.debian.org/Aptitude
[debian-url]: https://www.debian.org/
<!-- END_VARS -->

<div align="center" >
   <img src="./.github/assets/logo_wo_blur.svg" width=300>

   _just let the magic happens_
   
   [![.github/workflows/test.yaml](https://github.com/pmqueiroz/dotfiles/actions/workflows/test.yaml/badge.svg?branch=master)](https://github.com/pmqueiroz/dotfiles/actions/workflows/test.yaml)
   
</div>

### Requirements

Before running this script make sure you have the following installed:
   * [Git][git-url]
   * [Curl][curl-url]
   * A Distro based on [Debian][debian-url] with [Aptitude][aptitude-url] Package Manager

```sh
$ apt install curl git
```

### Run

```sh
$ sudo apt update
$ sudo apt upgrade
# now run the commands above that I know you skipped
$ bash install.sh
```
> **Warning** This script must be used in a sudoer user, otherwise it will not work at all.

### Options

| option  |          description             |
|---------|----------------------------------|
| --quiet | skip all logs except error level |
| --skip-fonts | skip fonts install |
| --skip-icons | skip icons install |
| --skip-dependencies | skip dependencies install |
| --skip-settings | skip settings install |
| --skip-sources | skip sources adds to bash config |

### Authenticate

There is an another script to authenticate the machine with github, generating SSH keys and etc.

#### Run

```sh
# inside the dotfiles clone
$ bash authenticate.sh

# or even without clone anything
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/pmqueiroz/dotfiles/master/authenticate.sh)"
```

To skip interactions you can simply run:

```sh
$ bash authenticate.sh << EOF
YOUR_EMAIL
YOUR_USERNAME
YOUR_PERSONAL_ACCESS_TOKEN
EOF
```

#### Options

| option  |          description             |
|---------|----------------------------------|
| --skip-ssh | skip setting ssh key to github |
| --skip-npm-token | skip setting personal access token to npm user |
| --skip-git-configuring | skip configuring git |

### Tested on

##### Distros that I have used this script to setup

| distro | version | manually | ci |
| -------|---------|----------|----|
| Kali Linux | 2022.4 | :heavy_check_mark: | :heavy_check_mark: |
| Ubuntu | 22.04 | :heavy_check_mark: | :heavy_check_mark: |
| Ubuntu | 20.04 | :x: | :heavy_check_mark: |
