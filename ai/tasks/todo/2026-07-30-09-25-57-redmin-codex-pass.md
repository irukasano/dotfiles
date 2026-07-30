## HLD

### 2026-07-30 09:25 : redmin env codex pass dependency
- 目的: `tmux` の `Alt+p, c` で起動する `codex` が `redmin` 環境では `pass` エラーになる原因を特定し、`github` 参照を不要にするための対応方針を整理する
- 変更対象: 調査結果と対応方針の整理、および必要なら後続実装で触る候補ファイルの特定
- 非変更対象: まだコード変更は行わない。`redmin` 連携機能は追加しない
- 入出力:
  - 入力: 既存の `tmux`/`codex` 起動設定、`gh`/`pass` ラッパー、ユーザー要件
  - 出力: 根本原因、切替案、推奨案、未確定事項
- 運用方法: まず既存設定を調査し、実装判断に必要な分岐点を明文化してユーザー確認を取る
- 失敗時挙動: 原因や切替点が特定できなければ、追加で必要な一次情報を明示する
- 既存機能への影響: 調査のみの段階ではなし。後続実装では GitHub 環境の `codex-with-gh` 導線へ影響する可能性がある
- 調査結果:
  - `config/tmux/bin/codex-pane.sh` は `codex` を直接呼ばず、常に `~/dotfiles/bin/codex-with-gh` を起動する
  - `bin/codex-with-gh` は引数に関係なく起動直後に `gh --ensure-auth` を実行する
  - `bin/gh` は `GH_TOKEN` がなければ `pass` を必須とし、`pass` 不在時点で即失敗する
  - よって `redmin` 環境で GitHub を使わなくても、Codex 起動前処理の都合で `pass` 依存が顕在化している
- 未確定事項:
  - `git remote` 判定を `tmux` 側で行うか、`codex-with-gh` 側で行うか
  - 複数 remote がある repo で `github` と非 `github` が混在した場合の扱い
- ユーザー確認が必要な項目:
  - 判定ルール:
    - `git remote` が GitHub を含む: 現状どおり GitHub 認証付きで起動
    - `git remote` がない: GitHub 認証なしで起動
    - `git remote` が GitHub ではない: GitHub 認証なしで起動
  - 複数 remote がある場合、`origin` だけを見るか、全 remote の URL を見るか

## Plan

### 2026-07-30 09:25 : redmin env codex pass dependency
- [x] `config/codex/AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] `tmux` の `Alt+p, c` 起動経路と `codex` ラッパーの依存関係を確認する
- [x] 根本原因と切替案を `## HLD` に反映して、ユーザー確認事項を整理する
- [x] 判定仕様を確定する
- [x] `config/tmux/bin/codex-pane.sh` で `origin` remote を見て launcher を分岐する
- [x] GitHub origin / 非 GitHub origin / remote なし の各ケースで起動コマンド選択を検証する
- [x] Review に実装結果を記録する

## Review

### 2026-07-30 09:25 : redmin env codex pass dependency
- 原因:
  - `Alt+p, c` は `config/tmux/tmux.conf` の `pane_mode c` から `config/tmux/bin/open-codex-pane.sh` を呼ぶ
  - `open-codex-pane.sh` は対象 pane の `#{pane_current_path}` を維持したまま `config/tmux/bin/codex-pane.sh` を新規 pane で実行する
  - `codex-pane.sh` は常に `~/dotfiles/bin/codex-with-gh` を起動する
  - `bin/codex-with-gh` は無条件で `gh --ensure-auth` を実行する
  - `bin/gh` は `GH_TOKEN` 未設定時に無条件で `pass` と `github/cli-token` を要求する
  - そのため、GitHub を使わない `redmin` 環境でも `Alt+p, c` だけで `pass` 依存が発火する
- 切替案候補:
  - tmux 側で launcher を分岐する
  - `codex-with-gh` 側で GitHub 不要時は素通しする
  - `bin/gh` 側で `--ensure-auth` だけ条件付き no-op にする
- 懸念:
  - `bin/gh` を広く緩めると、他の `gh` 呼び出しまで GitHub 認証確認をすり抜ける可能性がある
  - repo remote 判定にすると、git 管理外ディレクトリや複数 remote の扱いを決める必要がある
- 実装:
  - `config/tmux/bin/codex-pane.sh` に `origin` remote 判定を追加し、`origin` URL に `github.com` を含むときだけ `~/dotfiles/bin/codex-with-gh` を使うようにした
  - `git` がない、git 管理外、`origin` remote がない、`origin` が GitHub 以外、の各ケースでは素の `codex` を起動するようにした
- 検証:
  - `bash -n config/tmux/bin/codex-pane.sh` が成功した
  - スタブ launcher を使い、`origin=git@github.com:example/repo.git` の repo では `launcher=with-gh` になることを確認した
  - スタブ launcher を使い、`origin=ssh://git@example.redmin.local/project/repo.git` の repo では `launcher=plain` になることを確認した
  - スタブ launcher を使い、`origin` remote がない repo では `launcher=plain` になることを確認した
  - `git diff --check -- config/tmux/bin/codex-pane.sh ai/tasks/todo/2026-07-30-09-25-57-redmin-codex-pass.md` が成功した
