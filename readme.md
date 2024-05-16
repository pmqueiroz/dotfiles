<!-- VARS -->
[peam-url]: https://pmqueiroz.dev/
[git-url]: https://git-scm.com/
[curl-url]: https://curl.se/
[brew-url]: https://brew.sh/
[unix-url]: https://en.wikipedia.org/wiki/Unix
[code-url]: https://code.visualstudio.com/
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
   * [Visual Studio Code][code-url] _('code' need to bee installed in PATH)_

> **Warning** if you are in `macOS` make sure to update bash version

### Run

```sh
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pmqueiroz/dotfiles/release/install.sh)"
```
> **Warning** This script must be used in a sudoer user, otherwise it will not work at all.

...

### Options

| option  |          description             |
|---------|----------------------------------|
| <kbd>--verbose</kbd> | log all suppressed `stdout`\|`stderr` from commands |
| <kbd>--skip-dependencies</kbd> | skip dependencies install |
| <kbd>--skip-sources</kbd> | skip sources adds to bash config |
| <kbd>--skip-dots</kbd> | skip settings install |
| <kbd>--skip-ssh</kbd> | skip setting ssh key to github |
| <kbd>--skip-npm-token</kbd> | skip setting personal access token to npm user |
| <kbd>--skip-git-configuring</kbd> | skip configuring git |

<div align="center">

<samp>Made with :heart: by [**Peam**][peam-url]</samp> 

</div>
