## HLD

### 2026-07-09 17:47 : notify backhaul tmux pane
- 目的: Codex 完了通知に既存の `tmux_session` / `tmux_window` に加えて `tmux_pane` も含める
- 変更対象: `bin/notify-backhaul.sh` の tmux context 解決処理と payload 拡張処理
- 非変更対象: 通知転送先、既存の `sender` / `tmux_session` / `tmux_window` の仕様、tmux 設定
- 入出力:
  - 入力: Codex の notify payload、実行時環境変数 `TMUX_PANE`、必要に応じて `tmux display-message` の結果
  - 出力: notify payload のトップレベル object に `tmux_pane` を追加する
- 運用方法: `TMUX_PANE` があり tmux context を解決できたときだけ `tmux_pane` を追加する
- 失敗時挙動: `TMUX_PANE` 未設定、tmux コマンド失敗、JSON 変換失敗時は既存通知をそのまま送る
- 既存機能への影響: 受信側が pane 単位の識別に `tmux_pane` を使えるようになる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

## Plan

### 2026-07-09 17:47 : notify backhaul tmux pane
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] 既存の `bin/notify-backhaul.sh` と直近の tmux context 変更履歴を確認する
- [x] HLD の未確定事項をユーザー確認する
- [x] 合意済み HLD をこのファイルに反映する
- [x] `bin/notify-backhaul.sh` に `tmux_pane` を追加する
- [x] 構文確認と payload 変換検証を行う
- [x] Review に原因、修正内容、検証結果を記録する

## Review

### 2026-07-09 17:47 : notify backhaul tmux pane
- 原因: 既存通知は tmux の session/window までは持っていたが、同一 window 内のどの pane からの通知かは識別できなかった
- 修正内容: `bin/notify-backhaul.sh` の `resolve_tmux_context` が `TMUX_PANE` の生値も返すようにし、呼び出し側で `tmux_pane` / `tmux_session` / `tmux_window` を展開するようにした
- 修正内容: notify payload のトップレベル object に `sender`、`tmux_session`、`tmux_window` に加えて `tmux_pane` を追加するようにした
- 失敗時挙動: `TMUX_PANE` 未設定、tmux コマンド失敗、JSON 変換失敗時は既存通知を維持する
- 検証: `bash -n bin/notify-backhaul.sh` が成功した
- 検証: fake `tmux` を `PATH` 先頭に置き `TMUX_PANE='%7'` で実行し、ログに `tmux: pane=%7 session=dev window=editor` が出ることを確認した
- 検証: 同じ実行を `bash -x` で追跡し、変換後 payload が `{"msg":"ok","sender":"host-a","tmux_pane":"%7","tmux_session":"dev","tmux_window":"editor"}` になることを確認した
- 検証: `TMUX_PANE` なしの実行でログに `tmux: unavailable` と `payload_augmented: object sender/tmux added` が出ることを確認した
- 検証制約: このサンドボックスでは `/dev/tcp/127.0.0.1/53245` への接続が `Operation not permitted` で失敗するため、実転送先での受信 payload までは未確認
