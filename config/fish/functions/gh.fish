function gh --description "gh wrapper using pass-stored GITHUB_TOKEN"
    if not command -q pass
        echo "gh: pass コマンドが必要です。インストールしてください" >&2
        return 127
    end

    set -l token_name github/cli-token

    if not pass show $token_name >/dev/null 2>/dev/null
        if status is-interactive
            echo "gh: $token_name が未設定です。これから pass insert します" >&2
            pass insert $token_name
            or begin
                echo "gh: トークン登録に失敗しました" >&2
                return 1
            end
        else
            echo "gh: $token_name が未設定です。先に 'pass insert $token_name' を実行してください" >&2
            return 1
        end
    end

    set -l token (pass show $token_name | head -n 1)
    if test -z "$token"
        echo "gh: $token_name からトークンを取得できませんでした" >&2
        return 1
    end

    set -lx GITHUB_TOKEN $token
    command gh $argv
end

