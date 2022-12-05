colorscheme palenight

# Set background to Default to keep the background image of the terminal.
set-face global Default default,default
set-face global BufferPadding rgb:4b5263,default

# Set eye-catching and related color to the cursor and the matching char.
set-face global PrimaryCursor rgb:c792ea,white+bfg
set-face global MatchingChar  white,rgb:c792ea+bfg
add-highlighter global/matching show-matching

# Show newline and tab.
set-face global Whitespace rgb:4b5263,default+fg
add-highlighter global/ws show-whitespaces -spc ' ' -nbsp ' ' -tab ▏

# Make tailing Whitespaces more visible.
add-highlighter global/t-ws regex '\h+$' 0:black,rgb:666666+F

## Disable mouse.
set-option global ui_options terminal_enable_mouse=false

# Show number lines relatively.
add-highlighter global/nu number-lines -hlcursor -relative

## Ag (the silver searcher) is mush faster then grep.
try %{
evaluate-commands %sh{
    if ! command -v ag >/dev/null 2>&1; then
        echo 'echo -debug Missing ag command, it is more recommended than grep'
        echo 'fail Missing ag command'
    fi
}
set-option global grepcmd 'ag --noheading --column --nobreak'
}
map global user g ':grep ' -docstring 'grep text under cwd'

## Add the same <c-a>/<c-x> functions as vim.
try %{
evaluate-commands %sh{
    if ! command -v bc >/dev/null 2>&1; then
        echo 'echo -debug Missing bc command, <c-a> and <c-x> will not be set'
        echo 'fail Missing bc command'
    fi
}
define-command -hidden -params 2 inc %{
    evaluate-commands %sh{
        if [ "$1" = 0 ]; then
            count=1
        else
            count="$1"
        fi
        printf '%s%s\n' 'execute-keys <a-i>na' "$2($count)<esc>|bc<ret>"
    }
}
map global normal <c-a> ':inc %val{count} +<ret>'
map global normal <c-x> ':inc %val{count} -<ret>'
}

## Handy for selecting multi parapraph ('}p}p}p' vs '}P}P}P').
map global object P p -docstring 'paragraph'

## Faster view mode.
map global normal <c-v> 4V

## Arrow keys alias in view mode.
map global view <left>  h -docstring 'scroll left'
map global view <down>  j -docstring 'scroll down'
map global view <up>    k -docstring 'scroll up'
map global view <right> l -docstring 'scroll right'

## Indent settings. Default 2 spaces.
set-option global indentwidth 2
# Use a tab in golang.
hook global BufSetOption filetype=go %{
    set-option buffer indentwidth 0
    set-option buffer tabstop 2
}
# Keep using 4 spaces in rust and kak.
hook global BufSetOption filetype=(rust|kak) %{
    set-option buffer indentwidth 4
}

## Smart Indent.
hook global InsertChar \t -group smart-indent tab-indent
define-command -hidden tab-indent %{
    evaluate-commands -draft -itersel %{ try %{
        execute-keys -draft h<a-h> '<a-k>^\h*\t\z<ret>' '<a-:>;d' <a-gt>
    }}
}
hook global InsertDelete ' ' -group smart-indent bs-de-indent
define-command -hidden bs-de-indent %{
    evaluate-commands -draft -itersel %{ try %{
        execute-keys -draft <a-h> '<a-k>^\h+.\z<ret>' 'i <esc>' <lt>
    }}
}

## Plugins.

source "%val{config}/plugins/plug.kak/rc/plug.kak"

plug "robertmeta/plug.kak" noload

plug "kak-lsp/kak-lsp" do %{
    cargo install --locked --force --path .
} config %{
    ## Enable Language Server Protocol for golang.
    hook global WinSetOption filetype=go %{
        lsp-enable-window
        map window user d ':lsp-hover<ret>' -docstring 'run lsp-hover.'
    }
}

plug "harryoooooooooo/src-outline.kak" config %{
    map global user o ':src-outline<ret>' -docstring 'show outline'
}

plug "harryoooooooooo/exchange.kak" config %{
    map global user x ':exchange<ret>' -docstring 'mark/commit the exchange'
    map global user <a-x> ':exchange clear<ret>' \
        -docstring 'clear the marked exchange'
}

plug "harryoooooooooo/diff.kak" config %{
    diff-enable-auto-detect
    map global user n ':diff-jump-hunk next<ret>' -docstring 'jump to next diff hunk of the current file'
    map global user p ':diff-jump-hunk prev<ret>' -docstring 'jump to prev diff hunk of the current file'
}

## Commands.

define-command -docstring '
pwd: Show the current working directory.' \
    -params 0 pwd %{
    echo %sh{pwd}
}

declare-option -hidden bool toggle_wrap_state false
define-command -docstring '
toggle-wrap: Toggle between wrap and nowrap on current window.
Note that for each window this command always starts from being as nowrap.' \
    -params 0 toggle-wrap %{ evaluate-commands %sh{
    if [ "${kak_opt_toggle_wrap_state}" = true ]; then
        echo 'set-option window toggle_wrap_state false'
        echo 'remove-highlighter window/toggle-wrap'
        echo 'echo -markup {Information}Disabled wrapping'
    else
        echo 'set-option window toggle_wrap_state true'
        echo 'add-highlighter window/toggle-wrap wrap'
        echo 'echo -markup {Information}Enabled wrapping'
    fi
}}
map global user w ':toggle-wrap<ret>' -docstring 'toggle wrap and unwrap line.'

