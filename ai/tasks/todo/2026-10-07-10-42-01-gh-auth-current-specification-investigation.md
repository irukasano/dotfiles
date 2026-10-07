## HLD

### 2026-10-07 10:42 : gh 認証の現行仕様調査
- 目的: 過去の gh / Codex 認証調整の内容と、現行の対話・非対話における `pass + gpg` 復号条件を説明する。
- 変更対象: 調査・記録のみ。
- 非変更対象: `bin/gh`、`bin/codex-with-gh`、GPG、`pass`、GitHub token、および Codex 設定。
- 入出力: 実装・Git 履歴・既存タスク記録を入力に、認証フローと制約の説明を出力する。
- 運用方法: 現行スクリプトの静的確認と履歴確認に限定する。
- 失敗時挙動: 実行時環境が必要な点は、静的確認による結論と区別して記載する。
- 既存機能への影響: なし。
- 未確定事項: 現在の gpg-agent キャッシュ状態および実行時の復号可否。
- ユーザー確認が必要な項目: 修正を希望する場合のみ、Codex 起動時に復号を許可するか、別の token 供給経路にするか。

### 2026-10-07 10:42 : no-tty Codex の gh 認証対策検討
- 目的: Codex の no-tty 実行で、共有 gpg-agent のキャッシュが有効なら `pass` から GitHub token を復号して `gh` を使い、キャッシュ切れなら pinentry-curses を起動せず安全に失敗させる。
- 変更対象: `bin/gh` の token 読出し経路と no-tty 時のエラー文言、検証用スクリプト。
- 非変更対象: `bin/codex-with-gh`、Codex sandbox 権限、GPG agent、token 保存先、`GH_TOKEN` の Codex への継承。
- 入出力: 入力は TTY の有無、gpg-agent キャッシュ、`pass show github/cli-token`。出力はキャッシュ有効時の `/usr/bin/gh` 実行、またはキャッシュ切れ時の非対話・非表示エラー。
- 運用方法: キャッシュ切れ時は別の対話端末で `pass show github/cli-token >/dev/null` を実行して GPG 認証を完了してから、Codex の gh 操作を再実行する。
- 失敗時挙動: no-tty 時の `pass show` に `--batch --pinentry-mode error` を強制して pinentry を起動しない。失敗時は token を出力せず、対話端末での復号手順を stderr に表示して非 0 終了する。
- 既存機能への影響: 対話端末では従来どおり pinentry を利用可能。no-tty 時だけ、キャッシュ切れの GPG 認証を即時失敗へ変更する。
- 未確定事項: なし。`pass` 1.7.4 が `PASSWORD_STORE_GPG_OPTS` を GPG 起動オプションとして受け入れること、GnuPG 2.4.8 が `--pinentry-mode error` を提供することを確認済み。
- ユーザー確認: 2026-10-07 に、`--batch --pinentry-mode error` を用いて Codex/no-tty 内の pinentry 起動を抑止し、gpg-agent キャッシュだけを利用する方針を合意。

## Plan

### 2026-10-07 10:42 : gh 認証の現行仕様調査
- [x] 関連スクリプト、Git 履歴、既存の認証調査記録を確認する。
- [x] 対話・非対話・`--ensure-auth`・Codex 起動時の分岐を静的に確認する。
- [x] 確認結果と制約を Review に記録し、ユーザーへ報告する。

### 2026-10-07 10:42 : no-tty Codex の gh 認証対策検討
- [x] GPG agent キャッシュ、Codex sandbox、token 継承の制約を整理する。
- [x] token を Codex に渡さず、共有 gpg-agent キャッシュだけを使う方針の合意を得る。
- [x] `pass` の GPG option 注入と GnuPG の `--pinentry-mode error` 対応を確認する。
- [x] no-tty の `pass show` にだけ `--batch --pinentry-mode error` を付与する helper を実装する。
- [x] no-tty の失敗時メッセージを、別端末での無表示復号手順に更新する。
- [x] fake `pass` とネットワーク不要の `/usr/bin/gh --version` で、no-tty の option 付与、token 非出力、成功実行、失敗時の pinentry 非起動指定、TTY 時の既存挙動維持を検証する。
- [x] `sh -n`、`git diff --check`、基準ブランチ `master` との差分を確認し、Review に結果を記録する。

#### 2026-10-07 10:42 : TTY 判定の再計画
- 変更理由: token の存在確認は stdout/stderr を `/dev/null` にリダイレクトしているため、`show_token()` の内部で TTY を判定すると、元の起動が対話端末でも no-tty と誤判定する。これは対話時の pinentry 利用を維持する HLD に反する。
- 変更内容: `bin/gh` 起動直後に stdin/stderr の TTY 有無を一度だけ記録し、`show_token()` はその記録値で通常 GPG と no-prompt GPG を分岐する。fixture の疑似 TTY 実行では実システムの `PATH` を保持する。
- 変更なし: no-tty 時の `--batch --pinentry-mode error` 強制、token 非出力、Codex への `GH_TOKEN` 非継承。

## Review

