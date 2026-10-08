## HLD

### 2026-10-08 14:07 : gh の pass 登録時に公開鍵が見つからない原因調査

- 目的: 別環境で `gh --ensure-auth` が `pass insert` 時に `公開鍵がありません` で失敗する理由を説明する。
- 変更対象: なし（読み取り専用の設定・実装調査）。
- 非変更対象: `bin/gh`、GPG 鍵、password-store、認証トークン。
- 入出力: ユーザー提示の GPG エラーと `bin/gh` の認証フローを入力に、切り分け手順を出力する。
- 運用方法: 対象環境で password-store の `.gpg-id`、実行時の `GNUPGHOME`、公開鍵一覧を照合する。
- 失敗時挙動: トークンを表示せず、鍵 ID・フィンガープリントだけを確認する。
- 既存機能への影響: なし。
- 未確定事項: 対象環境の `.gpg-id` の鍵 ID と、インポート済み鍵のフィンガープリントの一致。
- ユーザー確認が必要な項目: 修正を行う場合の password-store 再初期化または `.gpg-id` 変更の可否。

### 2026-10-08 14:10 : password-store 初期 clone の認証循環調査

- 目的: `pass git clone` が未初期化の `pass` と `gh` credential helper の循環に陥る理由と、初期構成の認証経路を説明する。
- 変更対象: なし（手順の説明のみ）。
- 非変更対象: Git credential helper、GitHub token、password-store の内容、GPG 鍵。
- 入出力: HTTPS clone 時の `gh` wrapper エラーと GitHub 認証失敗を入力に、安全な clone 手順を出力する。
- 運用方法: SSH 鍵を GitHub に登録済みの環境では SSH URL で clone する。HTTPS を使う場合だけ、GitHub password ではなく権限を絞った PAT を一時的に使う。
- 失敗時挙動: SSH 認証が未設定なら clone を止め、鍵登録状態を確認する。token を出力・保存しない。
- 既存機能への影響: なし。
- 未確定事項: 新環境の SSH 公開鍵が GitHub アカウントに登録済みか。
- ユーザー確認が必要な項目: 恒久的な HTTPS 運用へ変更するか、bootstrap の SSH 利用を標準手順にするか。

### 2026-10-08 14:17 : password-store bootstrap 導線の設計検討

- 目的: password-store が未 clone の状態で Git credential helper が `pass` を要求する循環を、手動の設定コメントアウトなしで解消する導線を決める。
- 変更対象: 初期設定ドキュメントまたは専用 bootstrap コマンド（名称・配置は未決定）。
- 非変更対象: 通常時の `gh` wrapper、password-store の暗号化方式、既存 token の保存先、Git credential helper の恒久設定。
- 入出力: native `/usr/bin/gh auth login --web` のデバイスコード認証を入力に、password-store の HTTPS clone と `github/cli-token` への保存を出力とする。native gh token は stdout/stderr に出さない。
- 運用方法: native gh token を shell 変数と当該 clone 子プロセスだけの `GH_TOKEN` に保持し、clone 成功後に `pass` へ保存する。`pass` を用いた復号検証が成功してから native gh のローカル認証を logout する。
- 運用方法（更新）: native gh token を shell 変数と当該 clone 子プロセスだけの `GH_TOKEN` に保持する。password-store は clone 先の親ディレクトリ配下に作った一時ディレクトリへ clone し、`.gpg-id` の全 recipient に対応する GPG 公開鍵・秘密鍵を確認する。一時 store で token 保存・pass 復号検証まで成功した場合だけ、`PASSWORD_STORE_DIR`（未設定時 `~/.password-store`）へ移動して native gh のローカル認証を logout する。
- 失敗時挙動: native gh login、clone、GPG 鍵確認、GPG 暗号化、pass 復号検証のいずれかが失敗したら、一時 clone を削除して token を表示せず停止し、native gh は logout しない。既存の password-store は上書きせず中止する。
- 既存機能への影響: bootstrap 成功時は native gh の一時認証情報が削除され、以後は既存 `bin/gh` の pass 経路を使う。
- 未確定事項: なし。
- ユーザー確認が必要な項目: なし。HLD 合意済み。

## Plan

### 2026-10-08 14:07 : gh の pass 登録時に公開鍵が見つからない原因調査

- [x] `bin/gh` が `pass insert github/cli-token` を呼ぶ条件を確認する。
- [x] エラーメッセージを GPG の暗号化先公開鍵の解決失敗として判定する。
- [x] 秘密情報を出さない照合コマンドを提示する。

### 2026-10-08 14:10 : password-store 初期 clone の認証循環調査

- [x] `pass git clone` の HTTPS clone が Git credential helper を呼ぶ経路を説明する。
- [x] GitHub password authentication が Git HTTPS では利用できない点を明示する。
- [x] 認証循環を回避する SSH bootstrap 手順を提示する。

### 2026-10-08 14:17 : password-store bootstrap 導線の設計検討

