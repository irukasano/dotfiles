#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
target="$project_root/bin/gh"
fake_bin="$project_root/ai/tasks/workspace/gh-no-tty-test-bin"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

assert_contains() {
    needle=$1
    file=$2

    if ! grep -F -- "$needle" "$file" >/dev/null; then
        echo "expected '$needle' in $file" >&2
        exit 1
    fi
}

assert_not_contains() {
    needle=$1
    file=$2

    if grep -F -- "$needle" "$file" >/dev/null; then
        echo "did not expect '$needle' in $file" >&2
        exit 1
    fi
}

no_tty_log="$tmp_dir/no-tty.log"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_LOG="$no_tty_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success \
    "$target" --ensure-auth >"$tmp_dir/no-tty.out" 2>"$tmp_dir/no-tty.err"; then
    echo 'expected no-tty authentication failure without GH_TOKEN' >&2
    exit 1
fi
if [ -e "$no_tty_log" ]; then
    echo 'did not expect pass to run without GH_TOKEN in no-tty mode' >&2
    exit 1
fi
assert_contains 'GH_TOKEN を設定してください' "$tmp_dir/no-tty.err"
assert_not_contains 'fake-token' "$tmp_dir/no-tty.out"
assert_not_contains 'fake-token' "$tmp_dir/no-tty.err"

token_command_log="$tmp_dir/token-command.log"
env GH_TOKEN='fixture-token' PATH="$fake_bin:$PATH" TEST_LOG="$token_command_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=failure \
    "$target" --version >"$tmp_dir/command.out" 2>"$tmp_dir/command.err"
if [ -e "$token_command_log" ]; then
    echo 'did not expect pass to run when GH_TOKEN is set' >&2
    exit 1
fi
assert_contains 'gh version' "$tmp_dir/command.out"
assert_not_contains 'fake-token' "$tmp_dir/command.out"
assert_not_contains 'fake-token' "$tmp_dir/command.err"

tty_log="$tmp_dir/tty.log"
tty_path="$fake_bin:$PATH"
script -q -e -c "env -u GH_TOKEN PATH='$tty_path' TEST_LOG='$tty_log' PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success '$target' --ensure-auth" /dev/null >"$tmp_dir/tty.out"
assert_contains '--trust-model always' "$tty_log"

echo 'gh no-tty authentication tests passed'
