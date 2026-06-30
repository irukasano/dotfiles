#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'convert-csv-to-cp932: %s\n' "$1" >&2
  exit 1
}

resolve_path() {
  local path=$1

  if [[ -z "$path" ]]; then
    return 1
  fi

  realpath -e -- "$path"
}

src_input=${1-}
[[ -n "$src_input" ]] || fail "no file selected"

src=$(resolve_path "$src_input") || fail "invalid file: $src_input"
[[ -f "$src" ]] || fail "not a file: $(basename "$src_input")"

dir=$(dirname "$src")
base=$(basename "$src")
name=${base%.*}
ext=${base##*.}

if [[ "$name" == "$base" ]]; then
  dest="${dir}/${base}.cp932"
else
  dest="${dir}/${name}.cp932.${ext}"
fi

tmp=$(mktemp "${dest}.tmp.XXXXXX")
cleanup() {
  rm -f -- "$tmp"
}
trap cleanup EXIT

iconv -f UTF-8 -t CP932 -- "$src" >"$tmp" || fail "iconv failed"

if [[ -e "$dest" ]]; then
  printf 'Overwrite %s? [y/N]: ' "$(basename "$dest")" >&2
  read -r reply || true
  case "$reply" in
    [Yy]|[Yy][Ee][Ss]) ;;
    *) fail "aborted" ;;
  esac
fi

mv -f -- "$tmp" "$dest"
trap - EXIT
printf 'Wrote %s\n' "$dest"
