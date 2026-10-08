#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
source="$project_root/bin/pass-bootstrap"
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
    mkdir -p "$fixture_dir/bin"

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

    cat >"$fixture_dir/bin/git" <<'EOF'
#!/bin/sh
set -eu

if [ "$1" != clone ]; then
    exit 1
fi

destination=''
for argument in "$@"; do
    destination=$argument
done

mkdir "$destination"
printf '%s\n' fixture-recipient >"$destination/.gpg-id"
EOF

    cat >"$fixture_dir/bin/gpg" <<'EOF'
#!/bin/sh
set -eu

printf '%s\n' "$*" >>"$TEST_DIR/gpg.log"
if [ "${GPG_MODE:-success}" = missing ]; then
    exit 2
fi
EOF

    cat >"$fixture_dir/bin/pass" <<'EOF'
#!/bin/sh
exit 0
EOF

    cat >"$fixture_dir/gh" <<'EOF'
#!/bin/sh
set -eu

if [ "$1" = auth ] && [ "$2" = update-token ]; then
    test -z "${GH_TOKEN:-}"
    IFS= read -r token
    printf '%s\n' "$token" >"$PASSWORD_STORE_DIR/github-cli-token"
    printf '%s\n' 'update-token' >>"$TEST_DIR/wrapper.log"
    exit 0
fi

if [ "$1" = --ensure-auth ]; then
    test -s "$PASSWORD_STORE_DIR/github-cli-token"
    test -z "${GH_TOKEN:-}"
    printf '%s\n' 'ensure-auth' >>"$TEST_DIR/wrapper.log"
    exit 0
fi

exit 1
EOF

    sed "s|/usr/bin/gh|$fixture_dir/bin/native-gh|g" "$source" >"$fixture_dir/pass-bootstrap"
    chmod +x "$fixture_dir/bin/native-gh" "$fixture_dir/bin/git" \
        "$fixture_dir/bin/gpg" "$fixture_dir/bin/pass" "$fixture_dir/gh" \
        "$fixture_dir/pass-bootstrap"
}

run_success() {
    test_dir="$tmp_dir/success"
    mkdir "$test_dir"
    make_fixture "$test_dir"

    if ! env -u GH_TOKEN PATH="$test_dir/bin:$PATH" TEST_DIR="$test_dir" HOME="$test_dir/home" \
        PASSWORD_STORE_DIR="$test_dir/password-store" "$test_dir/pass-bootstrap" \
        >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        cat "$test_dir/stderr" >&2
        exit 1
    fi

    test -d "$test_dir/password-store"
    test -s "$test_dir/password-store/github-cli-token"
    test ! -e "$test_dir/native-authenticated"
    assert_contains 'auth login --hostname github.com --web --git-protocol https --skip-ssh-key' "$test_dir/native-gh.log"
    assert_contains 'auth logout --hostname github.com --user fixture-user' "$test_dir/native-gh.log"
    assert_contains 'update-token' "$test_dir/wrapper.log"
    assert_contains 'ensure-auth' "$test_dir/wrapper.log"
    assert_contains '--list-keys fixture-recipient' "$test_dir/gpg.log"
    assert_contains '--list-secret-keys fixture-recipient' "$test_dir/gpg.log"
    assert_not_contains 'fixture-token' "$test_dir/stdout"
    assert_not_contains 'fixture-token' "$test_dir/stderr"
    if find "$test_dir" -maxdepth 1 -name '.pass-bootstrap.*' | grep -q .; then
        echo 'expected temporary password-store clone to be removed' >&2
        exit 1
    fi
}

run_existing_native_auth() {
    test_dir="$tmp_dir/existing-native-auth"
    mkdir "$test_dir"
    make_fixture "$test_dir"
    : >"$test_dir/native-authenticated"

    if env -u GH_TOKEN PATH="$test_dir/bin:$PATH" TEST_DIR="$test_dir" HOME="$test_dir/home" \
        PASSWORD_STORE_DIR="$test_dir/password-store" "$test_dir/pass-bootstrap" \
        >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        echo 'expected bootstrap to reject existing native gh authentication' >&2
        exit 1
    fi

    test ! -e "$test_dir/password-store"
    assert_contains '既存認証' "$test_dir/stderr"
    if grep -F 'auth login' "$test_dir/native-gh.log" >/dev/null; then
        echo 'did not expect native gh login with existing authentication' >&2
        exit 1
    fi
}

run_missing_gpg_key() {
    test_dir="$tmp_dir/missing-gpg-key"
    mkdir "$test_dir"
    make_fixture "$test_dir"

    if env -u GH_TOKEN PATH="$test_dir/bin:$PATH" TEST_DIR="$test_dir" HOME="$test_dir/home" \
        PASSWORD_STORE_DIR="$test_dir/password-store" GPG_MODE=missing \
        "$test_dir/pass-bootstrap" >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        echo 'expected bootstrap to fail without the GPG key' >&2
        exit 1
    fi

    test ! -e "$test_dir/password-store"
    test -e "$test_dir/native-authenticated"
    assert_contains '公開鍵が import されていません' "$test_dir/stderr"
    assert_not_contains 'fixture-token' "$test_dir/stdout"
    assert_not_contains 'fixture-token' "$test_dir/stderr"
    if grep -F 'auth logout' "$test_dir/native-gh.log" >/dev/null; then
        echo 'did not expect native gh logout after GPG key failure' >&2
        exit 1
    fi
}

run_success
run_existing_native_auth
run_missing_gpg_key

echo 'pass-bootstrap tests passed'
