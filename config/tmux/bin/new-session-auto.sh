#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [--socket-path <path>] <dir>
  $(basename "$0") [--socket-path <path>] --rename-default <session-target>
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

normalize_name() {
  local raw="$1"
  local normalized

  normalized="$(printf '%s' "$raw" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[[:space:]]+/-/g; s/[^a-z0-9_-]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')"

  if [[ -z "$normalized" ]]; then
    normalized="session"
  fi

  printf '%s\n' "$normalized"
}

pick_adjective() {
  local adjectives=(
    agile
    airy
    amber
    bright
    calm
    candid
    clever
    crisp
    deft
    dapper
    eager
    gentle
    glib
    humble
    lively
    lucid
    mellow
    nimble
    polished
    quiet
    radiant
    robust
    serene
    steady
    swift
    subtle
    sunny
    tidy
    tranquil
    upbeat
    vivid
    warm
    wry
    zesty
  )

  printf '%s\n' "${adjectives[RANDOM % ${#adjectives[@]}]}"
}

session_exists() {
  local name="$1"
  tmux_cmd has-session -t "$name" >/dev/null 2>&1
}

build_session_name() {
  local dir="$1"
  local base adjective candidate suffix

  base="$(normalize_name "$(basename "$dir")")"
  adjective="$(pick_adjective)"
  candidate="${adjective}-${base}"

  if ! session_exists "$candidate"; then
    printf '%s\n' "$candidate"
    return 0
  fi

  suffix=2
  while session_exists "${candidate}-${suffix}"; do
    suffix=$((suffix + 1))
  done

  printf '%s-%s\n' "$candidate" "$suffix"
}

create_session() {
  local dir="$1"
  local session_name

  session_name="$(build_session_name "$dir")"
  tmux_cmd new-session -Ad -c "$dir" -s "$session_name"
  tmux_cmd display-message "created session: $session_name"
}

rename_default_session() {
  local session_target="$1"
  local current_name dir next_name

  current_name="$(tmux_cmd display-message -p -t "$session_target" '#{session_name}')"
  if [[ ! "$current_name" =~ ^[0-9]+$ ]]; then
    return 0
  fi

  dir="$(tmux_cmd display-message -p -t "$session_target" '#{pane_current_path}')"
  next_name="$(build_session_name "$dir")"
  tmux_cmd rename-session -t "$session_target" "$next_name"
}

main() {
  local args=()

  require_cmd tmux

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
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#args[@]} -eq 2 && "${args[0]}" == "--rename-default" ]]; then
    rename_default_session "${args[1]}"
    return 0
  fi

  if [[ ${#args[@]} -eq 1 ]]; then
    create_session "${args[0]}"
    return 0
  fi

  usage
  exit 1
}

main "$@"
