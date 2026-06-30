## HLD

### 2026-06-30 10:13 : yazi csv FreeOffice 化
- 目的: `yazi` で `csv` ファイルに対して `Shift+Enter` を押したとき、候補に `OnlyOffice` と `FreeOffice` の両方を出し、既存の `office` 候補は `OnlyOffice` として明示する
- 変更対象: `config/yazi/yazi.toml` の opener 定義と `text/csv` の `use` 順
- 非変更対象: `csv` 以外の MIME ルール、`Shift+Enter` 以外のキーバインド、Windows 向け opener、通常 Enter の既定動作
- 入出力: 入力は `text/csv` に対する `Shift+Enter`。出力は `$EDITOR` / `OnlyOffice` / `FreeOffice` / `Reveal` の候補表示と、各 opener 実行
- 運用方法: Linux の既存 `office` opener は `OnlyOffice` として残し、新規 `freeoffice` opener を追加する。`text/csv` ルールだけに `freeoffice` を追加する
- 失敗時挙動: `/usr/share/freeoffice2024/planmaker` または `desktopeditors` が存在しない場合、その opener 単体が起動失敗する。フォールバック追加は行わない
- 既存機能への影響: `office` opener を参照する既存/将来の Linux ルールは `OnlyOffice` 表示になる。`FreeOffice` は `text/csv` ルールにだけ追加する
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

### 2026-06-30 10:18 : yazi xlsx OnlyOffice 追加
- 目的: `yazi` で `xlsx` ファイルに対して `Shift+Enter` を押したとき、候補に `OnlyOffice` を出せるようにする
- 変更対象: `config/yazi/yazi.toml` の `open.rules`
- 非変更対象: `csv` ルール、`FreeOffice` opener、`xlsx` 以外の MIME ルール、通常 Enter の既定動作
- 入出力: 入力は `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` に対する `Shift+Enter`。出力は `OnlyOffice` / `Reveal` の候補表示
- 運用方法: `xlsx` 専用 MIME ルールを追加し、`office` opener を使う
- 失敗時挙動: `desktopeditors` が存在しない場合、その opener 単体が起動失敗する。フォールバック追加は行わない
- 既存機能への影響: `xlsx` だけが専用ルールで `OnlyOffice` を選べるようになる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

### 2026-06-30 10:27 : yazi office 候補不一致修正
- 目的: `Shift+Enter` で `csv` / `xlsx` の `OnlyOffice` / `FreeOffice` 候補が実際に表示されるようにする
- 変更対象: `config/yazi/yazi.toml` の `open.rules`
- 非変更対象: opener コマンド本体、他拡張子のルール、通常 Enter の既定動作
- 入出力: 入力は `csv` / `xlsx` ファイルへの `Shift+Enter`。出力は意図した opener 候補一覧
- 運用方法: `mime` ではなく `url` の拡張子ルールで `csv` / `xlsx` をマッチさせる
- 失敗時挙動: 対象拡張子でないファイルは既存ルールへフォールスルーする
- 既存機能への影響: `csv` / `xlsx` の interactive open 候補選定が拡張子ベースになる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

### 2026-06-30 10:31 : yazi xlsx FreeOffice 優先化
- 目的: `xlsx` の通常 `open` を `FreeOffice` にし、`Shift+Enter` 候補も `FreeOffice` / `OnlyOffice` / `Reveal` の順にする
- 変更対象: `config/yazi/yazi.toml` の `open.rules`
- 非変更対象: `csv` ルール、opener コマンド本体、`xlsx` 以外のルール
- 入出力: 入力は `*.xlsx` への通常 `open` と `Shift+Enter`。出力は通常時 `FreeOffice` 起動、interactive 時 `FreeOffice` / `OnlyOffice` / `Reveal` の候補表示
- 運用方法: `*.xlsx` の `use` 順を `[ "freeoffice", "office", "reveal" ]` に変更する
- 失敗時挙動: `/usr/share/freeoffice2024/planmaker` が存在しない場合、通常 `open` と先頭候補の `FreeOffice` は起動失敗する。フォールバック追加は行わない
- 既存機能への影響: `xlsx` だけが `FreeOffice` 優先になる
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

