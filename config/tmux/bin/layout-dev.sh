#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <target-pane-id> <dir>
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required." >&2
    exit 1
  fi
}

main() {
  local target_pane="$1"
  local dir="$2"

  if [[ $# -ne 2 ]]; then
    usage
    exit 1
  fi

  require_cmd tmux
  require_cmd fish
  require_cmd codex

  tmux respawn-pane -k -t "$target_pane" -c "$dir" 'exec fish' >/dev/null
  tmux split-window -h -P -F '#{pane_id}' -p 40 -t "$target_pane" -c "$dir" 'exec codex' >/dev/null
  tmux select-pane -t "$target_pane"
}

main "$@"
