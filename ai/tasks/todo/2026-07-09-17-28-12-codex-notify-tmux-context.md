## HLD

### 2026-07-09 17:28 : codex notify tmux context
- 目的: Codex 完了通知に tmux の session 名と window 名を含められるか調査し、実装方針を整理する
- 変更対象: `bin/notify-backhaul.sh` の payload 拡張処理
- 非変更対象: 通知転送先、tmux レイアウト、Codex 本体挙動
- 入出力:
  - 入力: Codex の notify payload、実行時環境変数、必要に応じて tmux が返す session/window 情報
  - 出力: notify payload のトップレベル object に `sender` に加えて `tmux_session` と `tmux_window` を追加する
- 運用方法: Codex が tmux pane 内で動いている場合だけ `TMUX_PANE` を使って session/window を取得し、tmux 外ではキーを追加しない
- 失敗時挙動: `tmux` コマンド失敗や `TMUX_PANE` 未設定時は既存通知をそのまま送る
- 既存機能への影響: `sender` の意味は維持しつつ、受信側で追加キーを利用できるようになる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

## Plan

### 2026-07-09 17:28 : codex notify tmux context
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] 既存の `bin/notify-backhaul.sh` と Codex notify 設定を確認する
- [x] tmux 情報の取得候補と制約を整理する
- [x] HLD の未確定事項をユーザー確認する
- [x] `TMUX_PANE` から session/window を取得して payload に追加する実装を入れる
- [x] 構文確認と payload 変換検証を行う
- [x] Review に結果を記録する

## Review

### 2026-07-09 17:28 : codex notify tmux context
- 原因: 既存通知は `sender` に host/IP だけを追加しており、tmux 上のどの session/window から来た通知かを識別できなかった
- 修正内容: `bin/notify-backhaul.sh` に `resolve_tmux_context` を追加し、`TMUX_PANE` があるときだけ `tmux display-message -p -t "$TMUX_PANE"` で `session_name` と `window_name` を取得するようにした
- 修正内容: notify payload のトップレベル object に `sender` を維持したまま `tmux_session` と `tmux_window` を追加するようにした
- 失敗時挙動: tmux 外、`TMUX_PANE` 未設定、または `tmux` コマンド失敗時は `tmux_*` を追加せず既存通知を維持する
- 検証: `bash -n bin/notify-backhaul.sh` が成功した
- 検証: fake `tmux` を `PATH` 先頭に置いた実行でログに `tmux: session=dev window=editor` と `payload_augmented: object sender/tmux added` が出ることを確認した
- 検証: `TMUX_PANE` なしの実行でログに `tmux: unavailable` と `payload_augmented: object sender/tmux added` が出ることを確認した
- 検証制約: このサンドボックスでは `/dev/tcp/127.0.0.1/53245` が接続できず、実転送先での受信 payload までは未確認