try %{
evaluate-commands %sh{
    if ! command -v osc52 >/dev/null 2>&1; then
        echo 'echo -debug Missing osc52 script, :clip command will not be defined.'
        echo 'echo -debug Sample script can be found at: https://chromium.googlesource.com/apps/libapps/+/master/hterm/etc/osc52.sh'
        echo 'fail Missing osc52 script'
    fi
}
define-command -docstring '
clip: Copy the selected text to clipboard by using OSC 52 escape sequence.
Additional support/configuring of terminal may be needed.' \
    -params 0 clip %{ evaluate-commands %sh{
    if printf '%s' "${kak_selection}" | osc52 >/proc/$kak_client_pid/fd/1; then
        echo 'echo -markup {Information}Selection copied.'
    else
        echo 'fail Failed to copy the selection'
    fi
}}
map global user c ':clip<ret>' -docstring 'copy selection to clipboard.'
}

declare-option -hidden -docstring %{
    This option should define a template script for commands to run a
    program on a terminal-like environment, while the stdin and stdout of
    the program can still be controlled (with redirection) by the commands.

    Usually it should be set by the windowing modules.

    Sample usage by the commands:
        script=`printf "${kak_opt_term_run_template}" "fzf"`
        filename="$(ag -g '' | sh -c "${script}")"

    The example above should launch a terminal for users to interact with
    the given command "fzf".
} str term_run_template

try %{
evaluate-commands %sh{
    if ! command -v ag >/dev/null 2>&1; then
        echo 'echo -debug Missing ag command, :find command will not be defined.'
        echo 'fail Missing ag command'
    fi
}
define-command -docstring '
find: Invoke fzf to find and open a file' \
    -params 0 find %{ evaluate-commands %sh{
    if [ -z "${kak_opt_term_run_template}" ]; then
        echo "fail term_run_template is not set"
        exit
    fi
    script=`printf "${kak_opt_term_run_template}" "fzf"`
    filename=`ag -g '' | sh -c "${script}"`
    if [ -n "${filename}" ]; then
        printf 'edit "%s"\n' "${filename}"
    fi
}}
map global user f ':find<ret>' -docstring 'find file under cwd with fzf'
}

try %{
evaluate-commands %sh{
    if ! command -v sudo >/dev/null 2>&1; then
        echo 'echo -debug Missing sudo command, :sudo-write command will not be defined.'
        echo 'fail Missing sudo command'
    fi
}
define-command -docstring '
sudo-write [<filename>]: Write as root.' \
    -params 0..1 sudo-write %{
    execute-keys -draft " %%:sudo-write-impl '%arg{1}'<ret>"
}
define-command -hidden -params 1 sudo-write-impl %{ evaluate-commands %sh{
    if [ -z "${kak_opt_term_run_template}" ]; then
        echo "fail term_run_template is not set"
        exit
    fi
    filename="${kak_buffile}"
    if [ -n "$1" ]; then
        filename="$1"
    fi
    script=`printf "${kak_opt_term_run_template}" "sudo tee ${filename}"`
    printf '%s' "${kak_selection}" | sh -c "${script}" >/dev/null
}}
alias global sw sudo-write
}

hook global ModuleLoaded wayland|x11 %{

try %{
evaluate-commands %sh{
    if ! command -v urxvt >/dev/null 2>&1; then
        echo 'echo -debug Missing urxvt command, term_run_template will not be set'
        echo 'fail Missing urxvt command'
    fi
}
set-option global term_run_template %{
    urxvt -title float-urxvt -e bash -c "%s </proc/$$/fd/0 >/proc/$$/fd/1" </dev/null 2>&1 | true
}
}

} # End of ModuleLoaded wayland|x11

hook global ModuleLoaded tmux %{

set-option global term_run_template %{
    sig=`mktemp --tmpdir kak-tmux-run-XXXXXX-done`
    TMUX="${kak_client_env_TMUX}" tmux \
        splitw -l 15 "%s </proc/$$/fd/0 >/proc/$$/fd/1; tmux wait-for -S ${sig}" \; \
        wait-for ${sig} </dev/null >/dev/null 2>&1
    rm ${sig}
}

alias global terminal tmux-terminal-horizontal

define-command -docstring '
new [<commands>]: Create a new kakoune client horizontally.
The optional arguments are passed as commands to the new client' \
    -override -params .. -command-completion new %{
    tmux-terminal-vertical kak -c %val{session} -e "%arg{@}"
}
define-command -docstring '
vnew [<commands>]: Similar to :new, but vertically.' \
    -params .. -command-completion vnew %{
    tmux-terminal-horizontal kak -c %val{session} -e "%arg{@}"
}
define-command -docstring '
tnew [<commands>]: Similar to :new, but on a new tab.' \
    -params .. -command-completion tnew %{
    tmux-terminal-window kak -c %val{session} -e "%arg{@}"
}

} # End of ModuleLoaded tmux
