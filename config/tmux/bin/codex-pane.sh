#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0")
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required." >&2
    exit 1
  fi
}

detect_shell() {
  local shell_path=""

  if [[ -n "${TMUX:-}" ]]; then
    shell_path="$(tmux show-option -gv default-shell 2>/dev/null || true)"
  fi

  if [[ -z "$shell_path" ]]; then
    shell_path="${SHELL:-}"
  fi

  if [[ -z "$shell_path" ]]; then
    shell_path="/bin/sh"
  fi

  printf '%s\n' "$shell_path"
}

exec_shell() {
  local shell_path="$1"
  local shell_name

  shell_name="$(basename "$shell_path")"

  case "$shell_name" in
    bash|fish|zsh)
      exec "$shell_path" -l
      ;;
    *)
      exec "$shell_path"
      ;;
  esac
}

main() {
  local shell_path exit_code codex_launcher

  if [[ $# -ne 0 ]]; then
    usage >&2
    exit 1
  fi

  codex_launcher="$HOME/dotfiles/bin/codex-with-gh"
  if [[ ! -x "$codex_launcher" ]]; then
    echo "Error: '$codex_launcher' is required." >&2
    exit 1
  fi
  shell_path="$(detect_shell)"

  set +e
  "$codex_launcher"
  exit_code=$?
  set -e

  printf '\n[codex pane] codex exited with status %d. Returning to %s.\n' "$exit_code" "$shell_path"
  exec_shell "$shell_path"
}

main "$@"
