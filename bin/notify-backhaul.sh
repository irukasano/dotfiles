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

if augmented_payload="$(printf '%s\n' "$payload" | python3 -c '
import json
import sys

sender = sys.argv[1]
raw = sys.stdin.read()
value = json.loads(raw)
if isinstance(value, dict):
    value["sender"] = sender
    sys.stdout.write(json.dumps(value, separators=(",", ":")))
else:
    sys.stdout.write(raw)
' "$sender" 2>/dev/null)"; then
  payload="$augmented_payload"
  log "payload_augmented: object sender added"
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
