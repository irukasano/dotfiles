## HLD

### 2026-08-20 14:39 : tmux codex pane focus
- 目的: `tmux` の `Alt-p` から `c` / `r` で `codex` pane を開いた際、起動した pane にフォーカスを残せるようにする
- 変更対象: `config/tmux/bin/open-codex-pane.sh`、必要なら `config/tmux/tmux.conf`
- 非変更対象: `codex` 起動コマンド本体、pane サイズ、他の pane 操作キーバインド
- 入出力:
  - 入力: `open-codex-pane.sh <target-pane-id> <dir> [codex args...]`
  - 出力: `codex` 用 pane を開き、合意した場合はその pane をアクティブにする
- 運用方法: 既存の `Alt-p c` / `Alt-p r` バインドから利用する
- 失敗時挙動: `tmux` や helper 不在時は従来どおり非 0 終了してメッセージを返す
- 既存機能への影響: `codex` pane 起動直後のフォーカス遷移だけが変わる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

## Plan

### 2026-08-20 14:39 : tmux codex pane focus
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] 既存の `tmux` / `codex` 関連実装と過去タスクを確認する
- [x] HLD の未確定事項をユーザー確認する
- [x] 合意済み HLD をこのファイルに反映する
- [x] `open-codex-pane.sh` のフォーカス制御を実装する
- [x] 必要なら `tmux.conf` の呼び出し側も調整する
- [x] `bash -n` で関連 script を検証する
- [x] 可能な範囲で `tmux` 上のフォーカス遷移を実証する
- [x] `git diff --check` を実行する
- [x] Review に原因、修正内容、検証結果を記録する

## Review

### 2026-08-20 14:39 : tmux codex pane focus
- 原因: `config/tmux/bin/open-codex-pane.sh` が `tmux split-window ...` の直後に `tmux select-pane -t "$target_pane"` を実行しており、新規 `codex` pane 作成後に明示的に元 pane へフォーカスを戻していた
- 修正内容: `split-window -P -F '#{pane_id}'` の戻り値を `codex_pane` として受け取り、その pane を `tmux select-pane -t "$codex_pane"` で選択するように変更した
- 修正内容: `tmux.conf` 側の `Alt-p c` / `Alt-p r` 呼び出しはそのままとし、共通 helper の挙動だけで両方を修正した
- 検証: `bash -n config/tmux/bin/open-codex-pane.sh config/tmux/bin/codex-pane.sh config/tmux/bin/codex-focus-pane.sh` が成功した
- 検証: 一時 `tmux` server を `/tmp/tmux-codex-focus.xJymAU/tmux.sock` で起動し、`open-codex-pane.sh` 実行前の target pane `%0` から新規 pane `%1` が作成され、active pane が `%1` へ切り替わることを確認した
- 検証: `git diff --check` が成功した