### 2026-06-30 10:34 : yazi csv CP932 変換追加
- 目的: `csv` の `Shift+Enter` 候補に CP932 変換アクションを追加する
- 変更対象: `config/yazi/yazi.toml` の opener / open.rules、必要なら `config/yazi/scripts/` 配下の変換スクリプト
- 非変更対象: `csv` 以外のルール、既存 `OnlyOffice` / `FreeOffice` / `Reveal` の順序、`xlsx` の既定動作
- 入出力: 入力は `*.csv` に対する `Shift+Enter`。出力は CP932 変換コマンド実行
- 運用方法: `csv` 専用 opener を追加し、外部スクリプトで変換処理を行う想定
- 失敗時挙動: 変換元が UTF-8 でない、変換コマンドが利用不可などの条件では明示的に失敗させる。変換先が既に存在する場合は上書き確認を優先し、確認導線が難しければ強制上書きを許容する
- 既存機能への影響: `csv` の interactive open 候補が 1 つ増える
- 未確定事項: なし
- ユーザー確認が必要な項目: なし

## Plan
- [x] `config/yazi/yazi.toml` の `office` Linux 表示名を `OnlyOffice` に変更する
- [x] `config/yazi/yazi.toml` に `/usr/share/freeoffice2024/planmaker` を使う `freeoffice` opener を追加する
- [x] `text/csv` の `use` を `$EDITOR` / `OnlyOffice` / `FreeOffice` / `Reveal` の順に更新する
- [x] `yazi --debug </dev/null` で設定パースを検証する
- [x] `config/yazi/yazi.toml` に `xlsx` 用 MIME ルールを追加する
- [x] `yazi --debug </dev/null` で設定パースを再検証する
- [x] `Shift+Enter` で `csv` / `xlsx` の候補が不足する再現条件を確認する
- [x] `config/yazi/yazi.toml` の `csv` / `xlsx` ルールを interactive open に効く形へ修正する
- [x] `yazi --debug </dev/null` と TTY 再現で候補表示を再検証する
- [x] `xlsx` の `use` 順を `FreeOffice` 優先へ変更する
- [x] `yazi --debug </dev/null` と TTY 再現で `xlsx` の候補順を再検証する
- [x] `csv` 用 `Convert to CP932` opener と変換スクリプトを追加する
- [x] `Makefile` の `yazi-plugins` に変換スクリプトの symlink 導線を追加する
- [x] 変換スクリプトの新規作成・上書き確認・日本語入り CP932 変換を検証する
- [x] `yazi --debug </dev/null` と TTY 再現で `csv` の候補表示を再検証する

## Review
### 2026-06-30 10:13 : yazi csv FreeOffice 化
- 原因: `text/csv` は `office` opener しか持たず、Linux の `office` が `desktopeditors` へ固定されていたため、`Shift+Enter` から `FreeOffice` を選べなかった
- 修正内容: `config/yazi/yazi.toml` の Linux `office` opener 表示名を `OnlyOffice` に変更し、新規 `freeoffice` opener を `/usr/share/freeoffice2024/planmaker` で追加した
- 修正内容: `text/csv` の `use` を `[ "edit", "office", "freeoffice", "reveal" ]` に変更し、CSV の候補へ `OnlyOffice` と `FreeOffice` を両方出すようにした
- 検証結果: `yazi --debug </dev/null` が 0 終了し、設定パース成功を確認した

### 2026-06-30 10:18 : yazi xlsx OnlyOffice 追加
- 原因: `xlsx` 専用の `open.rules` がなく、`Shift+Enter` で `OnlyOffice` 候補を出す設定が存在しなかった
- 修正内容: `config/yazi/yazi.toml` に `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` 用ルールを追加し、`use = [ "office", "reveal" ]` とした
- 検証結果: `yazi --debug </dev/null` が 0 終了し、設定パース成功を再確認した

