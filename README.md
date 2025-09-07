# My work environment

## `kakrc`

### Setup

Place the kakrc file under `%val{config}`. By default it should be `$HOME/.config/kak/`.

Then launch Kakoune. The kakrc detects and installs the plugins manager
[andreyorst/plug.kak](https://github.com/andreyorst/plug.kak)
to `%val{config}/plugins/plug.kak` automatically if it's missing.

Run `:plug-install` to install the plugins.
[Cargo](https://doc.rust-lang.org/cargo/) is necessary for installing kak-lsp and kakpipe.

Quit Kakoune and launch again after the installation is done.
Check debug log with `:b *debug*` to see if there is any missing command.

### Usage

Most of my self-defined commands are bound to keys in user mode,
press space key in normal mode to see the available commands.

A special `osc52` script is used in `:clip` command.
Sample script can be found [here](https://chromium.googlesource.com/apps/libapps/+/main/hterm/etc/osc52.sh).

## `bashrc`

### Setup

* Configure bash completion, fzf completion, and git prompt path according to your distribution.
* I'm using shell prompt to automatically send the desktop notification when a long running command is done.
  Configure `NOTIFY_COMMAND_DONE_*` variables to disable/set blocklist/set threshold.
* Install [hterm-notify](https://chromium.googlesource.com/apps/libapps/+/main/hterm/etc/hterm-notify.sh).
  This is used as the default notifying tool.

## `gitconfig`

### Setup

Install [delta](https://github.com/dandavison/delta) to your environment.

## `tmux.conf`

### Usage

* `F7` selects previous window, `F8` selects next window, `F9` inserts a new window to the next index
* `Shift+ F7/F8/F9` for pane; Note that `Shift+F9` splits the pane smartly according to the pane width
* `Control+ F7/F8` to join/split the current pane to the left/right window.
  Imagine this as a normal `F7` `F8` but the current pane is carried.
