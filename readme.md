<!-- VARS -->
[git-url]: https://git-scm.com/
[curl-url]: https://curl.se/
<!-- END_VARS -->

<div align="center" >
   <img src="./.github/assets/logo_wo_blur.svg" width=300>

   _just let the magic happens_
</div>

### Requirements

Before running this script make sure you have the following installed:
   * [Git][git-url]
   * [Curl][curl-url]

### Run

```sh
   $ bash install
```
> **Warning** this script is set up to runs on Debian based distros (that uses apt as package manager) and uses Gnome Shell, running on another linux distribution or with another interface might cause errors

| option  |          description             |
|---------|----------------------------------|
| --quiet | skip all logs except error level |
| --skip-settings | skip settings install |
| --skip-dependencies | skip dependencies install |
| --skip-fonts | skip fonts install |
