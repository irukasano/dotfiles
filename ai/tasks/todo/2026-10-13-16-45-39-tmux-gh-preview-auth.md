## HLD

### 2026-10-13 16:45 : tmux-gh issue プレビューの非対話認証

- 目的: `tmux-gh.sh issue` の右側プレビューで issue 内容を取得できない原因を修正し、非対話の `gh` 呼び出しでも有効な GitHub 認証を利用できるようにする。
- 変更対象候補: `bin/gh` の非対話認証判定と、`ai/tasks/workspace` の認証フロー用テスト。
- 非変更対象: `tmux-gh.sh` の表示・キャッシュ仕様、token 保存場所、pass/GPG 鍵・設定、通常の `/usr/bin/gh` の挙動。
- 入出力: `GH_TOKEN` があれば常にそれを利用する。未設定の no-tty 呼び出しでは `pass show github/cli-token` の復号を試し、成功時は取得 token を `/usr/bin/gh` へ渡す。
- 運用方法: TTY がある通常端末では現行どおり GPG/pinentry を利用する。fzf preview など no-tty 呼び出しでは GPG agent cache のみを使う。
- 失敗時挙動: no-tty GPG 試行には `--batch --pinentry-mode error` を適用し、pinentry/curses は起動しない。cache miss、または sandbox からの agent 接続・書込み失敗などで復号できない場合は、原因を決めつけず可能性を示して非 0 終了する。既存 token が無効な場合は `/usr/bin/gh` のエラーを返す。
- 既存機能への影響: 対話シェルの `gh` と `gh --ensure-auth` の挙動は維持する。非対話実行で有効な pass 認証が使えるようになる。
- 技術判断: 提案の clear-sign probe ではなく、実際に必要な `pass show` の復号可否を先に確認する。既存の no-tty 対応履歴・テストで使っている `PASSWORD_STORE_GPG_OPTS='--batch --pinentry-mode error'` を適用し、cache がないとき pinentry を呼ばない。
- 適用範囲上の制約: Codex sandbox では `~/.gnupg` の lock file 作成が拒否され、cache が有効でも agent に接続できない場合がある。batch/no-pinentry 指定ではこの境界を回避できない。
- 未確定事項: なし。
- ユーザー確認が必要な項目: TTY の通常 pinentry 維持、no-tty の batch/cache-only 試行、失敗時は原因を決めつけず終了、で合意済み。

## Plan

### 2026-10-13 16:45 : tmux-gh issue プレビューの非対話認証

- [x] 既存 `bin/gh` の認証分岐、no-tty テスト、過去の pinentry 抑止仕様と lesson を確認する。
- [x] no-tty 時に `PASSWORD_STORE_GPG_OPTS` へ `--batch --pinentry-mode error` を付け、`GH_TOKEN` 不在でも pass 復号を試す仕様を確定する。
- [x] `bin/gh` から GH_TOKEN のみを要求する no-tty 早期終了を外し、復号失敗時は cache を対話端末で有効化する具体的な案内を出す。
- [x] `ai/tasks/workspace/test-gh-no-tty.sh` を現仕様に更新し、cache hit 相当で成功すること、cache miss 相当で失敗し UI を呼ばないこと、token を出力しないことを確認する。
- [x] shell 構文、関連認証テスト、差分を確認する。
- [x] Review に原因、変更、検証を記録し、適用対象の lesson を再照合する。

## Review

### 2026-10-13 16:45 : tmux-gh issue プレビューの非対話認証

- 原因: `bin/gh` は `GH_TOKEN` 未設定の no-tty 呼び出しを `pass show` より先に拒否していた。そのため fzf のプレビュー子プロセスは、GPG agent cache が有効でも復号を試せなかった。
- 修正内容: no-tty 時に `PASSWORD_STORE_GPG_OPTS` へ `--batch --pinentry-mode error` を追加し、`GH_TOKEN` がなくても `pass show github/cli-token` を試すよう変更した。既存 cache で復号できる場合だけ後続の gh を実行し、復号できない場合は cache 未利用または agent 接続不可の可能性を示して終了する。no-tty fixture は成功・失敗・`gh --version` 実行、option 付与、token 非出力を確認する。
- 検証結果: `sh -n bin/gh`、`sh -n ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-pass-bootstrap.sh`、`git diff --check` は成功。fixture 上で復号成功・失敗分岐を確認した。実環境 `pass show` はこの実行 sandbox から `~/.gnupg` への lock file 作成が read-only で拒否され、gpg-agent に接続できなかったため、実 cache hit/miss は未検証。no-tty では pinentry を起動せず、復号不能時は終了する。TTY ありでの通常 pinentry は現行どおり維持する。
- lesson 照合: `codex-lesson --ai-base ai check` で vector index を確認し上位 5 件を検索。no-TTY で pinentry を抑止する Rule と、cache-only 成功を cache miss の対話成功と混同しない Rule を適用。Codex sandbox の GPG home 書込み制限を確認し、実機の通常コンソール cache 復号は未検証と明記する。
