#### AutoVenv

Plugin to automatically activate/deactivate Python virtual enviroments upon entering/leaving a directory.

Forked to provide compatibility with [fisher](https://github.com/jorgebucaran/fisher) plugin manager.

[![MIT License][license-badge]](/LICENSE)
</br>

## Install
Installation with [fisher](https://github.com/jorgebucaran/fisher):

    fisher install strayge/fish-autovenv2

## About
Do you like the way Pyenv automatically switches between enviroments when you change directories and wish
you could do the same thing with standard Python 3 venvs? Well, now you can! No complicated scripts,
binaries or overhead needed; AutoVenv is a single file, pure `fish` solution.

## Usage
Upon entering a directory that contains a Python venv (or any directory *above* it) AutoVenv will automatically
activate it for you. Likewise, when moving *below* the venv's parent directory AutoVenv will deactivate it!
AutoVenv can also handle cases where you move directly from one venv directory to another.

## Settings
    set -U autovenv_enable yes|no
Enables/disables autovenv functionality.

    set -U autovenv_announce yes|no
Controls whether or not a message is printed when entering/leaving/changing venvs.

## License
[MIT][mit] © [Timothy Brown][author]

[author]: https://github.com/timothybrown
[license-badge]: https://img.shields.io/badge/license-MIT-007EC7.svg?style=flat-square
[mit]: http://opensource.org/licenses/MIT