### 2026-06-30 10:27 : yazi office 候補不一致修正
- 原因: `open --interactive` の候補選定で、追加した `mime` ベースの `csv` / `xlsx` ルールが実際の候補表示に効いておらず、`csv` は `$EDITOR` / `Reveal`、`xlsx` は `Open` / `Reveal` に落ちていた
- 修正内容: `config/yazi/yazi.toml` の `csv` / `xlsx` ルールを `mime` から `url = "*.csv"` / `url = "*.xlsx"` へ変更し、interactive open が拡張子ベースで確実に該当ルールへ入るようにした
- 検証結果: `yazi --debug </dev/null` が 0 終了した
- 検証結果: `/tmp/yazi-csv-test/test.csv` で `Shift+Enter` 時に `$EDITOR` / `OnlyOffice` / `FreeOffice` / `Reveal` が表示されることを TTY で確認した
- 検証結果: `/tmp/yazi-xlsx-only-test/test.xlsx` で `Shift+Enter` 時に `OnlyOffice` / `Reveal` が表示されることを TTY で確認した

### 2026-06-30 10:31 : yazi xlsx FreeOffice 優先化
- 原因: `xlsx` は `OnlyOffice` / `Reveal` のみで、通常 `open` を `FreeOffice` にしたい要件を満たしていなかった
- 修正内容: `config/yazi/yazi.toml` の `*.xlsx` ルールを `use = [ "freeoffice", "office", "reveal" ]` に変更した
- 検証結果: `yazi --debug </dev/null` が 0 終了し、設定パース成功を確認した
- 検証結果: `/tmp/yazi-xlsx-only-test/test.xlsx` で `Shift+Enter` 時に `FreeOffice` / `OnlyOffice` / `Reveal` が表示されることを TTY で確認した

### 2026-06-30 10:34 : yazi csv CP932 変換追加
- 原因: `csv` の `Shift+Enter` 候補に文字コード変換アクションがなく、CP932 版をその場で作れなかった
- 修正内容: `config/yazi/scripts/convert-csv-to-cp932.sh` を追加し、UTF-8 CSV を `sample.cp932.csv` へ `iconv` 変換する処理を実装した
- 修正内容: 変換先が既に存在する場合は `Overwrite ...? [y/N]:` で確認し、`y` / `yes` のときだけ `mv -f` で上書きするようにした
- 修正内容: `config/yazi/yazi.toml` に `convert_cp932` opener を追加し、`*.csv` の候補順を `$EDITOR` / `OnlyOffice` / `FreeOffice` / `Convert to CP932` / `Reveal` に更新した
- 修正内容: `Makefile` の `yazi-plugins` に `convert-csv-to-cp932.sh` の symlink 作成を追加した
- 検証結果: `make -n yazi-plugins -o yazi` で `convert-csv-to-cp932.sh` の symlink 作成コマンドが出力されることを確認した
- 検証結果: `yazi --debug </dev/null` が 0 終了し、設定パース成功を確認した
- 検証結果: `/tmp/cp932-test/sample.csv` から `/tmp/cp932-test/sample.cp932.csv` が生成され、`iconv -f CP932 -t UTF-8` で内容を復元できることを確認した
- 検証結果: 既存 `/tmp/cp932-test/sample.cp932.csv` に対して上書き確認が表示され、`y` 入力後に上書き完了することを確認した
- 検証結果: `/tmp/cp932-ja-test/sample.csv` の日本語入りデータで `sample.cp932.csv` が生成され、`file -bi` が `charset=unknown-8bit`、`iconv -f CP932 -t UTF-8` で `あ` を復元できることを確認した
- 検証結果: `/tmp/yazi-csv-convert-test/sample.csv` で `Shift+Enter` 時に `$EDITOR` / `OnlyOffice` / `FreeOffice` / `Convert to CP932` / `Reveal` が表示されることを TTY で確認した
