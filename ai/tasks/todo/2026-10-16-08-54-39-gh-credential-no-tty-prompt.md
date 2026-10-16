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

### 2026-10-16 09:36 : Codex の GPG 復号失敗後に昇格再実行を案内する

- 背景: `require_escalated` で `echo test | gpg --clearsign | gpg --decrypt` と、一時 script 内の `pass show 'github/cli-token' > /dev/null` が成功した。通常 sandbox 内の `.gnupg` 書込み拒否は、昇格実行でも復号不能という意味ではない。
- 目的案: Codex 内の `gh` でも `GH_TOKEN` を必須にせず、通常 sandbox で GPG 復号が失敗した場合に、Codex が元のコマンドを昇格実行で再試行できる案内を出す。
- 変更対象: `bin/gh` の「Codex ancestor かつ `GH_TOKEN` なし」の分岐だけを変更し、cache-only の GPG 復号を試して失敗時に昇格再実行の案内を出す。`bin/codex-with-gh` と `config/tmux/bin/codex-pane.sh` は変更しない。
- 非変更対象: 非 Codex 呼出し元、Codex ancestor かつ `GH_TOKEN` ありの経路、token store の形式、`gh auth update-token`、Codex 起動時の既存 `GH_TOKEN` 注入。
- 後続候補: 第1段階で Codex + no-token 経路の昇格再試行が実際に成立した後、別途 HLD 合意を得て `codex-with-gh` の起動前復号と `GH_TOKEN` 注入を廃止するか判断する。
- 入出力・マトリックス案:

  | 親 process chain に Codex | `GH_TOKEN` | 動作案 |
  |---|---|---|
  | あり | あり | `GH_TOKEN` を使う |
  | あり | なし | cache-only pass/GPG を試す。失敗時は元コマンドを昇格実行で再試行するよう診断する。昇格実行で復号できれば gh を実行する |
  | なし | あり | `GH_TOKEN` を使う |
  | なし | なし | 現行どおり pass/GPG を試し、pinentry を許可する |

- 失敗時挙動案: credential helper の復号失敗は `quit=true` を維持して Git の username/password prompt を止め、stderr に昇格再実行の案内を出す。昇格実行でも失敗した場合は通常の認証エラーとする。GH_TOKEN と復号した token は stdout/stderr/argv に出さない。
- 既存機能への影響: 既存 launcher と GH_TOKEN 注入を維持する。`GH_TOKEN` がない状態で直接呼ばれた Codex 配下の gh/Git 認証だけ、通常 sandbox 失敗後に昇格再試行の段階が増える。
- 未確定事項: 昇格実行を求める診断の具体文言と、Codex が元のコマンド全体を再試行する運用にすること。
- ユーザー確認: 「Codex ancestor かつ `GH_TOKEN` なし」のみを変更し、通常実行失敗後に元コマンドの昇格再実行を促すことを確認済み（2026-10-16）。launcher の token 注入廃止は後続の別判断とする。

## Plan

### 2026-10-16 09:36 : Codex の GPG 復号失敗後に昇格再実行を案内する

- [x] Codex かつ `GH_TOKEN` なしの場合だけ cache-only GPG を試し、失敗時は昇格再実行を案内する。
- [x] credential helper では `quit=true` を維持し、Git の username/password prompt を防ぐ。
- [x] fixture で Codex/no-token 成功・失敗、pinentry 抑止、昇格再実行の診断、他の三つのマトリックス条件が不変であることを検証する。
- [x] 実際の `require_escalated` 経路で `bin/gh --ensure-auth` が token を表示せず成功することを確認する。
- [x] 関連テスト、構文、差分、lesson を確認して Review に記録する。

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

### 2026-10-16 09:30 : 権限昇格判断のセッション間再発防止

