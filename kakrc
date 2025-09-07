colorscheme palenight

# Set background to Default to keep the background image of the terminal.
set-face global Default default,default
set-face global BufferPadding rgb:4b5263,default

# Set eye-catching and related color to the cursor and the matching char.
set-face global PrimaryCursor rgb:c792ea,white+bfg
set-face global MatchingChar  white,blue+dbfg
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

define-command -hidden -params 2.. needs-commands %{ evaluate-commands %sh{
    requester="${1}"
    shift
    for cmd in "$@"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            printf '%s\n' "echo -debug Missing ${cmd} command, ${requester} won't be set"
            printf '%s\n' "fail Missing ${cmd} command"
        fi
    done
}}

## Rg is much faster then grep.
try %{ needs-commands grepcmd rg
set-option global grepcmd 'rg --no-heading --column --no-context-separator'
}
map global user g ':grep ' -docstring 'grep text under cwd'
map global user G %{<a-i>w*:grep '<c-r>/'<ret>} -docstring 'grep the word under cursor under cwd'

## Add the same <c-a>/<c-x> functions as vim.
try %{ needs-commands '<c-a>/<c-x>' bc
define-command -hidden -params 2 inc %{
    evaluate-commands %sh{
        if [ "$1" = 0 ]; then
            count=1
        else
            count="$1"
        fi
        printf '%s%s%s\n' 'execute-keys <a-i>na' "$2($count)" '<ret><esc>|bc|tr<space>-d<space>\\n<ret>'
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
# Languages that prefer tabs.
hook global BufSetOption filetype=(go|ini) %{
    set-option buffer indentwidth 0
    set-option buffer tabstop 2
}
# Languages that prefer 4 spaces.
hook global BufSetOption filetype=(rust|kak) %{
    set-option buffer indentwidth 4
}
# Many C projects mix tab and space while assuming width=8.
hook global BufSetOption filetype=c %{
    set-option buffer indentwidth 0
    set-option buffer tabstop 8
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
    ## Enable Language Server Protocol.
    set-face global InlayHint rgb:777788,default+d
    set-face global Reference white,magenta+dF
    set-face global ReferenceBind white,magenta+duF
    set-option global lsp_auto_highlight_references true
    hook global WinSetOption filetype=(go|python|rust) %{
        lsp-enable-window
        map window user l ':enter-user-mode lsp<ret>' -docstring 'Enter lsp mode'
        map window insert <tab> '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>' \
            -docstring 'Select next snippet placeholder. <c-o> to close the complete window before using this.'
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
    map global user n ':diff-jump-hunk next<ret>' -docstring 'jump to next diff hunk'
    map global user p ':diff-jump-hunk prev<ret>' -docstring 'jump to prev diff hunk'
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

try %{ needs-commands 'clip (see https://chromium.googlesource.com/apps/libapps/+/main/hterm/etc/osc52.sh)' osc52
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
define-command -docstring '
clip-fn: Copy the filename to clipboard by using OSC 52 escape sequence.
Additional support/configuring of terminal may be needed.' \
    -params 0 clip-fn %{ evaluate-commands %sh{
    if printf '%s' "${kak_bufname}" | osc52 >/proc/$kak_client_pid/fd/1; then
        echo 'echo -markup {Information}Filename copied.'
    else
        echo 'fail Failed to copy the filename'
    fi
}}
map global user C ':clip-fn<ret>' -docstring 'copy filename to clipboard.'
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

try %{ needs-commands find rg fzf
define-command -docstring '
find: Invoke fzf to find and open a file' \
    -params 0 find %{ evaluate-commands %sh{
    if [ -z "${kak_opt_term_run_template}" ]; then
        echo "fail term_run_template is not set"
        exit
    fi
    script=`printf "${kak_opt_term_run_template}" "fzf"`
    filename=`rg -l '' | sh -c "${script}"`
    if [ -n "${filename}" ]; then
        printf 'edit "%s"\n' "${filename}"
    fi
}}
map global user f ':find<ret>' -docstring 'find file under cwd with fzf'
}

try %{ needs-commands sudo-write sudo
define-command -docstring '
sudo-write [<filename>]: Write as root.' \
    -params 0..1 sudo-write %{
    execute-keys -draft ",%%:sudo-write-impl '%arg{1}'<ret>"
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

define-command -docstring '
mouse [on|off]: Enable/disable mouse.' \
    -shell-script-candidates %{ printf 'on\noff\n' } \
    -params 1 mouse %{ evaluate-commands %sh{
    case "$1" in
        on)
            echo "set-option -add global ui_options terminal_enable_mouse=true"
            ;;
        off)
            echo "set-option -add global ui_options terminal_enable_mouse=false"
            ;;
        *)
            echo "fail Invalid parameter"
            ;;
    esac
}}

hook global ModuleLoaded wayland|x11 %{

try %{ needs-commands term_run_template alacritty
set-option global term_run_template %{
    alacritty -t float-alacritty -e bash -c "%s </proc/$$/fd/0 >/proc/$$/fd/1" </dev/null 2>&1 | true
}
}

} # End of ModuleLoaded wayland|x11

hook global ModuleLoaded tmux %{

set-option global term_run_template %{
    sig=`mktemp --tmpdir kak-tmux-run-XXXXXX-done`
    TMUX="${kak_client_env_TMUX}" tmux \
        display-popup -E "%s </proc/$$/fd/0 >/proc/$$/fd/1; tmux wait-for -S ${sig}" \; \
        wait-for ${sig} </dev/null >/dev/null 2>&1
    rm ${sig}
}

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
    tmux-terminal-window -a kak -c %val{session} -e "%arg{@}"
}

define-command -docstring '
smart-split: Split the tmux window vertically when wide enough, otherwise horizontally.' \
    -params .. -command-completion smart-split %{ evaluate-commands %sh{
    if [ "${kak_window_width}" -ge 180 ]; then
        comm=vnew
    else
        comm=new
    fi
    for x in "$@"; do
        comm="${comm} %{${x}}"
    done
    printf %s "${comm}"
}}
map global normal <c-s-F9> ':smart-split b %val{bufname} \; select %val{selection_desc}<ret>'
map global normal <c-F9> ':tnew b %val{bufname} \; select %val{selection_desc}<ret>'

} # End of ModuleLoaded tmux
