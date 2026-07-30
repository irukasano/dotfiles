#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [codex args...]
EOF
}

is_github_origin_repo() {
  local origin_url

  if ! command -v git >/dev/null 2>&1; then
    return 1
  fi

  if ! origin_url=$(git remote get-url origin 2>/dev/null); then
    return 1
  fi

  case "$origin_url" in
    *github.com*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

main() {
  local exit_code codex_launcher

  codex_launcher="codex"
  if is_github_origin_repo; then
    codex_launcher="$HOME/dotfiles/bin/codex-with-gh"
  fi

  if [[ "$codex_launcher" == */* ]] && [[ ! -x "$codex_launcher" ]]; then
    echo "Error: '$codex_launcher' is required." >&2
    exit 1
  fi
  set +e
  "$codex_launcher" "$@"
  exit_code=$?
  set -e

  printf '\n[codex pane] codex exited with status %d.\n' "$exit_code"
  exit "$exit_code"
}

main "$@"
