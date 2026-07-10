#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  codex-focus-pane.sh --pane <pane-id> [--session <session-name>] [--window <window-name>]
EOF
}

die() {
  printf '%s\n' "$1" >&2
  exit "${2:-1}"
}

require_tmux() {
  if ! command -v tmux >/dev/null 2>&1; then
    die "tmux unavailable"
  fi

  if [[ -z "${TMUX:-}" ]]; then
    die "not in tmux"
  fi
}

tmux_value() {
  local target="$1"
  local format="$2"

  tmux display-message -p -t "$target" -F "$format"
}

main() {
  local pane_id=""
  local expected_session=""
  local expected_window=""
  local actual_session
  local actual_window
  local window_id

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pane)
        [[ $# -ge 2 ]] || die "missing pane"
        pane_id="$2"
        shift 2
        ;;
      --session)
        [[ $# -ge 2 ]] || die "missing session"
        expected_session="$2"
        shift 2
        ;;
      --window)
        [[ $# -ge 2 ]] || die "missing window"
        expected_window="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "invalid argument"
        ;;
    esac
  done

  [[ -n "$pane_id" ]] || {
    usage >&2
    die "pane required"
  }

  require_tmux

  if ! tmux display-message -p -t "$pane_id" -F '#{pane_id}' >/dev/null 2>&1; then
    die "pane not found"
  fi

  actual_session="$(tmux_value "$pane_id" '#{session_name}')"
  if [[ -n "$expected_session" && "$actual_session" != "$expected_session" ]]; then
    die "session mismatch"
  fi

  actual_window="$(tmux_value "$pane_id" '#{window_name}')"
  if [[ -n "$expected_window" && "$actual_window" != "$expected_window" ]]; then
    die "window mismatch"
  fi

  window_id="$(tmux_value "$pane_id" '#{window_id}')"

  tmux switch-client -t "$actual_session" \; select-window -t "$window_id" \; select-pane -t "$pane_id"
}

main "$@"
