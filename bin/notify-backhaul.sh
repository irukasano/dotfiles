#!/usr/bin/env bash
# stdin で受けた JSON を 127.0.0.1:53245 へ転送
# （RemoteForward によりローカルPCの 127.0.0.1:53245 へ届く）
set -euo pipefail

# --- logging setup (non-fatal) ---
LOG_DIR="${XDG_CACHE_HOME:-"$HOME/.cache"}/codex"
LOG_FILE="$LOG_DIR/notify-backhaul.log"
{
  mkdir -p "$LOG_DIR"
} || true

log() {
  # Avoid aborting on logging errors
  {
    printf '[%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >>"$LOG_FILE"
  } || true
}

log "==== notify-backhaul.sh invoked ===="
log "script: $0"
log "pwd: $(pwd)"
log "user: ${USER:-unknown} host: ${HOSTNAME:-unknown}"
log "args: [$#] -> $*"

resolve_sender() {
  local ssh_connection sender
  ssh_connection="${SSH_CONNECTION:-}"
  if [ -n "$ssh_connection" ]; then
    # SSH_CONNECTION = client_ip client_port server_ip server_port
    sender="$(printf '%s\n' "$ssh_connection" | awk '{print $3}')"
    if [ -n "$sender" ]; then
      printf '%s\n' "$sender"
      return 0
    fi
  fi

  printf '%s\n' "${HOSTNAME:-unknown}"
}

resolve_tmux_context() {
  local pane_id session_name window_name

  pane_id="${TMUX_PANE:-}"
  if [ -z "$pane_id" ] || ! command -v tmux >/dev/null 2>&1; then
    return 1
  fi

  session_name="$(tmux display-message -p -t "$pane_id" '#{session_name}' 2>/dev/null)" || return 1
  window_name="$(tmux display-message -p -t "$pane_id" '#{window_name}' 2>/dev/null)" || return 1

  if [ -z "$session_name" ] || [ -z "$window_name" ]; then
    return 1
  fi

  printf '%s\t%s\n' "$session_name" "$window_name"
}

# Accept JSON from argument only to avoid STDIN block
if [ $# -ge 1 ]; then
  payload="$1"
  source_desc="args"
  log "payload_source: $source_desc bytes=${#payload}"
  # Warn if multiple args were passed (likely missing quotes)
  if [ $# -gt 1 ]; then
    log "warn: multiple arguments received (#=$#); using only first"
  fi
else
  payload=""
  source_desc="none"
  log "payload_source: $source_desc (no args)"
  # No payload provided; do nothing but keep Codex running
  exit 0
fi

sender="$(resolve_sender)"
log "sender: $sender"

tmux_session=""
tmux_window=""
if tmux_context="$(resolve_tmux_context)"; then
  IFS=$'\t' read -r tmux_session tmux_window <<EOF
$tmux_context
EOF
  log "tmux: session=$tmux_session window=$tmux_window"
else
  log "tmux: unavailable"
fi

if augmented_payload="$(printf '%s\n' "$payload" | python3 -c '
import json
import sys

sender = sys.argv[1]
tmux_session = sys.argv[2]
tmux_window = sys.argv[3]
raw = sys.stdin.read()
value = json.loads(raw)
if isinstance(value, dict):
    value["sender"] = sender
    if tmux_session:
        value["tmux_session"] = tmux_session
    if tmux_window:
        value["tmux_window"] = tmux_window
    sys.stdout.write(json.dumps(value, separators=(",", ":")))
else:
    sys.stdout.write(raw)
' "$sender" "$tmux_session" "$tmux_window" 2>/dev/null)"; then
  payload="$augmented_payload"
  log "payload_augmented: object sender/tmux added"
else
  log "payload_augmented: skipped (invalid json payload)"
fi

# Try to open TCP connection; on failure, log and exit 0 to avoid breaking Codex
if exec 3>/dev/tcp/127.0.0.1/53245; then
  log "tcp_connect: ok -> 127.0.0.1:53245"
else
  log "tcp_connect: failed -> 127.0.0.1:53245 (tunnel not ready?)"
  exit 0
fi

if printf '%s\n' "$payload" >&3; then
  log "send: ok bytes=${#payload}"
else
  log "send: failed"
fi
exec 3>&-
log "stream: closed"
