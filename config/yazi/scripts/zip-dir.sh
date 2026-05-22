#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'zip-dir: %s\n' "$1" >&2
  exit 1
}

cwd=$(pwd -P)

resolve_path() {
  local path=$1

  if [[ -z "$path" ]]; then
    return 1
  fi

  if [[ "$path" != /* ]]; then
    path="${cwd}/${path}"
  fi

  realpath -e -- "$path"
}

hovered=${1-}
shift || true

targets=()
if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    targets+=("$arg")
  done
elif [[ -n "$hovered" ]]; then
  targets+=("$hovered")
else
  fail "no directory selected"
fi

names=()
for target in "${targets[@]}"; do
  abs=$(resolve_path "$target") || fail "invalid target: $target"
  [[ -d "$abs" ]] || fail "not a directory: $(basename "$target")"

  parent=$(dirname "$abs")
  [[ "$parent" == "$cwd" ]] || fail "selection outside current directory is not supported"

  names+=("$(basename "$abs")")
done

if [[ ${#names[@]} -eq 1 ]]; then
  dest="${names[0]}.zip"
else
  dest="archive-$(date +%Y%m%d-%H%M%S).zip"
fi

[[ ! -e "$cwd/$dest" ]] || fail "archive already exists: $dest"

zip_args=()
for name in "${names[@]}"; do
  zip_args+=("./$name")
done

cd "$cwd"
zip -r "$dest" "${zip_args[@]}"
