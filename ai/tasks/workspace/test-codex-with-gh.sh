#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
target="$project_root/bin/codex-with-gh"
fake_bin="$project_root/ai/tasks/workspace/codex-with-gh-test-bin"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

assert_equals() {
    expected=$1
    file=$2
    actual=$(sed -n '1p' "$file")

    if [ "$actual" != "$expected" ]; then
        echo "expected '$expected' in $file, got '$actual'" >&2
        exit 1
    fi
}

assert_not_exists() {
    path=$1

    if [ -e "$path" ]; then
        echo "did not expect $path" >&2
        exit 1
    fi
}

success_dir="$tmp_dir/success"
mkdir "$success_dir"
success_path="$fake_bin:$PATH"
script -q -e -c "env -u GH_TOKEN PATH='$success_path' TEST_DIR='$success_dir' TMPDIR='$success_dir' LANG='ja_JP.UTF-8' UNRELATED_SECRET='must-not-pass' SSH_AUTH_SOCK='/tmp/fake-agent' FAKE_GH_RESULT=success FAKE_PASS_RESULT=success '$target' --model test-model" /dev/null >"$success_dir/stdout" 2>"$success_dir/stderr"
assert_equals 'unset' "$success_dir/gh-token"
assert_equals 'unset' "$success_dir/pass-token"
assert_equals 'fixture-token' "$success_dir/codex-token"
assert_equals 'unset' "$success_dir/codex-unrelated-secret"
assert_equals 'unset' "$success_dir/codex-ssh-auth-sock"
assert_equals 'ja_JP.UTF-8' "$success_dir/codex-lang"
assert_equals 'tty' "$success_dir/codex-stdin"
assert_equals '-c' "$success_dir/codex-args"
if [ "$(sed -n '2p' "$success_dir/codex-args")" != 'shell_environment_policy.inherit="all"' ] || \
    [ "$(sed -n '3p' "$success_dir/codex-args")" != '--model' ] || \
    [ "$(sed -n '4p' "$success_dir/codex-args")" != 'test-model' ]; then
    echo 'expected Codex arguments to be preserved' >&2
    exit 1
fi
if [ -s "$success_dir/stdout" ] || [ -s "$success_dir/stderr" ]; then
    echo 'did not expect token or diagnostics on successful launch' >&2
    exit 1
fi

pass_failure_dir="$tmp_dir/pass-failure"
mkdir "$pass_failure_dir"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_DIR="$pass_failure_dir" \
    FAKE_GH_RESULT=success FAKE_PASS_RESULT=failure \
    "$target" >"$pass_failure_dir/stdout" 2>"$pass_failure_dir/stderr"; then
    echo 'expected pass failure' >&2
    exit 1
fi
assert_not_exists "$pass_failure_dir/codex-token"
assert_equals 'unset' "$pass_failure_dir/gh-token"
assert_equals 'unset' "$pass_failure_dir/pass-token"
if grep -F 'fixture-token' "$pass_failure_dir/stdout" "$pass_failure_dir/stderr" >/dev/null; then
    echo 'token leaked during pass failure' >&2
    exit 1
fi

gh_failure_dir="$tmp_dir/gh-failure"
mkdir "$gh_failure_dir"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_DIR="$gh_failure_dir" \
    FAKE_GH_RESULT=failure FAKE_PASS_RESULT=success \
    "$target" >"$gh_failure_dir/stdout" 2>"$gh_failure_dir/stderr"; then
    echo 'expected gh authentication failure' >&2
    exit 1
fi
assert_not_exists "$gh_failure_dir/pass-token"
assert_not_exists "$gh_failure_dir/codex-token"

echo 'codex-with-gh tests passed'
