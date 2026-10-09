# Cross-repository lesson index

## HLD

### 2026-10-09 09:34 : 他リポジトリでの lesson SQLite 索引

- 目的: lesson を使用する各リポジトリで、`AI_BASE_DIR/tasks/lessons.md` を正本のまま、同じディレクトリに `lessons.sqlite` を初期化する。
- 現状確認: `codex-lesson` は各リポジトリの `AI_BASE_DIR/tasks/lessons.md` を正本とし、同じ場所へ `lessons.sqlite` を生成できる。しかし `make codex-lesson` は dotfiles の `AI_BASE_DIR=ai` にしか `sync` を実行せず、skill には他リポジトリで初期化する手順がない。
- 変更対象: `config/codex/bin/codex-lesson` の初期化・診断 CLI、`config/codex/skills/lesson/SKILL.md` の利用手順、対応する fixture テスト。必要なら `Makefile` の導入時呼出し。
- 非変更対象: Markdown を正本とする方式、SQLite のリポジトリごとの保存先、既存 lesson の移行方式、ユーザー共通DB・リポジトリ横断検索。
- 入出力: `init` は対象リポジトリの `AI_BASE_DIR/tasks/lessons.md`（未作成なら空の lesson 集合）を入力に、`AI_BASE_DIR/tasks/lessons.sqlite` を生成する。`init` と既存の `sync` は、同一の索引生成処理を利用する。`check` はベクトル依存・モデル・そのリポジトリの索引の利用可否を報告する。
- 運用方法: lesson skill は各リポジトリで最初に `check` を実行する。モデルとベクトル依存が利用でき、SQLite 索引だけが未初期化なら `init` を実行してから検索・追加を行う。モデルまたは依存が利用できない場合は初期化を試行せず、Markdown-only の既存経路を使う。SQLite はリポジトリ間で共有しない。
- 失敗時挙動: `init` はモデルまたはベクトル依存が利用できない場合、SQLite を作成・更新せず利用不可を明示する。索引作成自体の失敗時も Markdown を変更・削除しない。
- 既存機能への影響: `sync` は後方互換のため維持し、`init` と共通の索引生成処理を呼ぶ。`add` 後の同期は従来どおり対象リポジトリの SQLite に反映する。
- 未確定事項: なし。
- ユーザー確認が必要な項目: `sync` を残したまま `init` を追加し、モデル不在時は SQLite を一切操作しないこと。

## Plan

### 2026-10-09 09:34 : 他リポジトリでの lesson SQLite 索引

- [x] HLD のリポジトリ単位の索引、`check`→必要時`init` の手順、`sync` との共通化、およびモデル不在時の非処理について合意を得る。
- [x] lesson skill を再読し、ユーザー修正を Review に記録して lesson を追加済みであること、最終時に `check` と検索または Markdown 照合が必要であることを確認する。
- [x] `check` がベクトル依存・モデルに加え、対象リポジトリの SQLite 索引の利用可否を JSON で報告するようにする。
- [x] `init` を追加し、既存 `sync` と同じ索引生成処理を呼び出す。モデルまたはベクトル依存が利用できない場合は SQLite を変更しない。
- [x] 導入 target は既存 `sync` ではなく `init` を使い、対象リポジトリの初期 SQLite を生成してから診断する。
- [x] lesson skill に、各リポジトリで `check` を確認し、ベクトル環境が利用可能かつ索引だけが未初期化の場合に `init` する手順を追加する。ベクトル環境が利用不可なら Markdown-only 経路を維持する。
- [x] fixture に、モデル不在時の `init` が SQLite を作成しないこと、利用可能な環境で `check`→`init` が SQLite と検索可能な索引を作ることを追加する。
- [x] Python 構文、シェル構文、fixture、Makefile dry-run、実モデルによる `check`・`init`・`sync`・`search`、差分検査を実行する。
- [x] lesson による最終回答照合を実行し、Review に結果を記録する。

## Review

### 2026-10-09 09:34 : 他リポジトリでの lesson SQLite 索引

- ユーザー指摘: dotfiles では `make codex-lesson` により SQLite DB を作成するが、他のリポジトリで lesson を使う場合は Markdown のままになる。
- 原因: 初期化コマンドが dotfiles の `AI_BASE_DIR=ai` に対してのみ `sync` を実行し、他リポジトリを登録・検出・同期する仕組みがない。
- ユーザー修正: SQLite は各リポジトリの `ai/` 配下に置く。skill 手順で `check` のエラー時に `init` する流れにし、`init` が SQLite を生成する。
- 修正された原因認識: 問題は索引の集約不足ではなく、リポジトリごとの初期化を skill が実行しないことだった。
- ユーザー確認: 既存の DB 作成処理を `init` と共通化する。モデルがない場合は初期化処理を行わない。
- 修正内容: `check` に `index_available` と `index_reason` を追加し、対象リポジトリの SQLite が存在し必要なテーブルを読み取れるかを診断可能にした。`init` と既存 `sync` は同じ `sync_index()` を呼ぶ。モデル取得は DB を開く前に実行するため、モデル・依存が利用できない `init` は SQLite を作成・変更しない。`make codex-lesson` は `init` 後に `check` する。
- skill 更新: 各リポジトリで `check` を読み、ベクトル環境が利用可能で索引のみ未初期化なら `init`、ベクトル環境が利用不可なら `init` / `sync` を行わず Markdown-only 経路を使う手順を追加した。
- 検証: `python3 -m py_compile config/codex/bin/codex-lesson`、`bash -n ai/tasks/workspace/test-codex-lesson.sh`、`make -n codex-lesson`、`git diff --check` が成功した。fixture はモデル不在で `init` が非ゼロ終了し SQLite が作られないこと、実モデルで未初期化の `check` が `index_available: false`、`init` 後の `check` が `true`、検索が成功することを確認した。実環境でも `check` が両方 `true`、`init`・互換 `sync`・検索が成功した。
- 最終 lesson 照合: `check` は `vector_available: true` と `index_available: true` を返した。最終回答内容で上位 5 件を検索し、今回の索引配置 lesson と前回の「診断と初期化を分離する」を確認した。前者にはリポジトリごとの SQLite を維持する形で、後者には `check` と副作用を持つ `init` を分離する形で従った。runtime config の実バイナリ検証も、実際の CLI で `check`、`init`、`sync`、`search` を実行して満たした。認証・タスク記録の残りの結果は本変更に固有の追加措置を要しない。
