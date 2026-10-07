# Codex lesson vector search

## HLD

### 2026-09-25 16:03 : Codex lesson vector search

- 目的: Codex の lesson 記録を専用 skill に分離し、再利用可能な一般則と具体例を分けて、ローカル埋め込みモデルと SQLite のベクトル検索で最終回答を検証できるようにする。
- 変更対象（候補）: `config/codex/AGENTS.md`、`config/codex/skills/lesson/` の新設 skill（通常記録・最終検証・既存 lesson 移行モード）、`config/codex/bin/` の補助スクリプト、`Makefile` の Codex 設定・依存配備、lesson の SQLite ストア、テスト。
- 非変更対象: 既存 dotfiles の動作、既存 lesson の内容・移行（方針が決まるまで）。
- 入出力（合意済み）: ユーザー指摘を入力に、一般則・適用範囲・元の具体例を含むタスク Review への参照を `lessons.md` に保存する。依存が利用可能な環境では、一般則・適用範囲・Review 参照・検索用ベクトルを別カラムで SQLite にも保存する。検索用ベクトルは `Rule` と `Scope` を連結したテキストから作成し、Review 本文は含めない。完了前には回答案を入力に、類似 lesson と一次情報へ戻れる Review 参照を含む検証結果を出力する。
- 運用方法（合意済み）: SQLite の vector 検索は `sqlite-vec` 拡張を使う。DB はプロジェクト単位で `AI_BASE_DIR/tasks/lessons.sqlite` に置く。skill は `config/codex/skills/lesson/` で管理し、`make codex-settings` で `~/.codex/skills/lesson` にリンクする。Docker は使わない。`sqlite-vec`、ローカル埋め込み用 Python 仮想環境およびモデルは `make codex-lesson` で同時に導入し、通常の `codex-all` には含めない。lesson 保存時に一般則をローカルでベクトル化してメタデータとともに SQLite へ保存する。完了前に回答案を同じモデルでベクトル化し、SQLite の近傍検索結果を用いて自己検証・修正を反復する。埋め込みモデルは CPU で動く `intfloat/multilingual-e5-small`（384 次元、MIT）を使う。
- 失敗時挙動（合意済み）: skill が簡易な機械チェックで Python、`sqlite-vec`、ローカルモデルの利用可否を確認する。利用できない場合でも Markdown の lesson 記録は継続する。SQLite 検索とベクトルによる最終検証の代わりに `rg` 等で Markdown をキーワード照合して検証する。依存導入またはロードが失敗したセットアップは失敗として停止する。一方、依存を導入できない環境で skill を実行するときは Markdown-only 運用として完了可能にする。既存 lesson の移行では、原文と一般化判断を移行タスクの Review に記録してから、Review 参照付きの新規 lesson を作る。
- 既存機能への影響: `AGENTS.md` の lesson 記録手順と完了前検証手順を置換・追加する。
- 未確定事項: なし。
- ユーザー確認が必要な項目: なし。
- ユーザー確認: 2026-09-25 に `sqlite-vec` 拡張を使う方針を合意。
- ユーザー確認: 2026-09-25 に DB を `AI_BASE_DIR/tasks/lessons.sqlite` へプロジェクト単位で保存する方針を合意。
- ユーザー確認: 2026-09-25 に skill を `config/codex/skills/lesson/` で管理し、`make codex-settings` で `~/.codex/skills/lesson` へリンクする方針を合意。
- ユーザー確認: 2026-09-25 に `OPENAI_API_KEY` は利用できない旨を確認。OpenAI Embeddings API を使う設計は未合意として停止する。
- ユーザー確認: 2026-09-25 に OpenAI Embeddings API を使わず、Docker を使わないローカル埋め込み方式へ切り替える方針を合意。`sqlite-vec`、Python 仮想環境、モデルは同じセットアップで導入する。
- ユーザー確認: 2026-09-25 にローカル埋め込みモデルとして `intfloat/multilingual-e5-small` を使う方針を合意。
- ユーザー確認: 2026-09-25 に依存が導入できない環境でも lesson 運用を継続できるフォールバックが必要と確認。
- ユーザー確認: 2026-09-25 に `lessons.md` を正本、SQLite を再生成可能なベクトル索引とする方針を合意。依存がない場合は `rg` 等で `lessons.md` をキーワード照合して最終検証する。
- ユーザー確認: 2026-09-25 に既存 `AI_BASE_DIR/tasks/lessons.md` の各箇条書きを一般則として初回の SQLite 索引へ移行し、具体例は空にする方針を合意。
- ユーザー確認: 2026-09-25 に `lessons.md` と SQLite の両方へ一般則・適用範囲・Review 参照を保存し、一般則のみをベクトル検索する方針を合意。
- ユーザー確認: 2026-09-25 に最終検証ではベクトル検索の上位 5 件を確認し、agent が Review の一次情報と照合して関連性を判断する方針を合意。
- ユーザー確認: 2026-09-25 に依存導入またはロードが失敗したセットアップは失敗として停止する一方、依存を導入できない環境での skill 実行は Markdown + `rg` のみで完了可能とする方針を合意。
- ユーザー確認: 2026-09-25 に `make codex-lesson` を明示実行する独立 target とし、モデルダウンロードを伴うため通常の `codex-all` には含めない方針を合意。
- ユーザー確認: 2026-09-25 に仮想環境を `~/.codex/lesson/.venv`、モデルキャッシュを `~/.codex/lesson/huggingface` に置く方針を合意。

