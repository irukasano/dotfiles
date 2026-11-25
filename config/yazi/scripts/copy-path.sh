#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
    echo "copy-path: no paths provided" >&2
    exit 2
fi

if command -v wl-copy >/dev/null 2>&1; then
    printf '%s\n' "$@" | wl-copy
elif command -v xclip >/dev/null 2>&1; then
    printf '%s\n' "$@" | xclip -selection clipboard
else
    echo "copy-path: neither wl-copy nor xclip is available" >&2
    exit 127
fi
