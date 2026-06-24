## Plan

### 2026-06-24 09:00 : tmux codex resume key
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] `tmux` の既存バインド実装を確認する
- [x] HLD を整理してユーザー確認を取る
- [x] 合意した範囲だけ `config/tmux/tmux.conf` を修正する
- [x] `tmux -f config/tmux/tmux.conf -L codex-test start-server` などで構文とバインドを検証する
- [x] Review を記録する

### 2026-06-24 09:10 : tmux pane menu color tuning
- [x] 現状の `Alt+p` ガイド配色を確認する
- [x] HLD と推奨配色を整理してユーザー確認を取る
- [x] 合意した範囲だけ `config/tmux/tmux.conf` を修正する
- [x] `tmux` 設定読込で構文確認する
- [x] Review を記録する

## Review

### 2026-06-24 09:00 : tmux codex resume key
- 原因: `pane_mode` では `Alt+p, n` が縦分割新規ペインに割り当てられていたが、同モードに `|` / `-` の分割が既にあり冗長だった。一方で `codex` は新規起動しかなく、`resume` の入口が不足していた
- 修正内容:
  - `config/tmux/tmux.conf` の `Alt+p` ガイドから `n` を削除し、`r` を `resume` 表示へ変更
  - `pane_mode` の `n` バインドを削除し、既存の `r` `respawn-pane` を `open-codex-pane.sh ... resume` へ置換
  - `open-codex-pane.sh` と `codex-pane.sh` を引数透過対応にし、`Alt+p, c` は従来どおり、`Alt+p, r` だけ `codex resume` を同じ起動経路で開けるようにした
- 検証結果:
  - `bash -n config/tmux/bin/open-codex-pane.sh` と `bash -n config/tmux/bin/codex-pane.sh` が成功
  - `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-test new-session -d -s codex-test` が成功し、更新後の `tmux.conf` を読めることを確認
  - スタブ `tmux` で `open-codex-pane.sh %1 /work resume` を実行し、`split-window ... codex-pane.sh resume` が呼ばれることを確認
  - スタブ `codex-with-gh` で `codex-pane.sh resume` を実行し、`resume` 引数が最終的に `codex` 起動コマンドへ渡ることを確認

### 2026-06-24 09:10 : tmux pane menu color tuning
- 原因: `Alt+p` ガイドで `popup` が `colour39`、`codex` が `colour81` になっており、どちらも近い青系で視認差が弱かった
- 修正内容: `config/tmux/tmux.conf` の `Alt+p` ガイドで `popup` の色を `colour118` へ変更し、`codex` の青系と役割ごとの差を出した
- 検証結果:
  - `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-test new-session -d -s codex-test` が成功し、更新後の `tmux.conf` を読めることを確認
