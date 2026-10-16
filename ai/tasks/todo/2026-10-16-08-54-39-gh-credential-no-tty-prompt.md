## HLD

### 2026-10-16 08:54 : no-tty Git credential の Codex 判定と pinentry

- 目的: 通常コンソールの Git credential helper では必要に応じて pinentry-curses を表示し、Codex から起動した helper では pinentry を起動しない。どちらの場合も復号失敗後の Git username/password prompt を止める。
- 変更対象候補: `bin/gh` の親プロセス判定、通常端末の GPG/pinentry 経路、`auth git-credential get` 失敗分岐、および `ai/tasks/workspace/test-gh-no-tty.sh`。
- 非変更対象: 通常の `gh` API 呼び出し、Codex 配下でない TTY あり `gh auth`、token 保存・GPG cache 挙動、Git の credential helper 登録方法。
- 入出力・判定マトリックス（先に親 process chain、次に `GH_TOKEN`）:

  | 親 process chain に Codex | `GH_TOKEN` | 動作 |
  |---|---|---|
  | あり | あり | `GH_TOKEN` で gh を実行。pass/GPG/pinentry は使わない |
  | あり | なし | TTY の有無を問わず即時エラー。pass/GPG/pinentry は試さない |
  | なし | あり | `GH_TOKEN` で gh を実行。pass/GPG/pinentry は使わない |
  | なし | なし | `pass + gpg` を試し、利用可能な端末があれば pinentry を許可 |

  Codex 判定不能時は Codex 扱いとする。表は通常の gh 呼出しと credential `get` に適用する。明示的な token 管理コマンド `gh auth update-token` は既存機能を保つが、Codex 配下で `GH_TOKEN` がなければ同じく実行前にエラーにする。credential `get` の取得失敗時は stdout に `quit=true` を返し、stderr に診断を出す。secret は出力しない。
- 運用方法: 親から祖先方向へ process chain を走査する。Codex 以外の呼出し元では、通常 TTY または継承された `GPG_TTY` を使って pinentry-curses を許可する。helper の stdin が Git protocol pipe でも、親が Codex でない場合は GPG の通常経路とする。
- 失敗時挙動: Codex 配下で `GH_TOKEN` がない場合は TTY があっても pinentry を起動しない。Codex 以外の呼出し元で GPG/pinentry が失敗またはキャンセルされた場合は `quit=true` で Git の username/password prompt へフォールバックさせず認証失敗とする。
- 既存機能への影響: 通常コンソールの Git HTTPS 認証では cache miss 時に pinentry が表示される。Codex 配下では `GH_TOKEN` がないとき pinentry を表示せず失敗する。credential 取得失敗時に Git の username/password prompt は出なくなる。
- 未確定事項: なし。
- ユーザー確認: 親プロセス優先のマトリックスと Codex 判定不能時の fail-closed をユーザー確認済み（2026-10-16）。

## Plan

### 2026-10-16 08:54 : no-tty Git credential の Codex 判定と pinentry

- [x] Git credential helper の既存回帰履歴と GPG_TTY/pinentry 条件を確認する。
- [x] `bin/gh` に Codex ancestor 判定を実装し、Codex 配下は GH_TOKEN 必須、その他は既存の対話判定を保つ。
- [x] credential helper の失敗時に `quit=true` を返し、実 Git が prompt を出さず失敗することを検証する。
- [x] Codex 配下では TTY の有無を問わず GH_TOKEN がない場合 pass を呼ばず即時失敗し、通常呼出し元では GPG option を追加せず pass が呼ばれることを検証する。
- [x] shell 構文、関連テスト、差分を確認する。
- [x] Review を記録し lessons と照合する。

## Review

### 2026-10-16 08:54 : no-tty と terminal 非対話を区別する

- ユーザー訂正: credential helper の stdin が Git protocol pipe でも、通常コンソール起動なら GPG/pinentry-curses を許可してよい。pinentry を抑止したいのは Codex の子プロセスだけである。
- 修正方針: stdin の TTY 有無だけで GPG UI 方針を決めず、親 process chain が Codex なら `GH_TOKEN` がない時点で GPG より前に失敗させる。通常コンソールでは inherited `GPG_TTY` による pinentry を許す。
- Review: `ai/tasks/todo/2026-10-16-08-54-39-gh-credential-no-tty-prompt.md#2026-10-16-0854--no-tty-と-terminal-非対話を区別する`

### 2026-10-16 09:05 : 親 Codex 優先の認証マトリックス

- ユーザー確認済み仕様: 判定順は親 process chain の Codex 判定が先、`GH_TOKEN` の有無が次。Codex 配下では `GH_TOKEN` 以外を許さず、通常端末であっても pinentry を起動しない。Codex 配下でない場合は `GH_TOKEN` がなければ pass/GPG を試し、通常の pinentry 経路を許す。
- HLD にこのマトリックスを記載し、Codex 判定不能は Codex 扱い（fail closed）とした。

### 2026-10-16 09:05 : 実装と検証

- 原因: 旧 wrapper は stdin が TTY でない呼出しを一律 batch/no-pinentry としていたため、Git credential helper 経由の通常端末でも pinentry が抑止されていた。また復号失敗時に Git credential protocol の `quit=true` を返さず、Git が username prompt へ進めた。
- 修正: 親 process chain を走査し、Codex ancestor または判定不能なら `GH_TOKEN` 必須として pass/GPG 前に失敗させる。通常呼出し元では既存 `GPG_TTY` を保持した pass/GPG 経路を使い、既存の TTY あり token 登録導線も維持する。credential `get` の失敗は stderr に診断を出しつつ `quit=true` を返す。
- 検証: `sh -n` と `git diff --check`、`test-gh-no-tty.sh`、`test-pass-bootstrap.sh`、`test-codex-with-gh.sh` が成功。`test-tmux-gh-repository-cache.sh` は bash で実行して成功。fixture による Codex/通常呼出し元/判定不能、pass 実行有無、GPG option、実 Git credential helper の prompt 抑止を確認。
- 制限: この sandbox から実際のユーザー GPG agent/pinentry を使った復号は再検証していない。Codex 判定不能時に GH_TOKEN が未設定なら fail closed する。
- Lesson 最終確認: vector 検索可能。上位 5 件のうち Git helper と GPG/pinentry の lessons を確認し、実 helper 経路の fixture 検証を実施した。Rule に沿って通常端末で pinentry を許可し、Codex/no-UI と分けた。
- 追試: 初回テストでは Codex + `GH_TOKEN` なしの TTY ありケースが不足していたため、疑似 TTY fixture を追加。`test-gh-no-tty.sh` を再実行し、TTY ありでもエラーになり pass が呼ばれないことを確認した。