- ユーザー指摘: Git 操作では sandbox 制限を理由に昇格実行を依頼した一方、GPG では同じ `.gnupg` 書込み制限に対して依頼しなかった。この違いを環境設定の違いのように説明してしまった。
- 原因: 明示された commit/push の実行には昇格が必要と判断したが、GPG の昇格は秘密情報に触れることと既存 HLD の no-GPG 方針を理由に、自分で試さない判断をした。GPG を昇格で試すかどうかは自動レビューが決めたのではなく、私が要求を出さなかった。
- 再利用ルール: sandbox 外のファイルや agent socket が必要なタスクでは、技術的に不可能と断定する前に、ユーザーの依頼がその操作と秘密情報の利用まで認可しているかを確認する。認可されている操作なら `require_escalated` を要求し、審査結果を確認する。認可範囲に秘密情報の実復号・利用が含まれるか不明なら、通常 sandbox の失敗と昇格要求未実施を区別して説明する。
- 追加確認: `pass show 'github/cli-token' > /dev/null` だけを行う一時 `dummy.sh` を `require_escalated` 付きで実行し、スクリプト内からの復号が exit 0 で成功することを確認した。出力先を `/dev/null` にしてトークンを表示せず、一時 script は削除した。これは昇格実行された script の子プロセスとして pass が動くことを確認し、通常 sandbox の `bin/gh` が自動的に昇格することは示さない。

### 2026-10-16 09:36 : Codex の GPG 復号失敗後に昇格再実行を案内する

- 原因: Codex ancestor かつ `GH_TOKEN` なしの場合、以前は GPG 復号を試さず即時失敗していた。ユーザー確認済みの elevated `pass show` が成功したため、cache-only 復号を先に試す方針へ変更した。
- 修正: `bin/gh` は Codex 配下の通常認証で `PASSWORD_STORE_GPG_OPTS` に `--batch --pinentry-mode error` を追加する。sandbox 内で `pass show` が失敗したら、`GH_TOKEN` の案内ではなく、元の gh/Git コマンドを `require_escalated` で再試行するよう stderr に案内する。credential helper の `quit=true` と GH_TOKEN ありの経路、非 Codex 経路、`gh auth update-token` は維持した。launcher の既存 GH_TOKEN 注入も未変更。
- 検証: `test-gh-no-tty.sh` で Codex/no-token の成功、失敗、TTY あり失敗、credential helper の quit、pinentry 抑止、親判定不能 fail-closed を確認。Codex+GH_TOKEN と非 Codex の各経路も同スクリプトで確認。`test-pass-bootstrap.sh`、`test-codex-with-gh.sh`、`test-tmux-gh-repository-cache.sh`、`sh -n`、`git diff --check` は成功。
- 実復号: `env -u GH_TOKEN bin/gh --ensure-auth >/dev/null` を `require_escalated` 付きで実行し exit 0。標準出力を破棄してトークンは表示しなかった。
- 運用上の制約: 通常 sandbox 内で復号に失敗した gh 自身は自動で昇格しない。表示された案内に従い、呼び出し元のコマンド全体を昇格実行で再試行する。cache の失効などで初回成功直後に昇格再試行が失敗する可能性は残る。
- Lesson 最終確認: `codex-lesson check` は vector/index とも利用可能。上位 5 件を確認し、Codex sandbox 内の復号を前提にしない既存 lesson の Review も確認した。今回の分岐は cache-only を試すだけで成功を前提にせず、失敗した認証コマンド全体を昇格実行で再試行する案内を出す。launcher の token 注入廃止は未実施で、別途合意が必要なままとした。

### 2026-10-16 09:46 : PID 1 の Codex 判定漏れ

- ユーザー報告: Codex から `gh issue list` を実行すると、Codex 専用の昇格再試行案内ではなく、旧来の非対話向け「GPG cache が使えないか…」エラーになった。
- 原因: process ancestry loop が `pid > 1` の間しか走査せず、Codex が PID 1 のプロセス名前空間では Codex 自身を検査していなかった。結果として非 Codex 扱いになっていた。
- 修正: PID 1 も走査対象に含め、Codex が PID 1 の fixture を追加した。通常環境の PID 1 は `init` として扱う fixture にし、既存の非 Codex matrix tests も維持した。
- 検証: PID 1 を Codex とする fixture を含め `test-gh-no-tty.sh` 成功。`test-pass-bootstrap.sh`、`test-codex-with-gh.sh`、`test-tmux-gh-repository-cache.sh`、構文・差分チェックも成功。通常実行の `env -u GH_TOKEN bin/gh --ensure-auth` で Codex 固有の昇格再試行案内が表示され exit 1、昇格実行では同じコマンドが token を表示せず exit 0 になることを確認した。
- lesson: プロセス名前空間内の祖先判定では PID 1 を終端として飛ばさず、名前空間の init 自身も判定対象にする。Review: `ai/tasks/todo/2026-10-16-08-54-39-gh-credential-no-tty-prompt.md#2026-10-16-0946--pid-1-の-codex-判定漏れ`
