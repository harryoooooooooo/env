function _add_path { [[ :"$PATH": = *:"$1":* ]] || export PATH="$1:$PATH"; }
_add_path "$HOME"/.local/bin
_add_path "$HOME"/.cargo/bin
_add_path "$HOME"/go/bin
unset -f _add_path

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Disable ctrl+s (freeze the terminal)
stty -ixon
# Don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth
HISTSIZE=64000
HISTFILESIZE=64000
# Append to the history file, don't overwrite it
shopt -s histappend
# Check the window size and update the values of LINES and COLUMNS
shopt -s checkwinsize
# Enable `**`
shopt -s globstar
# Enable more pattern matching syntax e.g. `+(pattern-list)`
shopt -s extglob

_last_command=
_last_command_start_time=
_last_command_status=
_last_command_end_time=
function _pre_command_hook {
  _last_command="${BASH_COMMAND}"
  _last_command_start_time=`date +%s`
  # This happened when user typed empty command.
  if [[ "${_last_command}" == "_post_command_hook" ]]; then
    _last_command=
  fi
}
function _post_command_hook {
  _last_command_status=$?
  _last_command_end_time=`date +%s`
  _notify_command_done
}
function _ps_gen {
  # Date and time
  printf %s "\[\033[38;5;220m\][\d \t]\[\033[0m\]"
  # Return status
  if [[ ${_last_command_status} != 0 ]]; then
    printf "%s" " \[\033[1;38;5;15;48;5;9m\] ${_last_command_status} \[\033[0m\]"
  fi
  # Git status
  GIT_PS1_SHOWDIRTYSTATE=true GIT_PS1_SHOWUNTRACKEDFILES=true GIT_PS1_SHOWCOLORHINTS=true __git_ps1
  # Working directory
  printf %s " \[\033[1;38;5;12m\]\w\[\033[0m\]>\n"

  # User name and host name
  printf %s "\[\033[1;38;5;10m\]\u@\h\[\033[0m\]\$ "
}
PROMPT_COMMAND='
_post_command_hook
PS1=`_ps_gen`
trap "trap - DEBUG; _pre_command_hook" DEBUG
(exit ${_last_command_status})
'

if [[ "${TERM}" = *256color* ]]; then
  export COLORTERM=truecolor
fi

export EDITOR=kak

# /tmp is mounted as NOEXEC inside Crostini
# This is necessary for running `go run xxx`
export GOTMPDIR="${HOME}"/go/tmp

alias l='ls'
alias la='ls -A'
alias ll='ls -lh'
alias lla='ll -a'
alias ls='ls --color=auto -F'
alias ..='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'

alias history.sync='history -a; history -c; history -r'

alias clip='osc52'
alias alert='hterm-notify'
alias vimnull='vimdiff +set\ paste /dev/null'

function t {
  tmux new -As "${1:-main}"
}
function _complete_tmux_attach {
  if [[ "${COMP_CWORD}" -ne 1 ]]; then
    return
  fi
  COMPREPLY=($(compgen -W "$(tmux ls 2>/dev/null | sed 's/:.*//g')" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -o default -F _complete_tmux_attach t

function kakc {
  if [[ "$#" -eq 1 ]]; then
    kak -c "$1"
    return $?
  fi

  if [[ "$#" -lt 3 ]]; then
    cat 1>&2 <<EOF
usage:
  kakc <session>
  kakc <session> <client> <filename> [<line> [<column>]]
EOF
    return 87
  fi

  local session="$1"
  local client="$2"
  local file="$3"
  shift 3

  file="$(realpath -s "${file}")"
  printf 'eval -client %s %%{edit %s %s}' "${client}" "${file}" "${*}" \
    | kak -p "${session}"
}
function _complete_kakoune_connect {
  if [[ "${COMP_CWORD}" -ne 1 ]]; then
    return
  fi
  COMPREPLY=($(compgen -W "$(kak -l | grep -v dead)" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -o default -F _complete_kakoune_connect kakc

NOTIFY_COMMAND_DONE_THRESHOLD=20
NOTIFY_COMMAND_DONE_BLOCK_LIST=(
  t ssh
  man git hg
  kak kakc vim vimdiff
)
NOTIFY_COMMAND_DONE_MODE=auto
function _notify_command_done {
  [ -z "${_last_command_start_time}" ] && return
  [[ "${NOTIFY_COMMAND_DONE_MODE}" == "off" ]] && return

  local full_comm="${_last_command}"
  # Clear leading and trailing spaces
  full_comm="${full_comm##*( )}"
  full_comm="${full_comm%%*( )}"

  local b comm="${full_comm%% *}"
  [ -z "${comm}" ] && return
  for b in "${NOTIFY_COMMAND_DONE_BLOCK_LIST[@]}"; do
    [[ "${comm}" == "${b}" ]] && return
  done

  local duration=$((_last_command_end_time - _last_command_start_time))
  ((duration < NOTIFY_COMMAND_DONE_THRESHOLD)) && return

  local pretty_duration
  if ((duration >= 60*60)); then
    pretty_duration="${pretty_duration}$((duration/(60*60)))h"
    duration=$((duration%(60*60)))
  fi
  if ((duration >= 60)); then
    pretty_duration="${pretty_duration}$((duration/60))m"
    duration=$((duration%60))
  fi
  if ((duration > 0)); then
    pretty_duration="${pretty_duration}${duration}s"
  fi
  local title="done in ${pretty_duration}"
  [[ ${_last_command_status} != 0 ]] && title="${title}, status=${_last_command_status}"

  local tty
  if [ -z ${TMUX} ]; then
    hterm-notify "${title}" "${full_comm}"
  elif tty=`tmux display-message -p '#{client_tty}' 2>/dev/null` && [ -n "${tty}" ]; then
    TERM=xterm hterm-notify "${title}" "${full_comm}" > "${tty}"
  else
    notify-send "${title}" "${full_comm}"
  fi
}
function set_notify_command_done_mode {
  case "$1" in
    auto|off)
      NOTIFY_COMMAND_DONE_MODE="$1"
      return 0
      ;;
    *)
      echo "Invalid mode '$1'" 1>&2
      return 87
      ;;
  esac
}
function _complete_set_notify_command_done_mode {
  COMPREPLY=($(compgen -W "auto off" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _complete_set_notify_command_done_mode set_notify_command_done_mode

# Bind Ctrl/Alt + p/n to search prefix/substring backward/forward history.
bind '"\C-p":history-search-backward'
bind '"\C-n":history-search-forward'
bind '"\ep":history-substring-search-backward'
bind '"\en":history-substring-search-forward'

. /usr/share/bash-completion/bash_completion
. /usr/share/git/git-prompt.sh

if . /usr/share/fzf/completion.bash; then
  function _fzf_compgen_path {
    ag -g "$1"
  }
  export FZF_COMPLETION_TRIGGER=",,"
  complete -o bashdefault -o default -F _fzf_path_completion kak
fi
