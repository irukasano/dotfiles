#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
source="$project_root/bin/pass-sync"
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

make_fixture() {
    fixture_dir=$1
    mkdir -p "$fixture_dir/bin" "$fixture_dir/password-store/.git"

    cat >"$fixture_dir/bin/native-gh" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$TEST_DIR/native-gh.log"

if [ "$1" = auth ] && [ "$2" = login ]; then
    : >"$TEST_DIR/native-authenticated"
    exit 0
fi
if [ "$1" = auth ] && [ "$2" = token ]; then
    if [ -e "$TEST_DIR/native-authenticated" ]; then
        printf '%s\n' fixture-token
        exit 0
    fi
    exit 1
fi
if [ "$1" = api ] && [ "$2" = user ]; then
    printf '%s\n' fixture-user
    exit 0
fi
if [ "$1" = auth ] && [ "$2" = logout ]; then
    rm -f "$TEST_DIR/native-authenticated"
    exit 0
fi
exit 1
EOF

    cat >"$fixture_dir/bin/pass" <<'EOF'
#!/bin/sh
set -eu
test "$*" = 'git pull'
test "${GH_TOKEN:-}" = fixture-token
printf '%s\n' 'pull-with-token' >>"$TEST_DIR/pass.log"
if [ "${PULL_MODE:-success}" = fail ]; then
    exit 1
fi
EOF

    sed "s|/usr/bin/gh|$fixture_dir/bin/native-gh|g" "$source" >"$fixture_dir/pass-sync"
    chmod +x "$fixture_dir/bin/native-gh" "$fixture_dir/bin/pass" "$fixture_dir/pass-sync"
}

run_success() {
    test_dir="$tmp_dir/success"
    mkdir "$test_dir"
    make_fixture "$test_dir"

    if ! env -u GH_TOKEN PATH="$test_dir/bin:$PATH" TEST_DIR="$test_dir" HOME="$test_dir/home" \
        PASSWORD_STORE_DIR="$test_dir/password-store" "$test_dir/pass-sync" \
        >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        cat "$test_dir/stderr" >&2
        exit 1
    fi

    test ! -e "$test_dir/native-authenticated"
    assert_contains 'auth login --hostname github.com --web --git-protocol https --skip-ssh-key' "$test_dir/native-gh.log"
    assert_contains 'api user --hostname github.com --jq .login' "$test_dir/native-gh.log"
    assert_contains 'auth logout --hostname github.com --user fixture-user' "$test_dir/native-gh.log"
    assert_contains 'pull-with-token' "$test_dir/pass.log"
    assert_not_contains fixture-token "$test_dir/stdout"
    assert_not_contains fixture-token "$test_dir/stderr"
}

run_pull_failure_keeps_native_auth() {
    test_dir="$tmp_dir/pull-failure"
    mkdir "$test_dir"
    make_fixture "$test_dir"

    if env -u GH_TOKEN PATH="$test_dir/bin:$PATH" TEST_DIR="$test_dir" HOME="$test_dir/home" \
        PASSWORD_STORE_DIR="$test_dir/password-store" PULL_MODE=fail "$test_dir/pass-sync" \
        >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        echo 'expected sync to fail when pass git pull fails' >&2
        exit 1
    fi

    test -e "$test_dir/native-authenticated"
    if grep -F 'auth logout' "$test_dir/native-gh.log" >/dev/null; then
        echo 'did not expect native gh logout after pull failure' >&2
        exit 1
    fi
    assert_not_contains fixture-token "$test_dir/stdout"
    assert_not_contains fixture-token "$test_dir/stderr"
}

run_preconditions() {
    test_dir="$tmp_dir/preconditions"
    mkdir "$test_dir"
    make_fixture "$test_dir"

    if env GH_TOKEN=caller-token PATH="$test_dir/bin:$PATH" TEST_DIR="$test_dir" HOME="$test_dir/home" \
        PASSWORD_STORE_DIR="$test_dir/password-store" "$test_dir/pass-sync" \
        >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        echo 'expected sync to reject inherited GH_TOKEN' >&2
        exit 1
    fi
    assert_contains 'GH_TOKEN が設定されています' "$test_dir/stderr"
    assert_not_contains caller-token "$test_dir/stdout"
    assert_not_contains caller-token "$test_dir/stderr"
    test ! -e "$test_dir/native-authenticated"
}

run_existing_native_auth() {
    test_dir="$tmp_dir/existing-native-auth"
    mkdir "$test_dir"
    make_fixture "$test_dir"
    : >"$test_dir/native-authenticated"

    if env -u GH_TOKEN PATH="$test_dir/bin:$PATH" TEST_DIR="$test_dir" HOME="$test_dir/home" \
        PASSWORD_STORE_DIR="$test_dir/password-store" "$test_dir/pass-sync" \
        >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        echo 'expected sync to reject existing native gh authentication' >&2
        exit 1
    fi
    assert_contains '既存認証' "$test_dir/stderr"
    if grep -F 'auth login' "$test_dir/native-gh.log" >/dev/null; then
        echo 'did not expect native gh login with existing authentication' >&2
        exit 1
    fi
    test ! -e "$test_dir/pass.log"
}

run_success
run_pull_failure_keeps_native_auth
run_preconditions
run_existing_native_auth
echo 'pass-sync tests passed'