- [x] GitHub account password が HTTPS clone の bootstrap credential にならないことを整理する。
- [x] global helper の手動コメントアウトに伴う復元漏れを評価する。
- [x] 初回認証方式として native gh のデバイスコード認証と、成功後の local logout を合意する。
- [x] native gh CLI の login/token/logout の対応と credential 保存・logout の意味を確認する。
- [x] bootstrap 前に native gh 認証が存在する場合は中止する仕様を合意する。
- [x] `pass git clone` が password-store の配置を設定せず、通常の Git clone を行う挙動を確認する。
- [x] password-store clone 配置先として、`PASSWORD_STORE_DIR` 未設定時の `~/.password-store` を合意する。
- [x] 一時 clone で GPG recipient を確認してから恒久配置する方式を合意する。
- [x] HLD を更新し、実装計画と検証を作成する。
- [x] `bin/pass-bootstrap` を追加し、native gh の一時認証・stage clone・GPG 鍵検証・pass 保存/復号・local logout を実装する。
- [x] `ai/tasks/workspace/test-pass-bootstrap.sh` を追加し、成功・既存 native 認証・GPG 鍵不足を fake コマンドで検証する。
- [x] shell 構文、既存・新規テスト、差分の whitespace を確認する。
- [x] lesson skill で最終回答を照合し、Review を完成する。

## Review

### 2026-10-08 14:07 : gh の pass 登録時に公開鍵が見つからない原因調査

- 原因: `bin/gh` は token 未登録時に `pass insert` を実行する。`pass` は password-store の `.gpg-id` にある recipient へ GPG 暗号化しようとするため、その recipient の公開鍵を現在の `GNUPGHOME` で解決できないと、trust 状態にかかわらず `公開鍵がありません` で失敗する。
- 修正内容: なし。
- 検証結果: `bin/gh` の `update_token` が `pass insert -f github/cli-token` を呼ぶことを確認。ユーザー提示ログの GPG メッセージは、暗号化先 recipient の公開鍵未解決と一致する。lesson skill による検証は `codex-lesson --ai-base ai check` を実行し、vector search は利用不可だったため `ai/tasks/lessons.md` を `rg` で確認した。秘密を出力せず実行経路・GPG 設定を一次情報で照合する既存 lesson に従い、鍵 ID と実行時 `GNUPGHOME` だけを確認する手順にした。

### 2026-10-08 14:10 : password-store 初期 clone の認証循環調査

- 原因: HTTPS の `pass git clone` は Git credential helper を実行する。helper の `gh` wrapper は token を password-store から取得しようとするが、clone 前のため取得不能である。その後 Git が求める GitHub account password は Git HTTPS 認証では受け付けられず失敗する。
- 修正内容: なし。SSH URL を用いる bootstrap 手順を案内する。
- 検証結果: ユーザー提示ログは、wrapper が non-TTY の credential helper で `pass` 復元を拒否した後、Git の HTTPS basic-auth fallback が GitHub に拒否される経路と一致する。lesson skill の確認は vector search が利用不可だったため `ai/tasks/lessons.md` を `rg` で照合し、認証経路を実行末端まで追い、secret を表示しない既存 lesson に適合することを確認した。

### 2026-10-08 14:17 : password-store bootstrap 導線の設計検討

- 原因: Git credential helper は password-store の token を通常運用で利用するが、その store 自体を private HTTPS repository から初回 clone する段階には利用できない。
- 修正内容: なし。native gh の `auth login --web`、`auth token`、`auth logout` の help を確認し、デバイスコード認証、token の一時取得、local-only logout を組み合わせる設計を HLD に反映した。
- 検証結果: `GH_TOKEN` は既存 `bin/gh` の pass 復号より優先されるため、token を clone 子プロセス限定で渡せば helper の循環を避けられる。native gh の logout は local configuration を削除するだけで token revoke はしない。bootstrap 前からの native gh 認証は中止する仕様で合意済み。`pass git clone` は clone 先を password-store に結び付けないため、bootstrap は `git clone` の明示的な配置先を使う必要がある。clone 後の GPG/pass 失敗時に、次回を再開処理にするかは未確定。

- 最終仕様: `bin/pass-bootstrap` を追加した。`GH_TOKEN`、既存 password-store、または native gh の既存認証を検出した場合は変更せず停止する。native gh の `--web` デバイスコード認証で得た token は clone 子プロセスの `GH_TOKEN` と shell 変数内だけに限定する。clone は配置先と同じ親ディレクトリの一時領域で行い、`.gpg-id` の全 recipient について公開鍵・秘密鍵を確認する。stage 内で pass 保存と復号確認が成功した場合だけ store を配置し、native gh のローカル認証を logout する。
- 実装: `bin/pass-bootstrap` と fake command による `ai/tasks/workspace/test-pass-bootstrap.sh` を追加した。現行 Git credential helper が渡す action を反映するため、既存 `test-gh-no-tty.sh` の `gh auth git-credential` 呼出しへ `get` を追加した。
- 検証: `sh -n bin/pass-bootstrap`、`sh -n ai/tasks/workspace/test-pass-bootstrap.sh`、`sh -n ai/tasks/workspace/test-gh-no-tty.sh`、新規 bootstrap test、`test-gh-no-tty.sh`、`test-codex-with-gh.sh`、`git diff --check`、`git diff master --check` が成功。新規 test は成功時の token 非出力・native logout、既存 native 認証での無変更停止、GPG 鍵不足時の一時 clone 削除と native auth 保持を確認した。lesson skill は `codex-lesson --ai-base ai check` を実行し、vector search が利用不可のため `ai/tasks/lessons.md` を `rg` で照合した。認証経路と token 出力を明示的に検証する既存 lesson に反する点はない。
