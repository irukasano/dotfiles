#!/usr/bin/env bash
# stdin で受けた JSON を 127.0.0.1:53245 へ転送
# （RemoteForward によりローカルPCの 127.0.0.1:53245 へ届く）
set -euo pipefail

payload="$(cat)"
# トンネル未確立でも失敗でCodexを止めない
exec 3>/dev/tcp/127.0.0.1/53245 || exit 0
printf '%s\n' "$payload" >&3 || true
exec 3>&-

