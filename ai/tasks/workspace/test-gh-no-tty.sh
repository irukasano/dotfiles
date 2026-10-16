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

assert_line() {
    expected=$1
    file=$2

    if ! grep -Fx -- "$expected" "$file" >/dev/null; then
        echo "expected line '$expected' in $file" >&2
        exit 1
    fi
}

no_tty_log="$tmp_dir/no-tty.log"
env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=other TEST_LOG="$no_tty_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success \
    "$target" --ensure-auth >"$tmp_dir/no-tty.out" 2>"$tmp_dir/no-tty.err"
assert_contains '--trust-model always' "$no_tty_log"
assert_not_contains '--batch --pinentry-mode error' "$no_tty_log"
assert_not_contains 'GH_TOKEN を設定してください' "$tmp_dir/no-tty.err"
assert_not_contains 'fake-token' "$tmp_dir/no-tty.out"
assert_not_contains 'fake-token' "$tmp_dir/no-tty.err"

no_tty_command_log="$tmp_dir/no-tty-command.log"
env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=other TEST_LOG="$no_tty_command_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success \
    "$target" --version >"$tmp_dir/no-tty-command.out" 2>"$tmp_dir/no-tty-command.err"
assert_contains '--trust-model always' "$no_tty_command_log"
assert_not_contains '--batch --pinentry-mode error' "$no_tty_command_log"
assert_contains 'gh version' "$tmp_dir/no-tty-command.out"
assert_not_contains 'fake-token' "$tmp_dir/no-tty-command.out"
assert_not_contains 'fake-token' "$tmp_dir/no-tty-command.err"

no_tty_failure_log="$tmp_dir/no-tty-failure.log"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=other TEST_LOG="$no_tty_failure_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=failure \
    "$target" --ensure-auth >"$tmp_dir/no-tty-failure.out" 2>"$tmp_dir/no-tty-failure.err"; then
    echo 'expected no-tty authentication failure when pass cannot decrypt' >&2
    exit 1
fi
assert_contains '--trust-model always' "$no_tty_failure_log"
assert_not_contains '--batch --pinentry-mode error' "$no_tty_failure_log"
assert_contains 'GPG cache が使えないか、gpg-agent に接続できない可能性があります' "$tmp_dir/no-tty-failure.err"
assert_not_contains 'fake pass failure' "$tmp_dir/no-tty-failure.err"
assert_not_contains 'fake-token' "$tmp_dir/no-tty-failure.out"
assert_not_contains 'fake-token' "$tmp_dir/no-tty-failure.err"

no_tty_credential_log="$tmp_dir/no-tty-credential.log"
printf 'protocol=https\nhost=github.com\n\n' | \
    env -u GH_TOKEN GPG_TTY='/dev/pts/inherited' PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=other \
    TEST_LOG="$no_tty_credential_log" "$target" auth git-credential get \
    >"$tmp_dir/no-tty-credential.out" 2>"$tmp_dir/no-tty-credential.err"
assert_contains 'GPG_TTY=/dev/pts/inherited' "$no_tty_credential_log"
assert_contains 'PASS_STDIN=not-a-tty' "$no_tty_credential_log"
assert_contains 'password=fake-token' "$tmp_dir/no-tty-credential.out"

token_command_log="$tmp_dir/token-command.log"
env GH_TOKEN='fixture-token' PATH="$fake_bin:$PATH" TEST_LOG="$token_command_log" \
    TEST_PROCESS_KIND=other \
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
script -q -e -c "env -u GH_TOKEN PATH='$tty_path' TEST_PROCESS_KIND=other TEST_LOG='$tty_log' PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success '$target' --ensure-auth" /dev/null >"$tmp_dir/tty.out"
assert_contains '--trust-model always' "$tty_log"

credential_failure_log="$tmp_dir/credential-failure.log"
printf 'protocol=https\nhost=github.com\n\n' | \
    env -u GH_TOKEN GPG_TTY='/dev/pts/inherited' PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=other \
    TEST_LOG="$credential_failure_log" PASS_RESULT=failure \
    "$target" auth git-credential get >"$tmp_dir/credential-failure.out" 2>"$tmp_dir/credential-failure.err"
assert_line 'quit=true' "$tmp_dir/credential-failure.out"
assert_not_contains 'fake-token' "$tmp_dir/credential-failure.out"
assert_contains 'GPG cache が使えないか、gpg-agent に接続できない可能性があります' "$tmp_dir/credential-failure.err"
assert_not_contains '未設定です。これから登録します' "$tmp_dir/credential-failure.err"
assert_contains 'GPG_TTY=/dev/pts/inherited' "$credential_failure_log"
assert_not_contains '--batch --pinentry-mode error' "$credential_failure_log"
if [ "$(grep -c '^PASS_STDIN=not-a-tty$' "$credential_failure_log")" -ne 1 ]; then
    echo 'expected failed git credential to attempt decryption once' >&2
    exit 1
fi

codex_failure_log="$tmp_dir/codex-failure.log"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=codex-grandparent \
    TEST_PS_STATE="$tmp_dir/codex-ps-state" TEST_LOG="$codex_failure_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=failure \
    "$target" --ensure-auth >"$tmp_dir/codex-failure.out" 2>"$tmp_dir/codex-failure.err"; then
    echo 'expected Codex without GH_TOKEN to fail when pass cannot decrypt' >&2
    exit 1
