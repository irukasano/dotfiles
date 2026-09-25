## HLD

### 2026-09-07 00:00 : tmux-gh リポジトリ別キャッシュ
- 目的: `bin/tmux-gh.sh` の一覧・プレビューキャッシュを、実行対象リポジトリごとに分離し、別リポジトリの GitHub issue / PR が表示されることを防ぐ。
- 調査結果: 現行 `cache_dir()` は `/tmp/tmux-gh-${USER}` を常に返すため、`issue` / `pr` / `file` の一覧と各 preview は、実行ディレクトリにかかわらず同一パスを共有する。
- 変更対象候補: `bin/tmux-gh.sh` のキャッシュディレクトリ算出、およびこれを使う一覧・preview・削除処理。
- 非変更対象: GitHub 取得条件、キャッシュ TTL（300 秒）、tmux/worktree 作成フロー、既存の `/tmp` キャッシュを削除する運用。
- 入出力: Git top-level directory の絶対パスを入力に、worktree ごとに固有の `/tmp` 配下キャッシュパスを出力する。issue / PR / file 一覧と preview は同一 worktree 内では従来どおり再利用する。
- 運用方法: `tmux-gh.sh` の通常起動および fzf からの内部サブコマンドが、同じリポジトリ識別子を用いて同一キャッシュを参照する。
- 失敗時挙動: Git top-level directory を取得できない場合はエラー終了し、キャッシュを読書きしない。誤って別リポジトリのキャッシュを共有しないことを優先する。
- 既存機能への影響: 修正後、既存の共通キャッシュは参照されず、リポジトリごとに最初の一度だけ再取得される。
- 未確定事項: なし。
- ユーザー確認が必要な項目: なし。
- ユーザー確認: 2026-09-07 に Git top-level directory ごと（worktree ごと）にキャッシュを分離する方針を合意。
- ユーザー確認: 2026-09-07 に、リポジトリ外ではエラー終了しキャッシュを読書きしない方針を合意。
- ユーザー確認: 2026-09-07 に、top-level directory の絶対パスを `cksum` の固定長識別子に変換してキャッシュディレクトリ名に使う方針を合意。

## Plan

### 2026-09-07 00:00 : tmux-gh リポジトリ別キャッシュ
- [x] 関連実装、既存タスク記録、レッスン、作業ツリー状態を確認する。
- [x] キャッシュを Git top-level directory ごと（worktree ごと）に分離することを合意する。
- [x] リポジトリ外ではエラー終了しキャッシュを読書きしないことを合意する。
- [x] キャッシュディレクトリ名に `cksum` の固定長識別子を使うことを合意する。
- [x] 使用可能な専用スキルがないことを確認する。
- [x] `git rev-parse --show-toplevel` と `cksum` によりキャッシュキーを算出する。
- [x] 一覧・preview・削除を含む全キャッシュ経路へ worktree 固有のキャッシュディレクトリを適用する。
- [x] fixture を追加し、異なる worktree 間の一覧・preview 分離、同一 worktree 内の再利用、リポジトリ外のエラーを検証する。
- [ ] 合意後、使用するスキルの有無を再確認し、必要なら定義を再読して必須手順・制約・検証を本 Plan へ転記する。
- [ ] キャッシュキー算出を実装し、一覧・preview・削除を含む全キャッシュ経路へ適用する。
- [ ] fake `git` / 一時キャッシュディレクトリによる異なるリポジトリ間の分離、同一リポジトリ内の再利用、識別子取得失敗時を検証する。
- [x] `bash -n bin/tmux-gh.sh`、`git diff --check`、基準ブランチ `master` との差分確認を実施し、Review に原因・変更・検証結果を記録する。

#### 2026-09-07 00:00 : 検証計画の再計画
- 変更理由: 初回 fixture 実行で、`ai/tasks/workspace` からプロジェクトルートへ戻る相対パスが一階層不足し、`ai/bin/tmux-gh.sh` を参照して失敗した。
- 変更内容: fixture のプロジェクトルート算出を `../../..` に訂正してから、同一の分離・再利用・リポジトリ外エラー検証を再実行する。
- 変更なし: 本体のキャッシュ分離仕様、変更対象、失敗時挙動、検証観点。

#### 2026-09-07 00:00 : 基準ブランチ確認による検証計画の再計画
- 変更理由: `main` はこのリポジトリに存在せず、`git diff main --check` は revision 解決エラーで失敗した。
- 変更内容: 現在の基準ブランチである `master` を比較対象に置き換える。
- 変更なし: 実装仕様と他の検証手順。

## Review

### 2026-09-07 00:00 : tmux-gh リポジトリ別キャッシュ
- 原因: `cache_dir()` がユーザー名だけから `/tmp/tmux-gh-$USER` を返し、一覧は mode、preview は mode と item ID だけをキーにしていた。そのため別リポジトリでも同じキャッシュを再利用し、同じ issue / PR 番号の preview も衝突していた。
- 修正内容: `git rev-parse --show-toplevel` で取得した worktree の絶対パスを `cksum` の識別子へ変換し、`/tmp/tmux-gh-$USER/<識別子>` をキャッシュディレクトリにした。既存の一覧・preview・削除処理はすべて `cache_dir()` を経由するため、同一 worktree では従来どおり再利用しつつ、別 worktree とは分離される。リポジトリ外では明示的なエラーで終了する。
- 検証: `bash ai/tasks/workspace/test-tmux-gh-repository-cache.sh` が成功。実 Git リポジトリを模した 2 つの一時 worktree と fake `gh` により、一覧・preview が worktree ごとに各 1 回取得されること、同一 worktree では再利用されること、リポジトリ外のキャッシュ削除がエラーになることを確認した。
- 検証: `bash -n bin/tmux-gh.sh`、`bash -n ai/tasks/workspace/test-tmux-gh-repository-cache.sh`、`git diff --check`、`git diff master --check` が成功した。`main` は存在しないため、基準ブランチ `master` と比較した。
- 影響確認: 既存の共通キャッシュは参照されなくなり、各 worktree では修正後の最初の起動時のみ再取得する。既存の `.gitconfig` と `config/codex/AGENTS.md` の未関連変更には触れていない。
