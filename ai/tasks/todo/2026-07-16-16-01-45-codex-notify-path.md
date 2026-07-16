## HLD

### 2026-07-16 16:01 : codex notify path
- 目的: `Makefile` の Codex 設定生成で `notify-backhaul.sh` の参照先を `dotfiles/bin` から `$HOME/.local/bin` へ変更する
- 変更対象: `Makefile` の `codex-config` タスク
- 非変更対象: `bin/notify-backhaul.sh` 本体、他の Codex 設定値、`codex-gh-mcp` の追記ロジック
- 入出力:
  - 入力: `make codex-config` 実行時の `HOME`
  - 出力: `$$HOME/.codex/config.toml` の `notify` 行が `$$HOME/.local/bin/notify-backhaul.sh` を参照する
- 運用方法: 既存どおり `codex-config` 実行時に managed config を新規生成する
- 失敗時挙動: managed 済み `config.toml` があれば既存どおり skip する
- 既存機能への影響: 新規生成される Codex 設定の通知スクリプト参照先のみ変わる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

## Plan

### 2026-07-16 16:01 : codex notify path
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] `Makefile` の `codex-config` と関連する Codex タスクを確認する
- [x] `codex-config` の `notify` 行を `$HOME/.local/bin/notify-backhaul.sh` 参照へ変更する
- [x] `HOME=/tmp/... make codex-config` で生成結果を検証する
- [x] `git diff --check` を実行する
- [x] Review に結果を記録する

## Review

### 2026-07-16 16:01 : codex notify path
- 原因: `codex-config` が生成する `config.toml` の `notify` 行が `$$HOME/dotfiles/bin/notify-backhaul.sh` を参照しており、希望する `$HOME/.local/bin` 配置とずれていた
- 修正内容: `Makefile` の `codex-config` で出力する `notify` 行を `$$HOME/.local/bin/notify-backhaul.sh` へ変更した
- 検証: `HOME=/tmp/codex-notify-path-test make codex-config` が成功した
- 検証: 生成された `/tmp/codex-notify-path-test/.codex/config.toml` に `notify = ["/tmp/codex-notify-path-test/.local/bin/notify-backhaul.sh"]` が出力されることを確認した
- 検証: `git diff --check` が成功した