### 2026-10-07 10:42 : gh 認証の現行仕様調査
- 該当履歴: 2026-04-07 の `62806b1`（`Codex用のGH認証とGPG設定を整備`）で、`pinentry-curses` と `GPG_TTY` を整備し、非対話時は `pass insert` を起動せず、事前の `gh --ensure-auth` を促す仕様になった。2026-04-09 の `8c356c5` は token 更新用の `gh auth update-token` を追加した変更である。
- 現行 `bin/gh`: `GH_TOKEN` が設定済みなら `pass` / GPG を実行しない。未設定なら、対話・非対話を問わず最初に `pass show github/cli-token >/dev/null` を実行する。失敗時だけ、非対話では token 登録をせずエラー終了する。成功時は token 取得のため `pass show` をもう一度実行し、子プロセスの `GH_TOKEN` として `/usr/bin/gh` に渡す。
- 現行 `bin/codex-with-gh`: 常に `gh --ensure-auth >/dev/null` を実行してから `codex` を起動する。この呼び出しでも上記の `pass show` / GPG 復号は行うが、`--ensure-auth` は token を export する前に終了するため、Codex には `GH_TOKEN` を引き渡さない。
- 結論: ユーザーの認識どおり、`GH_TOKEN` が外部から渡されない限り Codex 内で `gh` を使うたびに `pass + gpg` が必要となる。既存の 2026-08-31 調査では、Codex sandbox 内の `pass show` は `~/.gnupg` へ lock file を作れず、`can't connect to the gpg-agent: Read-only file system` で失敗することを実測済みである。従って、現在の launcher は「起動前に認証を促す」だけで、Codex 内での gh 利用を成立させる token 引継ぎにはなっていない。
- 検証: `sh -n bin/gh`、`sh -n bin/codex-with-gh`、`git diff --check` は成功。実 token を扱う実行テストは行わなかった。
- lesson 最終確認: `codex-lesson --ai-base ai check` は vector 検索不可（`sqlite_vec` 未導入）だったため、`ai/tasks/lessons.md` を全件確認した。認証・token・シークレット関連の Rule と矛盾する報告はない。

### 2026-10-07 10:42 : no-tty での pinentry 起動リスク訂正
- 原因: GPG agent キャッシュの有効性を `pass show` の成否で判定すればよいと説明したが、キャッシュ切れ時には `pass show` が pinentry-curses の起動を試みる。Codex の no-tty 実行において UI 出力が表示崩れを起こす可能性を考慮していなかった。
- 訂正: Codex 内では、キャッシュ切れ時に pinentry を起動しないことを明示的に保証する必要がある。単なる `pass show` の試行をキャッシュ判定としては採用しない。

### 2026-10-07 10:42 : no-tty Codex の gh 認証対策
- 原因: `bin/gh` は non-interactive な `pass show` でも通常の GPG 起動を使うため、gpg-agent のキャッシュ切れ時に pinentry-curses を起動し得た。一方で `GH_TOKEN` を Codex へ継承する方式は token を Codex の子プロセスへ公開するため採用しない。
- 修正内容: 起動時に TTY 有無を記録し、no-tty 起動時の token 読出しに限って `PASSWORD_STORE_GPG_OPTS` へ `--batch --pinentry-mode error` を追加した。キャッシュ済みの GPG agent は通常どおり復号でき、キャッシュ切れ時は pinentry を起動せず失敗する。対話端末からの起動は従来どおりの GPG option と pinentry を使う。失敗時メッセージは、別の対話端末で `pass show github/cli-token >/dev/null` を実行する手順へ更新した。
- TTY 判定の注意: token 存在確認は stdout/stderr を `/dev/null` にリダイレクトするため、helper 内ではなくスクリプト起動時に TTY 状態を記録する。これにより、対話端末の事前確認を誤って no-tty 扱いしない。
- 検証: `bash -n bin/gh`、`sh -n ai/tasks/workspace/gh-no-tty-test-bin/pass`、`sh -n ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-gh-no-tty.sh`、`git diff --check`、`git diff master --check` が成功した。fixture は `GH_TOKEN` をコマンドごとに unset し、fake `pass` により no-tty の option 付与・token 非出力・失敗時の内部エラー非表示、および疑似 TTY での option 非付与を確認した。通常の `gh` 経路も、ネットワーク不要の `/usr/bin/gh --version` で token を 2 回読出すことを確認した。実 token・実 `pass show` は実行していない。
- 実機 no-tty 確認: `bin/gh --ensure-auth` は exit 1 となり、token を stdout に出さず、pinentry-curses を表示せず、別の対話端末で `pass show github/cli-token >/dev/null` を実行する案内だけを stderr に出した。これはキャッシュ未利用時の想定された失敗挙動である。対話端末で GPG 認証後に同じ Codex session から成功する確認は、実 token を持つ対話端末での操作が必要なため未実施。
- lesson 最終確認: `codex-lesson --ai-base ai check` は vector 検索不可（`sqlite_vec` 未導入）だったため、`ai/tasks/lessons.md` の GPG・認証・秘密出力関連 Rule を照合した。今回の実装・検証は適用対象の Rule に従っている。
