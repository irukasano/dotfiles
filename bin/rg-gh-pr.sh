#!/usr/bin/env bash
set -euo pipefail

PATTERN="${1:-}"

if [[ -z "$PATTERN" ]]; then
  echo "Usage: $0 SEARCH_PATTERN"
  exit 1
fi

# ripgrep があれば優先
if command -v rg >/dev/null 2>&1; then
  GREP="rg -n"
else
  GREP="grep -n"
fi

echo "Searching open PRs for pattern: $PATTERN"
echo

gh pr list --state open --limit 500 \
  --json number,title,headRefName,author \
  --jq '.[] | [.number, .title, .headRefName, .author.login] | @tsv' |
while IFS=$'\t' read -r pr title branch author; do

  diff=$(gh pr diff "$pr")

  hits=$(printf '%s\n' "$diff" | $GREP "$PATTERN" || true)

  if [[ -n "$hits" ]]; then
    printf '\nPR #%s | %s | %s | %s\n' "$pr" "$author" "$branch" "$title"
    printf '%s\n' "$hits"
  fi

done

