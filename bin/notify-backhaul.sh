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
