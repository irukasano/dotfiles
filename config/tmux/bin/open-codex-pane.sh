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
  local codex_pane_script

  if [[ $# -ne 2 ]]; then
    usage >&2
    exit 1
  fi

  require_cmd tmux
  codex_pane_script="$HOME/dotfiles/config/tmux/bin/codex-pane.sh"

  if [[ ! -x "$codex_pane_script" ]]; then
    echo "Error: '$codex_pane_script' is required." >&2
    exit 1
  fi

  tmux split-window -h -P -F '#{pane_id}' -p 40 -t "$target_pane" -c "$dir" "$codex_pane_script" >/dev/null
  tmux select-pane -t "$target_pane"
}

main "$@"
