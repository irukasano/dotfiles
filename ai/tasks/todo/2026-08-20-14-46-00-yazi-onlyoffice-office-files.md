## HLD

### 2026-08-20 14:46 : yazi OnlyOffice 既定化
- 目的: `yazi` で office ファイルの `Enter` 起動先を `FreeOffice` から `OnlyOffice` へ切り替える
- 変更対象: `config/yazi/yazi.toml` の office 系 opener 定義と対象拡張子の `open.rules`
- 非変更対象: `csv` の CP932 変換機能、`OnlyOffice` 自体のインストール、Windows 向け opener、`yazi` 以外のアプリ関連付け
- 入出力: 入力は `*.xlsx` への `Enter` または interactive open。出力は `OnlyOffice` を既定にした opener 実行と、interactive open 候補から `FreeOffice` を除いた一覧
- 運用方法: Linux の `freeoffice` opener を削除し、`*.xlsx` の `use` を `OnlyOffice` 優先へ変更する。`FreeOffice` が候補に出ていた他ルールからも参照を除去する
- 失敗時挙動: `desktopeditors` が存在しない場合は `OnlyOffice` 起動が失敗する。追加フォールバックは合意なしに入れない
- 既存機能への影響: `*.xlsx` の `Enter` 既定起動先が `OnlyOffice` になる。`FreeOffice` が interactive open 候補に出ていた `*.xlsx` と `*.csv` の候補一覧が変わる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

## Plan

### 2026-08-20 14:46 : yazi OnlyOffice 既定化
- [x] 対象拡張子と `freeoffice` opener の扱いをユーザー確認する
- [x] 合意した HLD をこのファイルへ反映する
- [x] `config/yazi/yazi.toml` の office 関連設定を更新する
- [x] `yazi --debug </dev/null` で設定パースを検証する
- [x] `*.xlsx` と `*.csv` の interactive open 候補から `FreeOffice` が消えたことを確認する
- [x] Review に原因・修正内容・検証結果を記録する

## Review

### 2026-08-20 14:46 : yazi OnlyOffice 既定化
- 原因: `*.xlsx` の既定 opener が `/usr/share/freeoffice2024/planmaker` を使う `freeoffice` 先頭になっており、FreeOffice 削除後は `Enter` で起動できなくなっていた
- 修正内容: `config/yazi/yazi.toml` から Linux 用 `freeoffice` opener を削除し、`*.xlsx` の `use` を `[ "office", "reveal" ]` へ変更して `OnlyOffice` を既定に戻した
- 修正内容: `*.csv` の interactive open 候補からも `freeoffice` 参照を削除し、`FreeOffice` がどの候補一覧にも出ないようにした
- 検証結果: `yazi --debug </dev/null` が 0 終了し、設定パース成功を確認した
- 検証結果: TTY 上で `test.xlsx` の interactive open 候補が `OnlyOffice` / `Reveal` のみになることを確認した
- 検証結果: TTY 上で `test.csv` の interactive open 候補が `$EDITOR` / `OnlyOffice` / `Convert to CP932` / `Reveal` になり、`FreeOffice` が消えていることを確認した
