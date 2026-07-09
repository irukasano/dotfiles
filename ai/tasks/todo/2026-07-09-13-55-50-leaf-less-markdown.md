## HLD

### 2026-07-09 13:55 : leaf install and less markdown removal
- 目的: `less` で Markdown を man 形式へ変換して表示する既存処理を削除し、`leaf` のインストール導線を追加して `make all` に含める
- 変更対象: `Makefile` のインストールタスク定義、`less` の Markdown 表示に関わる既存設定、必要であれば関連ドキュメント
- 非変更対象: Markdown のブラウザプレビュー用スクリプト群、Markdown 以外の `less` 色付け処理、`leaf` 本体の設定
- 入出力:
  - 入力: `make all`、および Markdown ファイルを `less` で開く既存フロー
  - 出力: `make all` で `leaf` 導入タスクが実行対象に含まれ、Markdown を `less` で開いても man 変換処理は走らない
- 運用方法: 既存のインストールタスク体系に沿って `leaf` 導線を追加し、Markdown 用 `less` フィルタは削除または無効化する
- 失敗時挙動: `leaf` インストールコマンド失敗時は当該 `make` タスクが失敗として停止する想定
- 既存機能への影響: Markdown を `less` で見た際の見え方が変わる。`all` / 関連上位タスクの実行内容が増える
- 未確定事項:
  - なし
- ユーザー確認が必要な項目:
  - なし

## Plan

### 2026-07-09 13:55 : leaf install and less markdown removal
- [x] HLD の未確定事項をユーザー確認で確定する
- [x] 合意済み HLD に基づいて `## Plan` を具体化する
- [x] `Makefile` に `leaf` タスクを追加し、`tools-all` 経由で `base` / `all` に含める
- [x] `.lessfilter` から Markdown を man 変換する `*.md` 分岐を削除する
- [x] `README.md` の `less` 向け Markdown 変換説明を現状に合わせて更新する
- [x] `Makefile` と必要な関連ファイルを更新する
- [x] `make -n` と差分確認で期待動作を検証する
- [x] `## Review` に原因・修正内容・検証結果を記録する

## Review

### 2026-07-09 13:55 : leaf install and less markdown removal
- 原因: `.lessfilter` が `*.md` を `pandoc -t man | groff` へ流しており、Markdown を `less` で man 形式表示する独自処理が残っていた。一方で `leaf` の導入タスクは存在せず、`make all` に含まれていなかった
- 修正内容: `Makefile` に `leaf` タスクを追加し、`tools-all` へ依存追加して `make all` に含まれるようにした
- 修正内容: `.lessfilter` から Markdown 用 `*.md` 分岐を削除し、Markdown を `less` 向けに変換しないようにした
- 修正内容: `README.md` から古い `LESSCLOSE` / `lesspipe` パッチ説明を外し、Markdown は `leaf` を使う案内へ更新した
- 検証結果:
  - `make -n leaf tools-all all` で `curl -fsSL https://leaf.rivolink.mg/install.sh | sh` が `leaf` 単体と `all` 導線の両方に含まれることを確認
  - `make help | rg '^leaf\s'` で `leaf` タスクが一覧表示されることを確認
  - `sh -n .lessfilter` が成功し、フィルタのシェル構文が壊れていないことを確認
  - `rg -n '\*\.md\)|leaf|LESSOPEN|lesspipe|lessfilter' Makefile README.md config/fish/config.fish .lessfilter` で `.lessfilter` から Markdown 分岐が消え、`leaf` 導線だけが追加されたことを確認
  - `git diff --check -- Makefile .lessfilter README.md ai/tasks/todo/2026-07-09-13-55-50-leaf-less-markdown.md` が成功し、whitespace error がないことを確認