#### 2026-09-25 16:xx : 検索設計の再計画

- 問題: Rule だけで近傍検索して Scope を後段で除外すると、上位 5 件がすべて異なる適用範囲の lesson となり、必要な lesson を取り逃がす可能性がある。
- 再計画: SQLite の列は Rule と Scope を分離したまま、検索用ベクトル列の入力を `Rule` と `Scope` の組に変更する案をユーザーへ確認する。Review 参照および Review 本文は埋め込みに含めない。
- ユーザー確認: 2026-09-25 に一般則・適用範囲・Review 参照・検索用ベクトルを別カラムで保存し、検索用ベクトルだけは Rule と Scope を連結したテキストから作成する方針を合意。
- ユーザー確認: 2026-09-25 に `lessons.md` は一般則の短い人間向けタイトルを見出しとし、UUID を自動生成して ID として保存する方針を合意。
- ユーザー確認: 2026-09-25 に保存・索引・検索用補助スクリプトを `config/codex/bin/` で管理し、`~/.codex/bin/` へリンクする方針を合意。
- ユーザー確認: 2026-09-25 に `~/.codex/bin/` へ配備する補助コマンド名を `codex-lesson` とする方針を合意。

#### 2026-09-25 16:xx : 既存 lesson 移行の再計画

- 問題: 既存 `lessons.md` の一般則は必ずしも適切に一般化されておらず、元 Review 参照も確実に復元できない。自動移行すると、未検証の lesson を検索・検証結果へ混入させる。
- 再計画: lesson skill に既存 lesson の移行モードを設け、原文と一般化判断を移行タスクの Review に記録してから、新形式の lesson と SQLite 索引を作る方針をユーザーと合意。移行の実行契機は未確定。
- ユーザー確認: 2026-09-25 に既存 lesson は移行モードで再一般化し、原文・一般化判断を移行タスクの Review に残したうえで、新形式の lesson からその Review を参照する方針を合意。
- ユーザー確認: 2026-09-25 に既存 lesson の移行は `make codex-lesson` では実行せず、lesson skill を明示して実行する方針を合意。

#### 2026-09-25 16:xx : 移行出力先の再計画

- 問題: 既存 lesson を新形式へ移行した後、元の `lessons.md` の原文をそのまま残すか、移行 Review のみを出所とするかが未決定だった。
- 再計画: 原文を `lessons-legacy.md` として保存し、新形式の `lessons.md` には再一般化済み lesson だけを置く方針を合意。
- ユーザー確認: 2026-09-25 に移行後の旧形式 `lessons.md` 原文を `lessons-legacy.md` として残し、各原文は移行 Review にも記録する方針を合意。

#### 2026-09-25 16:xx : 新旧 lesson の共存再計画

- 問題: 明示的な既存 lesson 移行を実行するまで、旧形式の `lessons.md` が存在する。新規 lesson を同ファイルへ新形式で追記すると形式が混在し、SQLite 索引との同期が壊れる。
- 再計画: 初回の明示移行時に旧 `lessons.md` を `lessons-legacy.md` へ移し、新しい空の `lessons.md` を作る方針を合意。
- ユーザー確認: 2026-09-25 に初回の明示移行時だけ旧 `lessons.md` を `lessons-legacy.md` へ移し、新形式 `lessons.md` を開始する方針を合意。

#### 2026-09-25 16:xx : セットアップ権限の再計画

- 問題: Ubuntu 環境で `make codex-lesson YUM=apt` を実行すると、既存 `python3` target が `sudo apt install` を呼び、sudo 認証に失敗してセットアップが停止した。`python3` と `venv` 自体は既に利用可能である。
- 再計画: 既存の `python3` target を維持する。実際の Makefile 実行はユーザーが sudo 認証できる環境で行う前提とし、今回の認証失敗はテスト環境固有として許容する。
- ユーザー確認: 2026-09-25 に `make codex-lesson` の既存 `python3` target 依存を維持し、今回の sudo 認証失敗は許容する方針を合意。

## Plan

### 2026-09-25 16:03 : Codex lesson vector search

