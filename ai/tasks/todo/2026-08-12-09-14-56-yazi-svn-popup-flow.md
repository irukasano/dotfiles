## HLD

### 2026-08-12 09:14 : yazi svn popup flow
- 目的: `yazi` から使う `svn` 操作の主導線を `lazysvn` へ寄せ、複数行 commit message 編集や `status` / `commit` / `log` / `diff` の常駐表示を `lazysvn` 側の TUI に委譲する
- 変更対象: `config/yazi/keymap.toml`、必要なら `config/yazi/plugins/svn.yazi/`、`Makefile`
- 非変更対象: `svn` CLI 自体、`lazysvn` 本体の upstream 実装、既存の他機能の `yazi` / `tmux` 設定
- 入出力:
  - 入力: `yazi` の `SVN` キーバインド経由で `add` / `status` / `update` / `commit` を起動
  - 出力: 合意した UI 上で `svn` 実行結果を表示し、必要なら commit message 編集を行う
- 運用方法: `yazi` からは `shell "lazysvn" --block` を主導線として起動し、必要に応じて既存 `svn.yazi` の役割を縮小または整理する
- 運用方法: `yazi` からは既存の `S l` で `shell "lazysvn" --block` を起動しつつ、`S a/c/s/u` の既存 `svn.yazi` 導線は維持する
- 失敗時挙動: `lazysvn` 未導入や起動失敗時は、`yazi` の shell 実行エラーとして利用者が認識できる状態を維持する。導入は `Makefile` タスクで再現可能にする
- 既存機能への影響: `S` プレフィクス配下の既存導線は維持したまま、`S l` と独立した `lazysvn` 導入手段を明示する。`make yazi` / `make yazi-all` には自動導入しない
- 未確定事項:
  - なし
- ユーザー確認が必要な項目:
  - なし

## Plan

### 2026-08-12 09:14 : yazi svn popup flow
- [x] 既存の `svn.yazi` 実装、関連履歴、`tmux` popup 系資産、`yazi` の現行対話 API を確認する
- [x] UI 方針の未確定事項を 1 件ずつユーザー確認し、合意内容を HLD に反映する
- [x] 合意済み HLD に基づいて Plan を具体化する
- [x] `Makefile` の既存 `yazi` セクションに合わせて、独立した `lazysvn` 導入ターゲットを設計する
- [x] 合意済み方針どおり、`S l` は維持したまま `Makefile` に `lazysvn` ターゲットを追加する
- [x] 必要なら `ai/tasks` 記録内で、`lazysvn` が主導線・`svn.yazi` は補助導線であることを明文化する
- [x] 実装が必要なら対象ファイルを更新する
- [x] `make -n lazysvn` などで導入コマンド列を検証し、必要なら `yazi --debug </dev/null` で既存設定が壊れていないことも確認する
- [x] `git diff --check` と task 記録更新で仕上げる

## Review

### 2026-08-12 09:14 : yazi svn popup flow
- 原因: `yazi` の `svn.yazi` は `ya.input()` と `ya.notify()` ベースで、複数行 commit message 編集と持続的な status/commit ログ表示に向いていなかった。一方、`S l` で `lazysvn` を起動する導線は既にあり、導入手段だけが `Makefile` に欠けていた
- 修正内容: `Makefile` に独立ターゲット `lazysvn` を追加し、公式 quick install `curl -fsSL https://lazysvn.sawirstudio.com/install.sh | sh` を実行できるようにした
- 修正内容: インストール直後に `lazysvn --version` を試し、まだ PATH へ反映されていない場合は shell 再起動を促すメッセージを出すようにした
- 検証結果: `make -n lazysvn` で公式 install script 呼び出しとバージョン確認コマンドが順に出力されることを確認した
- 検証結果: `git diff --check -- Makefile ai/tasks/todo/2026-08-12-09-14-56-yazi-svn-popup-flow.md` が成功した
