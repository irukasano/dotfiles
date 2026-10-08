# Codex lesson initial index

## HLD

### 2026-10-08 17:33 : 初期導入時の lesson SQLite 索引

- 目的: `make codex-lesson` を初期導入した直後に、指定済みのモデルキャッシュを確実に利用して `AI_BASE_DIR/tasks/lessons.sqlite` を生成する。
- 変更対象: `Makefile` の `codex-lesson` target、`config/codex/bin/codex-lesson` の venv 判定・モデルキャッシュ設定・索引同期用 CLI、および初期化を再現する fixture テスト。
- 非変更対象: `lessons.md` の正本性、既存 lesson の移行方式、モデル名、DB の保存先、通常の `check` の診断専用という責務。
- 入出力: セットアップは `~/.codex/lesson/huggingface` をモデルキャッシュとして使用し、既存 `AI_BASE_DIR/tasks/lessons.md` の内容（空でも可）から SQLite 索引を生成する。`check` は従来どおり JSON 診断だけを出力する。
- 運用方法: 索引再生成は明示的な `sync` サブコマンドとして提供し、`make codex-lesson` は依存導入・モデル取得・`check`・`sync` の順に実行する。
- 失敗時挙動: モデル・ベクトル依存・索引作成のいずれかが失敗したら target を失敗終了する。`check` の利用可否表示だけでは成功とみなさない。
- 既存機能への影響: `add` の既存同期処理は維持する。初期導入後は空または既存 lesson を反映した検索可能な SQLite が追加で存在する。
- 未確定事項: `sync` を公開 CLI として追加すること。
- ユーザー確認が必要な項目: 上記の `sync` サブコマンド追加と、`check` の責務を変更しない方針。

#### 2026-10-08 17:33 : venv 再実行判定の再計画

- 問題: `use_lesson_venv()` は `sys.executable.resolve()` と venv の Python 実体を比較する。標準 venv では両方がシステムPython実体へ解決されるため、venv 外からの実行を誤って「venv 内」と判断する。その結果、セットアップの `check` / 新設する `sync` は `sqlite_vec` などを持たないシステムPythonで実行されうる。
- 変更対象の追加: `use_lesson_venv()` を、実行ファイルのシンボリックリンク先ではなく Python の仮想環境情報に基づいて判定するよう修正する。
- 非変更対象: venv の配置、依存導入方式、外部から渡された `HF_HOME` の優先順位。
- 入出力・運用方法: `~/.codex/lesson/.venv/bin/python` が存在し、現在のプロセスがその venv に属さない場合だけ、同 venv で補助コマンドを再実行する。
- 失敗時挙動: venv が未作成なら現在どおり現在の Python で Markdown-only の操作を許容する。venv が存在する場合、再実行に失敗すればコマンドを失敗終了する。
- 既存機能への影響: 直接実行、Makefile 経由、lesson skill 経由のいずれも、導入済み venv の依存とモデルキャッシュを一貫して使用する。
- 未確定事項: なし。
- ユーザー確認が必要な項目: この venv 判定修正を今回の初期化不具合の修正範囲に含めること。

#### 2026-10-08 17:33 : ベクトル検索の検証不能に関する再計画

- 問題: 実モデルで `sync` 後に `search` を実行すると、`sqlite-vec` が近傍検索に必須とする `LIMIT` または `k = ?` の制約がないため失敗する。SQLite ファイルの作成だけでは初期索引が実用可能であることを検証できない。
- 変更対象の追加（提案）: `command_search()` の `vec0` 問合せへ近傍件数を明示し、既存仕様どおり上位 5 件を返す。
- 非変更対象: 検索結果の JSON 形式、上位件数、モデル、DB スキーマ。
- 入出力・運用方法: `search` は現在どおり最大 5 件の JSON 配列を返し、初期 `sync` 後の DB に対しても検索できる。
- 失敗時挙動: DB 未初期化・依存未導入時の既存エラーは維持する。SQL・拡張エラーは非ゼロ終了する。
- 既存機能への影響: 導入済み DB の検索が `sqlite-vec` の要求する実行可能な問合せになる。
- 未確定事項: なし。
- ユーザー確認が必要な項目: この既存検索不具合を、初期導入の end-to-end 検証に必要な最小修正として今回の範囲に含めること。

### 2026-10-08 17:33 : lesson 初期化修正のコミットと push

