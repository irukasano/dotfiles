#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [--socket-path <path>]
  $(basename "$0") [--socket-path <path>] --preview <pane-id>
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required." >&2
    exit 1
  fi
}

SOCKET_PATH=""

tmux_cmd() {
  if [[ -n "$SOCKET_PATH" ]]; then
    tmux -S "$SOCKET_PATH" "$@"
  else
    tmux "$@"
  fi
}

trim_line() {
  local value="$1"

  value="${value//$'\r'/}"
  value="${value//$'\t'/ }"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

pane_summary() {
  local pane_id="$1"

  tmux_cmd capture-pane -p -t "$pane_id" -S -80 \
    | awk '
      {
        gsub(/\r/, "", $0)
        line = $0
        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)
        if (line != "") {
          buf[count % 3] = line
          count++
        }
      }
      END {
        if (count == 0) {
          exit
        }

        start = count > 3 ? count - 3 : 0
        for (i = start; i < count; i++) {
          if (i > start) {
            printf " // "
          }
          printf "%s", buf[i % 3]
        }
      }
    '
}

preview_pane() {
  local pane_id="$1"
  local session_name window_name pane_index cwd cmd

  session_name="$(tmux_cmd display-message -p -t "$pane_id" '#{session_name}')"
  window_name="$(tmux_cmd display-message -p -t "$pane_id" '#{window_index}:#{window_name}')"
  pane_index="$(tmux_cmd display-message -p -t "$pane_id" '#{pane_index}')"
  cwd="$(tmux_cmd display-message -p -t "$pane_id" '#{pane_current_path}')"
  cmd="$(tmux_cmd display-message -p -t "$pane_id" '#{pane_current_command}')"

  printf 'session: %s\n' "$session_name"
  printf 'window : %s\n' "$window_name"
  printf 'pane   : %s (%s)\n' "$pane_index" "$pane_id"
  printf 'cwd    : %s\n' "$cwd"
  printf 'cmd    : %s\n' "$cmd"
  printf '\n'

  tmux_cmd capture-pane -p -t "$pane_id" -S -200
}

list_candidates() {
  local pane_id session_name window_id window_label pane_index cmd cwd summary

  tmux_cmd list-panes -a -F '#{pane_id}	#{session_name}	#{window_id}	#{window_index}:#{window_name}	#{pane_index}	#{pane_current_command}	#{pane_current_path}' \
    | while IFS=$'\t' read -r pane_id session_name window_id window_label pane_index cmd cwd; do
        summary="$(pane_summary "$pane_id")"
        summary="$(trim_line "$summary")"

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "$pane_id" \
          "$session_name" \
          "$window_id" \
          "$session_name:$window_label.$pane_index" \
          "$cmd" \
          "$cwd" \
          "$(basename "$cwd")" \
          "$summary"
      done
}

jump_to_pane() {
  local pane_id="$1"
  local session_name window_id

  session_name="$(tmux_cmd display-message -p -t "$pane_id" '#{session_name}')"
  window_id="$(tmux_cmd display-message -p -t "$pane_id" '#{window_id}')"

  tmux_cmd switch-client -t "$session_name"
  tmux_cmd select-window -t "$window_id"
  tmux_cmd select-pane -t "$pane_id"
}

run_picker() {
  local selection pane_id
  local preview_cmd

  preview_cmd="$0"
  if [[ -n "$SOCKET_PATH" ]]; then
    preview_cmd="$preview_cmd --socket-path $(printf '%q' "$SOCKET_PATH")"
  fi
  preview_cmd="$preview_cmd --preview {1}"

  selection="$(
    list_candidates \
      | fzf \
          --layout=reverse \
          --height=100% \
          --ansi \
          --border=rounded \
          --delimiter=$'\t' \
          --with-nth=4,5,6,8 \
          --prompt='pane> ' \
          --header='session/window/pane | command | cwd | recent output' \
          --preview="$preview_cmd" \
          --preview-window='right,55%,border-left,wrap'
  )" || return 0

  pane_id="${selection%%$'\t'*}"
  [[ -n "$pane_id" ]] || return 0

  jump_to_pane "$pane_id"
}

main() {
  local preview_target=""

  require_cmd tmux
  require_cmd fzf
  require_cmd awk

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --socket-path)
        if [[ $# -lt 2 ]]; then
          usage
          exit 1
        fi
        SOCKET_PATH="$2"
        shift 2
        ;;
      --preview)
        if [[ $# -lt 2 ]]; then
          usage
          exit 1
        fi
        preview_target="$2"
        shift 2
        ;;
      *)
        usage
        exit 1
        ;;
    esac
  done

  if [[ -n "$preview_target" ]]; then
    preview_pane "$preview_target"
    return 0
  fi

  run_picker
}

main "$@"