- [x] HLD の未確定事項を一件ずつ合意する。
- [x] `skill-creator` を再読し、skill は必要な `SKILL.md` と実利用する補助資源だけで構成すること、簡潔で識別しやすい frontmatter にすること、不要な scaffold/補助文書を作らないこと、変更後に `quick_validate.py` と実際の動作を検証することを確認する。
- [x] `config/codex/skills/lesson/SKILL.md` を作成し、通常の lesson 記録、完了前検証、既存 lesson 移行の 3 モードを定義する。通常記録では Rule・Scope・Review を必須にし、技術・層・状況を Scope に残し、固有名詞を一般則から除く。移行モードでは `lessons-legacy.md`、移行 Review、明示実行だけを扱う。
- [x] `config/codex/bin/codex-lesson` を実装する。UUID を自動発行し、`lessons.md` の新形式を読み書きし、Rule・Scope・Review 参照・検索用ベクトルを SQLite に分離して保存する。検索用ベクトルは Rule と Scope の結合から作り、Review 本文は含めない。`check`・`add`・`search` を提供する。
- [x] `Makefile` の `codex-settings` を、AGENTS・lesson skill・`codex-lesson` を `~/.codex` 配下へ安全にリンクする形へ拡張する。`make codex-lesson` を新設して `~/.codex/lesson/.venv`、`~/.codex/lesson/huggingface`、`sqlite-vec`、`sentence-transformers`、`intfloat/multilingual-e5-small` を導入する。`codex-all` には追加しない。
- [x] `config/codex/AGENTS.md` を更新し、ユーザーからの修正指摘の lesson 化を新 skill に委譲する。完了前に `codex-lesson check` を実行し、利用可能なら検索上位 5 件と Review を照合して指摘がなくなるまで回答を修正し、利用不可なら `rg` 等で `lessons.md` を照合する規約へ変更する。
- [x] 旧形式の `ai/tasks/lessons.md` をセットアップでは自動移行しない。初回の明示的な移行モードでだけ `lessons.md` を `lessons-legacy.md` へ移し、新しい空の `lessons.md` を作る。以後は各原文と再一般化判断を移行タスク Review に残して新形式の lesson を作ることを確認する。
- [ ] 隔離した `AI_BASE_DIR/tasks/workspace` fixture で、Markdown-only の追加・`rg` 照合、依存利用可能時の追加・SQLite ベクトル検索・Review 参照返却、既存 lesson 移行のデータ保存を検証する。Markdown-only と移行の検証は成功。ベクトル経路は `make codex-lesson` が sudo 認証で停止したため、ユーザー実行後に要確認。
- [x] `skill-creator` の `quick_validate.py`、Python 構文確認、`make -n codex-lesson`、対象ファイルの `git diff --check`、`master` との差分を確認し、Review に原因・修正内容・検証結果を追記する。

## Review

### 2026-09-25 16:03 : Codex lesson vector search

- 原因: lesson は既存の Markdown 箇条書きだけで管理され、一般則の適用範囲・元の具体例への追跡・意味検索・完了前照合ができなかった。
- 修正内容: `lesson` skill を追加し、Rule・Scope・Review 参照を UUID で対応付ける運用、ベクトル検索と `rg` フォールバック、明示的な legacy 移行モードを定義した。`codex-lesson` は Markdown の記録、SQLite + `sqlite-vec` の索引、`multilingual-e5-small` による Rule + Scope の検索、依存チェック、初回移行を提供する。
- 修正内容: `make codex-settings` は AGENTS、skill、補助コマンドを `~/.codex` へリンクする。新設の `make codex-lesson` は独立して Python 仮想環境・sqlite-vec・埋め込みモデルを導入し、`codex-all` には追加しない。
- 修正内容: `config/codex/AGENTS.md` に、lesson skill によるユーザー修正指摘の記録と、最終回答の上位 5 件ベクトル検索または `rg` 照合を追加した。
- 検証: `ai/tasks/workspace/test-codex-lesson.sh` により、旧 Markdown の `lessons-legacy.md` への退避、新形式 Markdown の UUID 付き追加、依存なしの `indexed: false`、ベクトル検索の利用不可通知を確認した。
- 検証: `bash -n ai/tasks/workspace/test-codex-lesson.sh`、Python の構文コンパイル、`quick_validate.py config/codex/skills/lesson`、`make -n codex-lesson YUM=apt`、`git diff --check` が成功した。`make codex-settings` を実行し、`~/.codex/AGENTS.md`、`~/.codex/skills/lesson`、`~/.codex/bin/codex-lesson` がリポジトリ管理ファイルへリンクされることを確認した。
- 未検証: `make codex-lesson YUM=apt` は既存 `python3` target の sudo 認証に失敗して停止した。ユーザーの実行環境では sudo 認証を前提とするため、実際の `sqlite-vec` 索引作成・ベクトル検索はセットアップ後に確認が必要。
- 最終 lesson 検証: `codex-lesson check --ai-base ai` は `sqlite_vec` 未導入を検出したため、`rg` で既存 lessons の設定生成・移行・fixture 関連の一般則を照合した。設定の安全なリンク配備、明示的な移行、fixture の安全な一時データ処理を確認し、追加修正は不要と判断した。
