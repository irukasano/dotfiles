#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
command_path="$repo_root/config/codex/bin/codex-lesson"
fixture_dir="$(mktemp -d "$repo_root/ai/tasks/workspace/codex-lesson.XXXXXX")"
fixture_base="$fixture_dir/ai"

cleanup() {
  rm -rf "$fixture_dir"
}
trap cleanup EXIT

mkdir -p "$fixture_base/tasks"
printf '%s\n' '# Lessons' '- legacy lesson' > "$fixture_base/tasks/lessons.md"

"$command_path" --ai-base "$fixture_base" migrate-init >/dev/null
test -f "$fixture_base/tasks/lessons-legacy.md"
rg -q --fixed-strings -- '- legacy lesson' "$fixture_base/tasks/lessons-legacy.md"

add_result="$("$command_path" --ai-base "$fixture_base" add \
  --title '標準入力を競合させない' \
  --rule 'パイプ入力を読む処理では標準入力を別用途に使わない。' \
  --scope 'Bash、パイプ入力' \
  --review 'tasks/todo/example.md#review')"
rg -q '"indexed": false' <<<"$add_result"
rg -q --fixed-strings -- '## 標準入力を競合させない' "$fixture_base/tasks/lessons.md"
rg -q --fixed-strings -- '- Scope: Bash、パイプ入力' "$fixture_base/tasks/lessons.md"

if "$command_path" --ai-base "$fixture_base" search --query '標準入力'; then
  echo 'search unexpectedly succeeded without installed vector dependencies' >&2
  exit 1
fi

echo 'codex-lesson Markdown-only fixture passed'
