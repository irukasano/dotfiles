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
env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_LOG="$no_tty_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success \
    "$target" --ensure-auth >"$tmp_dir/no-tty.out" 2>"$tmp_dir/no-tty.err"
assert_contains '--trust-model always --batch --pinentry-mode error' "$no_tty_log"
assert_not_contains 'fake-token' "$tmp_dir/no-tty.out"
assert_not_contains 'fake-token' "$tmp_dir/no-tty.err"

command_log="$tmp_dir/command.log"
env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_LOG="$command_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success \
    "$target" --version >"$tmp_dir/command.out" 2>"$tmp_dir/command.err"
assert_contains '--trust-model always --batch --pinentry-mode error' "$command_log"
if [ "$(wc -l < "$command_log")" -ne 2 ]; then
    echo 'expected two token reads for a normal gh command' >&2
    exit 1
fi
assert_contains 'gh version' "$tmp_dir/command.out"
assert_not_contains 'fake-token' "$tmp_dir/command.out"
assert_not_contains 'fake-token' "$tmp_dir/command.err"

failure_log="$tmp_dir/failure.log"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_LOG="$failure_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=failure \
    "$target" --ensure-auth >"$tmp_dir/failure.out" 2>"$tmp_dir/failure.err"; then
    echo 'expected no-tty authentication failure' >&2
    exit 1
fi
assert_contains '--trust-model always --batch --pinentry-mode error' "$failure_log"
assert_contains "pass show github/cli-token >/dev/null" "$tmp_dir/failure.err"
assert_not_contains 'fake pass failure' "$tmp_dir/failure.err"
assert_not_contains 'fake-token' "$tmp_dir/failure.out"

tty_log="$tmp_dir/tty.log"
tty_path="$fake_bin:$PATH"
script -q -e -c "env -u GH_TOKEN PATH='$tty_path' TEST_LOG='$tty_log' PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success '$target' --ensure-auth" /dev/null >"$tmp_dir/tty.out"
assert_contains '--trust-model always' "$tty_log"
assert_not_contains '--pinentry-mode error' "$tty_log"

echo 'gh no-tty authentication tests passed'
