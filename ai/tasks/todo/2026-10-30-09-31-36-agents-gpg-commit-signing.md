## HLD

### 2026-10-30 09:31 : GPG 署名付き commit の待機

- 目的: GPG pinentry の失敗やキャッシュ切れが起きても、署名を外した commit を作らず、ユーザーが pinentry に入力できるまで作業を中断する行動を明文化する。
- 変更対象: `config/codex/AGENTS.md` の git commit / GPG 署名に関する行動指針。
- 非変更対象: Git/GPG の設定、hook、commit 実行スクリプト、他ファイル。
- 入出力: commit が署名エラーになる状況を受け、Codex は commit を中断し、ユーザーに `echo test | gpg --clearsign` を実行するよう促す。ユーザーが pinentry に入力を終えた後、署名付き commit を再試行する。
- 運用方法: 署名を無効化するオプションや署名なしの代替 commit は使わない。pinentry 入力中は再試行せず待つ。
- 失敗時挙動: pinentry 入力後も署名に失敗した場合は commit を続けず、エラーを報告する。
- 既存機能への影響: GPG 署名が成功する通常の commit 手順には影響しない。
- 未確定事項: なし（上記は依頼文からの仕様案）。
- ユーザー確認が必要な項目: この仕様案と対象箇所で編集を進めてよいか。

## Plan

- [x] HLD への合意を得る。
- [x] 合意した仕様に沿い `config/codex/AGENTS.md` に短い行動規則を追加する。
- [x] 差分を確認し、文言が「署名なしで続行しない」「`echo test | gpg --clearsign` をユーザーに促す」「pinentry 入力まで中断」「入力後に署名付きで再試行」を網羅することを確認する。
- [x] Review に変更と検証結果を記録する。

## Review

- 原因: GPG agent の認証キャッシュが切れると commit の pinentry が失敗し、署名なし commit に進む危険があった。
- 修正内容: `config/codex/AGENTS.md` に GPG 署名付き commit の手順を追加した。署名エラー時は署名なしで続行せず、ユーザーに `echo test | gpg --clearsign` の実行を促し、pinentry 入力完了まで commit を中断して待ってから署名付き commit を再試行する。再試行失敗時も中断して報告する。
- 検証: `git diff --check` 成功。差分を目視し、指定コマンドの案内、待機、署名付き再試行、失敗時中断を確認した。GPG コマンド自体は実行していない。
- Lesson 最終確認: `codex-lesson check` で vector/index が利用可能だったため、検索上位 5 件と各 Review を確認した。関連 lessons は credential helper や no-TTY 実行の pinentry 挙動に関するもので、今回の対話的 commit 手順への追加指摘はなかった。
