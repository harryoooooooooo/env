# My kakrc

## Setup

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

## Usage

Most of my self-defined commands are bound to keys in user mode,
press `,` key in normal mode to see the available commands.

A special `osc52` script is used in `:clip` command.
Sample script can be found [here](https://chromium.googlesource.com/apps/libapps/+/main/hterm/etc/osc52.sh).

A special option is `term_run_template`. Currently it's used by `:find` and `:sudo-write`.
I only set up the option for wayland, x11, and tmux windowing modules.
Please reference the docstring and set it up if you're using other windowing modules.