- 目的: 検証済みの lesson 初期化修正と記録を現在の `master` ブランチにコミットし、`origin` へ push する。
- 変更対象: このセッションで変更した Makefile、補助コマンド、fixture、lesson、タスク記録。
- 非変更対象: 変更対象外の作業ツリー、Git 履歴の書換え、リモートブランチの強制更新。
- 運用方法: 差分検査後に通常コミットを作成し、`git push origin master` を実行する。
- 失敗時挙動: push が失敗した場合はローカルコミットを保持し、リモートへ強制操作をしない。
- ユーザー確認: 2026-10-08 に commit と push を依頼。

## Plan

### 2026-10-08 17:33 : 初期導入時の lesson SQLite 索引

- [x] HLD の `sync` サブコマンド追加および `check` の診断専用維持について合意を得る。
- [x] HLD の venv 判定修正を修正範囲に含める合意を得る。
- [x] `lesson` skill を再読し、ユーザーの原因指摘を Review に先に記録し、完了前に `check` とベクトル検索または `rg` による最終回答照合を行うことを確認する。
- [x] `codex-lesson` の venv 所属判定を Python の仮想環境情報で判定する形に修正する。
- [x] `HF_HOME` の既定値設定を `sentence_transformers` の import 前に共通化し、外部指定値を優先する。
- [x] `sync` サブコマンドを追加し、既存 Markdown から SQLite 索引を再生成する。`check` は副作用なしとする。
- [x] `make codex-lesson` が `HF_HOME` を明示して `check` と `sync` を実行するよう変更する。
- [x] Markdown-only と導入済み venv の両方を扱える fixture テストへ更新し、後者では `sync` 後の DB 作成と検索結果を確認する。
- [x] `sqlite-vec` の近傍件数制約を満たすよう既存 `search` SQL を修正し、初期 `sync` 後の検索まで検証する。
- [x] 構文・シェル構文・fixture・Makefile dry-run・実モデルによる `check` / `sync` / `search`・差分検査を実行する。
- [x] Review に原因、修正、検証、lesson 最終回答照合を記録し、ユーザー指摘から再利用可能な lesson を保存する。

### 2026-10-08 17:33 : lesson 初期化修正のコミットと push

- [x] 作業ツリー、対象ブランチ、リモート、差分検査を確認する。
- [x] 変更を通常コミットし、`origin/master` へ push する。

## Review

### 2026-10-08 17:33 : 初期導入時の lesson SQLite 索引

- 原因調査: `HF_HOME` の import 後設定と、`check` に索引生成の副作用がないことに加え、venv Python のシンボリックリンク先比較により、導入済み venv への再実行が抑止されることを確認した。
- 検証中の追加発見: 実モデルでの初期索引生成後、`sqlite-vec` の近傍件数制約がない既存 SQL により `search` が失敗した。初期化の end-to-end 検証を妨げるため、修正範囲への追加確認が必要となった。
- ユーザー指摘（一次情報）: セットアップはモデル取得時にだけ `HF_HOME` を指定し、続く `check` には渡していなかった。また `sentence_transformers` の import 後に `HF_HOME` を設定していたため、既定キャッシュを参照していた。さらに `check` は DB を作成せず、DB 作成・同期は add 側だけにあった。
- 修正内容: モデルキャッシュ設定を import 前の共通関数にし、Makefile からも `check` と `sync` に明示的に渡した。`sync` を追加して初期索引生成を `check` から分離し、Makefile の導入手順に組み込んだ。venv 判定は実行ファイルのリンク先比較から `sys.prefix` 比較へ変更した。`search` は `sqlite-vec` が必須とする `k = 5` 制約を使うよう修正した。
- 検証: `python3 -m py_compile config/codex/bin/codex-lesson`、`bash -n ai/tasks/workspace/test-codex-lesson.sh`、fixture、`make -n codex-lesson`、`git diff --check` が成功した。fixture は venv を隠した Markdown-only 経路と、導入済み venv の `check`、`sync`、SQLite 作成、検索結果・Review 参照を確認した。
- lesson 記録: `codex-lesson --ai-base ai add` で「セットアップの診断と初期化を分離する」を保存し、`indexed: true` を確認した。
- 最終 lesson 検証: `codex-lesson --ai-base ai check` は `vector_available: true`。最終回答案でベクトル検索した上位 5 件を確認した。今回の lesson と「runtime config の実バイナリ検証」は適用対象であり、前者は本 Review の一次情報へ戻って照合し、後者は実際の補助コマンド・実モデルの fixture を実行して満たした。残る 3 件は UI、管理済み設定、GPG 認証を対象とし非該当。追加修正は不要と判断した。

### 2026-10-08 17:33 : lesson 初期化修正のコミットと push

- `cae4399 fix(codex): initialize lesson vector index` を作成した。push は次に実行する。
