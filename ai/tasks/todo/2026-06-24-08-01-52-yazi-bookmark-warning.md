## Plan

### 2026-06-24 08:01 : yazi bookmark warning 抑止
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] `config/yazi` と導入済み plugin の現状を確認する
- [x] warning の一次原因を特定する
- [x] 対応方針の HLD をユーザーと合意する
- [x] 合意した範囲だけ実装する
- [x] `make yazi-bookmark-plugin-patch` を隔離環境で検証する
- [x] Review を記録する

## Review

### 2026-06-24 08:01 : yazi bookmark warning 抑止
- 原因: 導入済み `bookmarks.yazi` の `main.lua` に `ya.mgr_emit()` が残っており、`Yazi 26.5.6` で deprecated API warning が出る状態だった。該当修正は upstream PR `dedukun/bookmarks.yazi#61` に既に存在する
- 修正内容: 通常の `yazi-plugins` フローは変えず、手動実行専用の `make yazi-bookmark-plugin-patch` を `Makefile` に追加した。タスクは `~/.config/yazi/plugins/bookmarks.yazi/main.lua` を検査し、`ya.mgr_emit("cd"` / `ya.mgr_emit("reveal"` を PR #61 相当の `ya.emit(...)` に置換する
- 運用: 自動実行はしない。`make yazi-plugins` 後に必要なときだけ `make yazi-bookmark-plugin-patch` をユーザーが実行する
- 検証結果:
  - 隔離した `HOME` 配下へ旧 plugin ファイルを置き、`make yazi-bookmark-plugin-patch HOME=<tmp>` で `ya.emit("cd"` と `ya.emit("reveal"` へ置換されることを確認
  - patched 済み plugin を含む一時 `~/.config/yazi` で `yazi --debug </dev/null` が 0 終了することを確認
