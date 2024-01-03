<!-- VARS -->
[peam-url]: https://pmqueiroz.dev/
[git-url]: https://git-scm.com/
[curl-url]: https://curl.se/
[brew-url]: https://brew.sh/
[unix-url]: https://en.wikipedia.org/wiki/Unix
<!-- END_VARS -->

<div align="center" >
   <img src="./.github/assets/logo_wo_blur.svg" width=300>

   _just let the magic happens_
</div>

### Requirements

Before running this script make sure you have the following installed:
   * [Git][git-url]
   * [Curl][curl-url]
   * [Homebrew][brew-url]
   * A [Unix][unix-url] system based (linux/mac).

### Run

```sh
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pmqueiroz/dotfiles/release/install.sh)"
```
> **Warning** This script must be used in a sudoer user, otherwise it will not work at all.

### Options

| option  |          description             |
|---------|----------------------------------|
| --skip-dependencies | skip dependencies install |
| --skip-sources | skip sources adds to bash config |
| --skip-dots | skip settings install |
| --skip-ssh | skip setting ssh key to github |
| --skip-npm-token | skip setting personal access token to npm user |
| --skip-git-configuring | skip configuring git |

<div align="center">

<samp>Made with :heart: by [**Peam**][peam-url]</samp> 

</div>
