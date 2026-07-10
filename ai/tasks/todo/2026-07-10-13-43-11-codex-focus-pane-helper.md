## HLD

### 2026-07-10 13:43 : codex focus pane helper
- 目的: Codex 通知から受け取った tmux pane/session/window 条件を helper に閉じ込め、条件一致時だけ対象 pane へ戻れるようにする
- 変更対象: `config/tmux/bin/codex-focus-pane.sh`
- 非変更対象: 既存の prefix、主要キーバインド、Codex 通知送信側ロジック、既存 helper の挙動
- 入出力:
  - 入力: `--pane` 必須、`--session` 任意、`--window` 任意
  - 出力: 条件一致時のみ tmux client の active pane を対象へ切り替える。通常時の標準出力はなし
- 運用方法: tmux `command-prompt` から `run-shell` 経由で non-interactive に呼び出す
- 失敗時挙動: tmux 外実行、pane 不在、session 不一致、window 不一致、引数不正では非 0 終了し、stderr は最小限にとどめる
- 既存機能への影響: 既存キーバインドは変更せず、Codex 通知から戻るための呼び出し先 helper が追加される
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

## Plan

### 2026-07-10 13:43 : codex focus pane helper
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] 既存の tmux helper と直近の tmux タスク履歴を確認する
- [x] HLD の未確定事項をユーザー確認する
- [x] 合意済み HLD をこのファイルに反映する
- [x] `config/tmux/bin/codex-focus-pane.sh` を実装する
- [x] 実行権限を付与する
- [x] `bash -n config/tmux/bin/codex-focus-pane.sh` を実行する
- [x] 可能な範囲で tmux 内の正常系と不一致系を検証する
- [x] `git diff --check` を実行する
- [x] Review に原因、修正内容、検証結果を記録する

## Review

### 2026-07-10 13:43 : codex focus pane helper
- 原因: Codex 通知から tmux の特定 pane へ戻る処理を shell 履歴へ生の `tmux switch-client ...` として残さず、安全に helper へ閉じ込める入口がなかった
- 修正内容: `config/tmux/bin/codex-focus-pane.sh` を追加し、`--pane` 必須、`--session` / `--window` 任意の引数を解釈するようにした
- 修正内容: 対象 pane の存在確認後、`session_name` と `window_name` を `tmux display-message` で取得し、指定条件が一致した場合に限って `tmux switch-client ... \; select-window ... \; select-pane ...` を実行するようにした
- 修正内容: tmux 外実行、pane 不在、条件不一致、引数不正では非 0 終了し、標準出力なし・stderr 最小限にとどめるようにした
- 検証: `bash -n config/tmux/bin/codex-focus-pane.sh` が成功した
- 検証: 実行権限 `-rwxrwxr-x` が付与されていることを確認した
- 検証: 一時 tmux server `codex-focus-test` を起動し、window 名 `feature/enhancement#320` を持つ session `gentle-dotfiles` で 2 pane を作成した
- 検証: attach 済み client の `TMUX` 環境で helper を `--pane %0 --session gentle-dotfiles --window 'feature/enhancement#320'` として実行し、`pane_active` が `%1` から `%0` へ切り替わることを確認した
- 検証: 同じ条件で `--window 'wrong-window'` を指定すると `window mismatch` で非 0 終了し、`pane_active` が `%1` のまま変化しないことを確認した
- 検証: `env -u TMUX ... --pane %0` で `not in tmux` を返して非 0 終了することを確認した
- 検証: `git diff --check` が成功した
