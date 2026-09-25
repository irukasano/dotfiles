#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
target_script="$project_root/bin/tmux-gh.sh"
fixture_bin="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/tmux-gh-repository-cache-bin" && pwd)"
test_root="$(mktemp -d /tmp/tmux-gh-repository-cache.XXXXXX)"
cache_base="/tmp/tmux-gh-${USER:-user}"
test_log="$test_root/gh.log"

cleanup() {
  local repo cache_key

  for repo in "$test_root/repo-a" "$test_root/repo-b"; do
    [[ -d "$repo/.git" ]] || continue
    cache_key="$(git -C "$repo" rev-parse --show-toplevel | cksum | awk '{print $1 "-" $2}')"
    rm -rf "$cache_base/$cache_key"
  done
  rm -rf "$test_root"
}
trap cleanup EXIT

assert_contains() {
  local expected="$1"
  local actual="$2"

  [[ "$actual" == *"$expected"* ]] || {
    echo "Expected output to contain: $expected" >&2
    echo "Actual output: $actual" >&2
    exit 1
  }
}

run_in_repo() {
  local repo="$1"
  shift
  (
    cd "$repo"
    PATH="$fixture_bin:$PATH" TMUX_GH_TEST_LOG="$test_log" "$target_script" "$@"
  )
}

mkdir -p "$test_root/repo-a" "$test_root/repo-b"
git -C "$test_root/repo-a" init -q
git -C "$test_root/repo-b" init -q

assert_contains 'issue-repo-a' "$(run_in_repo "$test_root/repo-a" __list-issue)"
assert_contains 'issue-repo-b' "$(run_in_repo "$test_root/repo-b" __list-issue)"
assert_contains 'issue-repo-a' "$(run_in_repo "$test_root/repo-a" __list-issue)"

[[ "$(rg -c '^fetch-list:' "$test_log")" == '2' ]] || {
  echo 'Expected one list fetch per repository.' >&2
  exit 1
}

assert_contains 'preview-repo-a' "$(run_in_repo "$test_root/repo-a" __preview-issue 42)"
assert_contains 'preview-repo-b' "$(run_in_repo "$test_root/repo-b" __preview-issue 42)"
assert_contains 'preview-repo-a' "$(run_in_repo "$test_root/repo-a" __preview-issue 42)"

[[ "$(rg -c '^fetch-preview:' "$test_log")" == '2' ]] || {
  echo 'Expected one preview fetch per repository.' >&2
  exit 1
}

if (
  cd "$test_root"
  PATH="$fixture_bin:$PATH" "$target_script" __clear-preview-issue
) >"$test_root/non-repository.out" 2>&1; then
  echo 'Expected a non-repository cache operation to fail.' >&2
  exit 1
fi

rg -q 'tmux-gh cache requires a Git repository' "$test_root/non-repository.out"
echo 'tmux-gh repository cache test: passed'