fi
assert_contains '--trust-model always --batch --pinentry-mode error' "$codex_failure_log"
assert_contains '昇格実行で再試行してください（require_escalated）' "$tmp_dir/codex-failure.err"
assert_not_contains 'GH_TOKEN を設定してください' "$tmp_dir/codex-failure.err"

codex_pid1_log="$tmp_dir/codex-pid1.log"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=codex-pid1 \
    TEST_PS_STATE="$tmp_dir/codex-pid1-ps-state" TEST_LOG="$codex_pid1_log" \
    PASS_RESULT=failure "$target" --ensure-auth \
    >"$tmp_dir/codex-pid1.out" 2>"$tmp_dir/codex-pid1.err"; then
    echo 'expected Codex at PID 1 to use cache-only pass and fail' >&2
    exit 1
fi
assert_contains '--batch --pinentry-mode error' "$codex_pid1_log"
assert_contains '昇格実行で再試行してください（require_escalated）' "$tmp_dir/codex-pid1.err"

codex_success_log="$tmp_dir/codex-success.log"
env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=codex TEST_LOG="$codex_success_log" \
    PASSWORD_STORE_GPG_OPTS='--trust-model always' PASS_RESULT=success \
    "$target" --ensure-auth >"$tmp_dir/codex-success.out" 2>"$tmp_dir/codex-success.err"
assert_contains '--trust-model always --batch --pinentry-mode error' "$codex_success_log"
assert_not_contains 'fake-token' "$tmp_dir/codex-success.out"
assert_not_contains 'fake-token' "$tmp_dir/codex-success.err"

codex_tty_log="$tmp_dir/codex-tty.log"
if script -q -e -c "env -u GH_TOKEN PATH='$tty_path' TEST_PROCESS_KIND=codex TEST_LOG='$codex_tty_log' PASS_RESULT=failure '$target' --ensure-auth" /dev/null \
    >"$tmp_dir/codex-tty.out" 2>"$tmp_dir/codex-tty.err"; then
    echo 'expected Codex with a TTY and no GH_TOKEN to fail cache-only pass' >&2
    exit 1
fi
assert_contains '--batch --pinentry-mode error' "$codex_tty_log"
assert_contains '昇格実行で再試行してください（require_escalated）' "$tmp_dir/codex-tty.out"

codex_credential_out="$tmp_dir/codex-credential.out"
printf 'protocol=https\nhost=github.com\n\n' | \
    env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=codex TEST_LOG="$tmp_dir/codex-credential.log" PASS_RESULT=failure \
    "$target" auth git-credential get >"$codex_credential_out" 2>"$tmp_dir/codex-credential.err"
assert_line 'quit=true' "$codex_credential_out"
assert_contains '昇格実行で再試行してください（require_escalated）' "$tmp_dir/codex-credential.err"
assert_contains '--batch --pinentry-mode error' "$tmp_dir/codex-credential.log"

codex_token_log="$tmp_dir/codex-token.log"
env GH_TOKEN='fixture-token' PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=codex TEST_LOG="$codex_token_log" \
    "$target" --version >"$tmp_dir/codex-token.out" 2>"$tmp_dir/codex-token.err"
assert_contains 'gh version' "$tmp_dir/codex-token.out"
if [ -e "$codex_token_log" ]; then
    echo 'did not expect pass to run for Codex with GH_TOKEN' >&2
    exit 1
fi

unknown_process_out="$tmp_dir/unknown-process.out"
if env -u GH_TOKEN PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=unavailable \
    PASS_RESULT=failure TEST_LOG="$tmp_dir/unknown-process.log" \
    "$target" --ensure-auth >"$unknown_process_out" 2>"$tmp_dir/unknown-process.err"; then
    echo 'expected ancestry lookup failure to fail closed through cache-only pass' >&2
    exit 1
fi
assert_contains '--batch --pinentry-mode error' "$tmp_dir/unknown-process.log"
assert_contains '昇格実行で再試行してください（require_escalated）' "$tmp_dir/unknown-process.err"

git_helper_out="$tmp_dir/git-helper.out"
if printf 'protocol=https\nhost=github.com\n\n' | \
    env -u GH_TOKEN GIT_TERMINAL_PROMPT=0 PATH="$fake_bin:$PATH" TEST_PROCESS_KIND=other \
    TEST_LOG="$tmp_dir/git-helper.log" PASS_RESULT=failure \
    git -c "credential.helper=!$target auth git-credential" credential fill \
    >"$git_helper_out" 2>"$tmp_dir/git-helper.err"; then
    echo 'expected git credential fill to fail without prompting' >&2
    exit 1
fi
assert_not_contains 'Username for' "$git_helper_out"
assert_not_contains 'Username for' "$tmp_dir/git-helper.err"
assert_not_contains 'Password for' "$git_helper_out"
assert_not_contains 'Password for' "$tmp_dir/git-helper.err"
assert_not_contains 'terminal prompts disabled' "$tmp_dir/git-helper.err"
assert_not_contains 'could not read Username' "$tmp_dir/git-helper.err"

echo 'gh no-tty authentication tests passed'
