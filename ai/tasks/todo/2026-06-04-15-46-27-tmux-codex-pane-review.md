## Plan

### 2026-06-04 15:46 : tmux codex pane review

- [x] 関連するローカル規約、既存レッスン、過去タスク履歴を確認する
- [x] `tmux.conf` と `codex-pane.sh`、起動導線の現状を確認する
- [x] HLD の論点を整理し、未確定事項をユーザー確認する
- [x] 合意済み HLD に基づいて必要な設定変更を実装する
- [x] `bash -n` と `tmux -f ... -L ... start-server` などで設定妥当性を検証する
- [x] 変更差分と検証結果を Review に記録する

## Review

### 2026-06-04 15:46 : tmux codex pane review

- 原因: `config/tmux/bin/codex-pane.sh` は `codex-with-gh` 終了後に `default-shell` を `exec` しており、tmux 上では Codex 専用 pane が汎用 shell pane に変質していた
- 合意仕様: Codex 専用 pane は終了後に shell へ戻さず終了し、再起動は `Alt-p` の pane menu から `c` で右側へ開けるようにする
- 修正内容: `config/tmux/bin/codex-pane.sh` から shell 復帰処理を削除し、Codex 終了時は終了コードを保ってそのまま exit するようにした
- 修正内容: `config/tmux/bin/open-codex-pane.sh` を追加し、指定 pane の右に 40% 幅で Codex pane を開く処理を共通化した
- 修正内容: `config/tmux/bin/layout-dev.sh` は新 helper を使って初期 Codex pane を開くようにした
- 修正内容: `config/tmux/tmux.conf` の `Alt-p` ガイドに `c` を追加し、pane menu から `c` で Codex pane を右側へ開けるようにした
- 検証: `bash -n config/tmux/bin/codex-pane.sh config/tmux/bin/open-codex-pane.sh config/tmux/bin/layout-dev.sh` が成功した
- 検証: `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-pane-review start-server` が成功し、設定読み込みエラーがないことを確認した
