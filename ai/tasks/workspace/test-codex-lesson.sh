#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
command_path="$repo_root/config/codex/bin/codex-lesson"
fixture_dir="$(mktemp -d "$repo_root/ai/tasks/workspace/codex-lesson.XXXXXX")"
markdown_base="$fixture_dir/markdown-only/ai"
vector_base="$fixture_dir/vector/ai"
original_home="$HOME"

cleanup() {
  rm -rf "$fixture_dir"
}
trap cleanup EXIT

mkdir -p "$markdown_base/tasks" "$fixture_dir/empty-home"
printf '%s\n' '# Lessons' '- legacy lesson' > "$markdown_base/tasks/lessons.md"

env -u HF_HOME HOME="$fixture_dir/empty-home" "$command_path" --ai-base "$markdown_base" migrate-init >/dev/null
test -f "$markdown_base/tasks/lessons-legacy.md"
rg -q --fixed-strings -- '- legacy lesson' "$markdown_base/tasks/lessons-legacy.md"

add_result="$(env -u HF_HOME HOME="$fixture_dir/empty-home" "$command_path" --ai-base "$markdown_base" add \
  --title '標準入力を競合させない' \
  --rule 'パイプ入力を読む処理では標準入力を別用途に使わない。' \
  --scope 'Bash、パイプ入力' \
  --review 'tasks/todo/example.md#review')"
rg -q '"indexed": false' <<<"$add_result"
rg -q --fixed-strings -- '## 標準入力を競合させない' "$markdown_base/tasks/lessons.md"
rg -q --fixed-strings -- '- Scope: Bash、パイプ入力' "$markdown_base/tasks/lessons.md"

if env -u HF_HOME HOME="$fixture_dir/empty-home" "$command_path" --ai-base "$markdown_base" search --query '標準入力'; then
  echo 'search unexpectedly succeeded without installed vector dependencies' >&2
  exit 1
fi

if env -u HF_HOME HOME="$fixture_dir/empty-home" "$command_path" --ai-base "$markdown_base" init; then
  echo 'init unexpectedly succeeded without installed vector dependencies' >&2
  exit 1
fi
test ! -e "$markdown_base/tasks/lessons.sqlite"

if [ -x "$original_home/.codex/lesson/.venv/bin/python" ] \
  && HF_HOME="$original_home/.codex/lesson/huggingface" "$command_path" --ai-base "$vector_base" check | rg -q '"vector_available": true'; then
  mkdir -p "$vector_base/tasks"
  printf '%s\n' \
    '# Lessons' \
    '## 初期同期の確認' \
    '' \
    '- ID: `00000000-0000-0000-0000-000000000001`' \
    '- Rule: 初期導入では索引を明示的に同期する。' \
    '- Scope: Codex lesson、SQLite、初期化' \
    '- Review: `tasks/todo/example.md#review`' \
    > "$vector_base/tasks/lessons.md"
  before_init_check="$(HF_HOME="$original_home/.codex/lesson/huggingface" "$command_path" --ai-base "$vector_base" check)"
  rg -q '"index_available": false' <<<"$before_init_check"
  HF_HOME="$original_home/.codex/lesson/huggingface" "$command_path" --ai-base "$vector_base" init
  test -f "$vector_base/tasks/lessons.sqlite"
  after_init_check="$(HF_HOME="$original_home/.codex/lesson/huggingface" "$command_path" --ai-base "$vector_base" check)"
  rg -q '"index_available": true' <<<"$after_init_check"
  search_result="$(HF_HOME="$original_home/.codex/lesson/huggingface" "$command_path" --ai-base "$vector_base" search --query '初期導入の SQLite 索引')"
  rg -q --fixed-strings -- '初期同期の確認' <<<"$search_result"
  rg -q --fixed-strings -- 'tasks/todo/example.md#review' <<<"$search_result"
  echo 'codex-lesson vector fixture passed'
else
  echo 'codex-lesson vector fixture skipped (lesson venv or model unavailable)'
fi

echo 'codex-lesson Markdown-only fixture passed'
