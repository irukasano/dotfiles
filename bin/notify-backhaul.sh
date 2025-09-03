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

# Read STDIN fully (may be empty if caller passes args instead)
payload="$(cat)"
log "stdin_bytes: ${#payload}"
if [ -n "$payload" ]; then
  source_desc="stdin"
  # Log the first few KB to avoid runaway logs
  max=4096
  if [ ${#payload} -le $max ]; then
    log "stdin_sample: $payload"
  else
    log "stdin_sample: ${payload:0:$max} ... (truncated)"
  fi
else
  log "stdin_empty"
  # Fallback: if args exist, treat them as payload
  if [ $# -gt 0 ]; then
    payload="$*"
    source_desc="args"
    log "args_used_as_payload bytes=${#payload}"
  else
    source_desc="none"
  fi
fi
log "payload_source: $source_desc"

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
