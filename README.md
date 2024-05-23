# My work environment

## `kakrc`

### Setup

First reference [robertmeta/plug.kak](https://github.com/robertmeta/plug.kak) to install the plugin manager.
For my kakrc to work it should be installed with:
``` sh
git clone https://github.com/robertmeta/plug.kak.git ~/.config/kak/plugins/plug.kak
```

Place the kakrc file under `%val{config}`. By default it should be `$HOME/.config/kak/`.
Then launch Kakoune and run `:plug-install` to install the plugins.
[Cargo](https://doc.rust-lang.org/cargo/) is necessary for installing kak-lsp.

Quit Kakoune and launch again after the installation is done.
Check debug log with `:b *debug*` to see if there is any missing command.

### Usage

Most of my self-defined commands are bound to keys in user mode,
press `,` key in normal mode to see the available commands.

A special `osc52` script is used in `:clip` command.
Sample script can be found [here](https://chromium.googlesource.com/apps/libapps/+/main/hterm/etc/osc52.sh).

A special option is `term_run_template`. Currently it's used by `:find` and `:sudo-write`.
I only set up the option for wayland, x11, and tmux windowing modules.
Please reference the docstring and set it up if you're using other windowing modules.

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
