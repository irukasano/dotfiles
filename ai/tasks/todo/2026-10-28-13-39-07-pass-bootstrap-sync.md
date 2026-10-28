## HLD

### 2026-10-28 13:39 : pass-sync で既存 store を同期
- 目的: B PC の `~/.password-store` にある古い token で Git 認証に失敗する状況を、同期専用の `bin/pass-sync` で安全に解消する。
- 変更対象案: 独立した `bin/pass-sync` と対応する `ai/tasks/workspace/test-pass-sync.sh` を追加する。
- 非変更対象: `bin/gh` の通常認証フロー、pass の保存形式、初期 clone の仕様、GitHub 側 token の内容。
- 入出力案: 引数なしで native `/usr/bin/gh` の一時 web 認証を行い、取得した token を `pass git pull` subprocess の `GH_TOKEN` にだけ渡す。token 本文は出力しない。
- 運用方法案: A PC 側で変更を push した後、既存 password-store がある PC で `bin/pass-sync` を実行する。
- 失敗時挙動: 認証または pull が失敗したら非 0 で停止する。既存 store の内容は Git が変更した範囲以外変更しない。pull が失敗した場合は復旧に使えるよう native gh 認証を保持し、成功後に logout する（既存 bootstrap の失敗時挙動に合わせる）。
- 既存機能への影響: `bin/pass-bootstrap` の初期化動作は変更しない。`bin/pass-sync` は既存 store のみを同期する。
- 未確定事項: なし。
- ユーザー確認: `bin/pass-sync` という独立した同期コマンドを追加し、native web 認証を同期時だけ使う方針で合意済み（2026-10-28）。

## Plan

- [x] HLD と `bin/pass-sync` の仕様について合意を得る。
- [x] 同期認証は native web login、`GH_TOKEN` は `pass git pull` の子プロセスだけに渡し、成功後のみ logout する。
- [x] 独立した `bin/pass-sync` を追加し、`bin/pass-bootstrap` の初期化動作を維持する。
- [x] fake command fixture で成功・既存 native 認証/GH_TOKEN 拒否・pull 失敗・logout 挙動と token 非出力を検証する。
- [x] 構文・差分チェックと関連 `pass-bootstrap` テストを実行する。
- [x] lesson skill のチェックと Review 記録を完了する。

## Review

### 2026-10-28 13:39 : pass-sync で既存 store を同期
- 原因: `pass git pull` が既存 Git credential helper の `bin/gh` を通り、同期元の token ではなく pull 前の古い pass token を使用するため認証できない。
- 修正内容: 独立した `bin/pass-sync` を追加した。native `/usr/bin/gh` の既存認証がないことを確認して web login し、その token を `pass git pull` の子プロセスだけに `GH_TOKEN` として渡す。pull 成功後に native gh を logout する。pull 失敗時は bootstrap と同じく native 認証を保持する。`bin/pass-bootstrap` は変更していない。
- 検証結果: `sh -n bin/pass-sync ai/tasks/workspace/test-pass-sync.sh`、`ai/tasks/workspace/test-pass-sync.sh`、`ai/tasks/workspace/test-pass-bootstrap.sh`、`git diff --check` が成功した。fixture で一時 token の限定継承、成功時 logout、pull 失敗時の認証保持、事前設定 `GH_TOKEN` の拒否、token 非出力を確認した。
- lesson skill: `codex-lesson check` は vector/index 利用可能を返した。上位5件を照合し、bootstrap credential を正本 entry に保存しない lesson は適用対象と判断、実装では token を pass に書かず pull subprocess のみに渡した。認証経路を揃えて secret 本文を出さない lesson に従い、テストでは token の値を比較するだけでログへ出さない。GPG helper/pinentry lesson は `GH_TOKEN` 経路で GPG を呼ばないため追加の実機 pinentry 確認対象外。
- 制限: 実 GitHub に対する実認証・pull は実施していない。fixture によるコマンド境界と失敗時挙動の検証まで。
