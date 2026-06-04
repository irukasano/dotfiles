#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0")
EOF
}

main() {
  local exit_code codex_launcher

  if [[ $# -ne 0 ]]; then
    usage >&2
    exit 1
  fi

  codex_launcher="$HOME/dotfiles/bin/codex-with-gh"
  if [[ ! -x "$codex_launcher" ]]; then
    echo "Error: '$codex_launcher' is required." >&2
    exit 1
  fi
  set +e
  "$codex_launcher"
  exit_code=$?
  set -e

  printf '\n[codex pane] codex exited with status %d.\n' "$exit_code"
  exit "$exit_code"
}

main "$@"
