## HLD

### 2026-11-25 09:35 : yazi Shift+Enter メニューに Copy path を追加
- 目的: Yazi の `Shift+Enter` で開く対話式「開く」メニューに `Copy path` を追加し、全ファイル種別でフルパスをコピーできるようにする
- 変更対象: `config/yazi/yazi.toml` の opener とすべての `open.rules`、`config/yazi/scripts/copy-path.sh`、`Makefile` の `yazi-plugins` スクリプト symlink
- 非変更対象: `config/yazi/keymap.toml` のキー割り当て、既存の opener の動作、`c c` による Yazi 標準 `copy path` アクション
- 入出力:
  - 入力: ファイル種別を問わず、Yazi で `Shift+Enter` を押してメニューから `Copy path` を選ぶ
  - 出力: 選択中のファイルすべてのフルパスを1行ずつクリップボードへコピーする。選択がなければカーソル上のファイルのフルパスをコピーする
- 運用方法: Linux 上で `wl-copy` を優先し、利用できない場合は `xclip` を使用する。`config/yazi/scripts/copy-path.sh` を `~/.config/yazi/scripts/` に symlink する
- 失敗時挙動: どちらの clipboard command も使えない場合はスクリプトを失敗終了し、クリップボード内容は保証しない
- 既存機能への影響: `Shift+Enter` の既存 opener 候補と `<Enter>` の通常オープンは維持する。全 rule のメニューに `Copy path` が加わる
- 未確定事項: なし
- ユーザー確認が必要な項目: この改訂 HLD の承認

## Plan

### 2026-11-25 09:35 : yazi Shift+Enter メニューに Copy path を追加
- [x] `open.rules` の全ルールと既存スクリプト／symlink のパターンを確認する
- [x] clipboard コマンドを優先順に選び、引数のパスを改行区切りで渡す `copy-path.sh` を追加する
- [x] `yazi.toml` に Linux 用 `Copy path` opener を定義し、全 `open.rules` に加える
- [x] `Makefile` の `yazi-plugins` で新スクリプトの symlink を作る
- [x] Yazi の設定パース、シェル構文、両 clipboard backend の出力を一時コマンドで検証する
- [x] 差分と `git diff --check` を確認し、Review に原因・変更・検証結果を記録する

## Review

### 2026-11-25 09:35 : yazi Shift+Enter メニューに Copy path を追加
- ユーザー修正: 依頼は `Shift+Enter` の対話式メニューへ `Copy path` を追加することだった。最初の解釈ではキーに直接コピー動作を割り当てる仕様としていた
- 原因: `Shift+Enter` の対話式「開く」メニューは `open.rules` の opener 一覧から生成され、既存設定にはパスコピー用 opener がなかった
- 修正内容: Linux 用 `Copy path` opener と `config/yazi/scripts/copy-path.sh` を追加し、12件すべての `open.rules` に加えた。`wl-copy` を優先し、未導入時は `xclip` を使う。`Makefile` の `yazi-plugins` でスクリプトを配置する symlink を追加した
- 検証結果: `yazi --debug </dev/null` が終了コード 0 で設定を読み込んだ。Python TOML 検証で全12ルールへの追加と `Shift+Enter` の既存割り当てを確認した。`bash -n` と `git diff --check` が成功した
- 検証結果: clipboard を模擬した一時コマンドで、空白を含む複数パスが `wl-copy` / `xclip` に1行ずつ渡ることを確認した。`make -n yazi-plugins` に新しい symlink コマンドが含まれる
- 配置結果: `~/.config/yazi/scripts/copy-path.sh` からリポジトリ内スクリプトへの symlink を作成した
- Lesson: ユーザー修正から「既存メニューへの項目追加をキー割り当てと混同しない」を記録した。`codex-lesson check` で vector index を確認し、上位5件を照合した。Yazi 設定の非対話検証を適用し、残りは今回の Scope と無関係と判断した
