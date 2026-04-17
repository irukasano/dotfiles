# Todo

## Plan

### 2026-04-16: tmux pane send-to-next-tab

- [x] `pane_mode` の既存ガイドとキーバインド配置を確認する
- [x] `Alt-p, t` で現在ペインを次のタブへ送るバインドを追加する
- [x] ガイド表示に `[t] send to next tab` を resize と find の間へ追加する
- [x] tmux 設定の構文と一時サーバー上の挙動を検証する

### 2026-04-16: git commit template fallback and OSC52 clipboard

- [x] `git commit-diff` の `codex exec --output-last-message` 失敗時の挙動を確認する
- [x] `bin/git-commit-template.sh` で Codex 出力ファイル未生成を安全に扱う
- [x] 構文確認と失敗経路の簡易実行で、`cat: /tmp/...codex` が出ないことを検証する
- [x] CP932 の staged diff が混ざっても Codex prompt が UTF-8 として読めるようにする
- [x] CP932 差分を含む一時 Git repo で `git commit-diff` の差分テンプレート生成を検証する

- [x] `set-clipboard off` 後の OSC52 ヤンク経路を確認し、原因を特定する
- [x] tmux copy-mode の `osc52.sh` 呼び出しを端末へ届く形に修正する
- [x] 構文確認と出力確認で、OSC52 シーケンスが生成されることを検証する

### 2026-04-16: gh credential and Codex integration

- [x] `bin/gh` のトークン保存フローを確認し、`pass` を直接叩かずに更新できる導線を決める
- [x] `bin/gh` にトークン更新サブコマンドを追加し、対話・非対話の両方で更新できるようにする
- [x] 構文確認とヘルプ出力の確認で、既存の `gh` ラッパー挙動を壊していないことを検証する

- [x] `gh` セットアップの責務を整理し、`.gitconfig` ではなく `~/.gitconfig.local` に credential helper を入れる方針を反映する
- [x] `Makefile` の `gh` タスクへ GitHub / gist 用 credential helper 設定を追加する
- [x] 変更差分と `make -n gh` の出力を確認し、`.gitconfig` を触らないことを検証する

- [x] `bin/tmux-gh.sh` の issue ブランチ既定値で、ラベルなし時のフォールバック文言を `misc` から `no-label` へ変更する
- [x] 影響範囲を確認し、`bin/tmux-gh.sh` の構文検証を行う

- [x] `bin/codex-with-gh` の要件を定め、Codex 用セットアップ導線の変更点を確認する
- [x] `bin/codex-with-gh` を追加し、`make codex` で `~/bin` にリンクする
- [x] スクリプト内容と Makefile 導線を確認して、期待どおりの起動経路になっていることを検証する
- [x] `bin/gh` を非対話 fail-fast にして、MCP から pinentry へ進まないようにする
- [x] `gpg-agent` キャッシュを長めに保持し、`codex-with-gh` の事前認証で非対話 `pass show` が通る導線へ切り替える
- [x] `layout-dev` の右ペイン起動導線を確認し、`bin/codex-with-gh` を使う変更方針を決める
- [x] tmux 右ペインの Codex 起動を `bin/codex-with-gh` 経由へ切り替える
- [x] 変更差分とシェル構文を確認して、既存の終了後復帰挙動を壊していないことを検証する

### 2026-04-16: todo.md conflict and task-log convention

- [x] `ai/tasks/todo.md` の conflict 内容を確認し、両側を残す解決方針を決める
- [x] `todo.md` の衝突箇所をタスク単位のセクションへ統合する
- [x] `config/codex/AGENTS.md` の `todo.md` 運用をタスク単位追記へ明文化する
- [x] `ai/tasks/lessons.md` に今回の指摘パターンを記録する
- [x] conflict 解消状態と差分を検証する

### 2026-04-17: tmux 3.5a OSC52 clipboard

- [x] 既存の tmux copy-mode と `osc52.sh` の経路を確認する
- [x] tmux 3.5a の `allow-passthrough` 既定値を確認する
- [x] tmux 3.3+ だけ DCS passthrough を許可する設定を追加する
- [x] tmux 設定構文と option 反映を検証する
- [x] 原因、修正内容、検証結果を Review に記録する

## Review

### 2026-04-16: tmux pane send-to-next-tab

- [x] `Alt-p, t` のペイン移動追加について、変更内容と検証結果を記録する
- 修正内容: `config/tmux/tmux.conf` の `pane_mode` に `t` バインドを追加し、現在ペインを次のタブへ送るようにした
- 動作: 次のタブがある場合は `join-pane -t ":+"` で次タブへ追加し、現在タブが最後の場合は `break-pane` で新しいタブとして独立する
- ガイド表示: `Alt-p` の表示に `[t] send to next tab` を resize と find の間へ追加し、隣接色と被らない `colour207` を使った
- 検証: 一時 tmux サーバーで `source-file config/tmux/tmux.conf` が成功し、次タブありの `join-pane` と最後タブでの `break-pane` の両方が期待どおり動くことを確認した
- 検証: `list-keys` で `pane_mode t` と `M-p` ガイド表示が反映されていることを確認し、`git diff --check` が成功した

### 2026-04-16: git commit template fallback and OSC52 clipboard

- 原因: `codex exec --output-last-message "$OUTPUT_LAST"` が失敗して出力ファイルを作らない場合でも、直後に `cat "$OUTPUT_LAST"` を実行していたため `cat: /tmp/...codex: そのようなファイルやディレクトリはありません` で落ちていた
- 修正内容: `codex exec` の stderr を一時ファイルへ保存し、終了コードと `OUTPUT_LAST` の非空確認が成功した場合だけ生成結果を読むようにした。失敗時はエラー内容を表示し、手動編集用テンプレートにフォールバックする
- 検証: `bash -n bin/git-commit-template.sh` が成功し、fake `codex` が失敗する一時 Git repo で `cat: /tmp/...codex` を出さずに editor 経由の commit まで通ることを確認した
- 追加原因: CP932 ファイルの差分が prompt に混ざると、Codex が UTF-8 として読めず `--output-last-message` の出力ファイル未生成につながる可能性があった
- 修正内容: staged diff をテンプレートへ入れる直前に、行単位で UTF-8、CP932 の順に decode し、どちらでも読めない bytes は escape するようにした
- 検証: CP932 で `こんにちはCP932` を書いた一時 Git repo の staged diff を使い、Codex に渡る prompt が UTF-8 として読め、CP932 本文も復元されることを確認した

- 原因: `copy-pipe-and-cancel '/usr/local/bin/osc52.sh'` は選択内容を `osc52.sh` の stdin に渡すが、スクリプトの stdout に出した OSC52 シーケンスは tmux クライアント端末へ届かないため、クリップボード更新まで到達していなかった
- 修正内容: copy-mode の `y` と `Enter` で `TERM=tmux-256color TMUX=1 /usr/local/bin/osc52.sh > "#{pane_tty}"` を実行し、tmux passthrough 形式の OSC52 シーケンスを対象ペインの tty へ明示的に流すようにした
- 検証: `bash -n bin/osc52.sh` が成功し、`TERM=tmux-256color` + `TMUX` 環境で DCS ラップ済み OSC52 が生成されることを `od` で確認した
- 検証: tmux 3.2a で `config/tmux/tmux.conf` を読み込み、`set-clipboard off` のまま `copy-mode-vi` の `y` / `Enter` が tty リダイレクト付きで登録されることを確認した

### 2026-04-16: gh credential and Codex integration

- [x] 原因と修正内容、検証結果を今回の `bin/gh` 更新について追記する

- [x] `bin/tmux-gh.sh` の issue 一覧が空になる再現条件を確認する
- [x] 取得失敗時に空キャッシュを残さないようにキャッシュ更新処理を修正する
- [x] 旧キャッシュ形式を無効化して、壊れた空キャッシュを自動で再取得させる
- [x] 失敗時と成功時の両方をコマンドで検証する
- [x] `pinentry` の実装選択が repo で固定されているか確認する
- [x] `pinentry-curses` を使う `gpg-agent.conf` を追加し、セットアップ時に `~/.gnupg` へ反映する
- [x] ローカル環境へ反映し、`gpg-agent --gpgconf-test` で設定妥当性を検証する
- 原因: この環境の `/usr/bin/pinentry` は `pinentry-tty 1.1.1` で、dialog ではなく単純な TTY プロンプトを表示していた
- 修正内容: `config/gnupg/gpg-agent.conf` を追加し、`pinentry-program /usr/bin/pinentry-curses` を明示した
- セットアップ導線: `Makefile` の `base` に `gnupg-link` を追加し、`~/.gnupg/gpg-agent.conf` を dotfiles 管理下からリンクするようにした
- 検証: `make gnupg-link` で `~/.gnupg/gpg-agent.conf` に反映し、`gpg-agent --gpgconf-test` が成功することを確認した
- 背景: Codex/gh MCP は非対話 subprocess で `gh` を呼ぶため、`bin/gh` に埋め込んだ `pass` + pinentry 復元とは責務が衝突する
- 修正内容: `bin/codex-with-gh` を追加し、Codex 起動前に一度だけ `pass show github/cli-token` で `GH_TOKEN` を復元してから `codex` を起動するようにした
- セットアップ導線: `Makefile` の `codex` ターゲットで `~/bin/codex-with-gh` へ symlink するようにした
- 検証: `bin/codex-with-gh` の内容と `Makefile` のリンク導線を読み取りで確認し、期待する起動経路になっていることを `git diff` で確認した
- 修正内容: `bin/gh` は `GH_TOKEN` 未設定かつ非対話のときに即失敗するようにし、`pass show` や `pass insert` に進まないようにした
- 方針変更: `GH_TOKEN` を Codex 親環境から渡す方式は gh MCP へ届かなかったため、`gpg-agent` キャッシュを温めてから非対話 `pass show` を許可する方式へ切り替えた
- 修正内容: `bin/codex-with-gh` は `gh --ensure-auth` を先に実行してから `codex` を起動するようにし、`bin/gh` は非対話でも `pass show` は試すが、失敗時の `pass insert` は対話時だけに限定した
- 修正内容: `config/gnupg/gpg-agent.conf` に `default-cache-ttl 28800` と `max-cache-ttl 86400` を追加し、Codex セッション中に復号キャッシュが残りやすいようにした
- 修正内容: `bin/tmux-gh.sh` のラベル未設定 issue 向けブランチ既定値を `feature/misc#<issue>` から `feature/no-label#<issue>` に変更した
- 検証: `bash -n bin/tmux-gh.sh` が成功し、差分がフォールバック文字列の変更だけであることを確認した
- 背景: `layout-dev` の右ペインは `config/tmux/bin/codex-pane.sh` 経由で `codex` を直接起動しており、`bin/codex-with-gh` の事前認証導線を通っていなかった
- 修正内容: `config/tmux/bin/codex-pane.sh` が `codex` ではなく `~/dotfiles/bin/codex-with-gh` を実行するように変更し、終了後にログインシェルへ戻る既存挙動は維持した
- 背景: `gh auth setup-git` ではなく repo 管理の wrapper `~/bin/gh` を Git credential helper に使いたいため、helper 設定は `~/.gitconfig` ではなく `~/.gitconfig.local` に寄せる方針とした
- 修正内容: `Makefile` の `gh` タスクで `~/bin/gh` の symlink 作成後に、GitHub / gist 用 credential helper を `~/.gitconfig.local` へ冪等に設定するようにした
- 検証: `make -n gh` で `git config --file "$HOME/.gitconfig.local"` のみが実行対象であることを確認し、`git diff -- Makefile ai/tasks/todo.md` で変更範囲を確認した
- 背景: `github/cli-token` を更新する専用導線がなく、`pass insert` の生コマンドを毎回思い出す必要があった
- 修正内容: `bin/gh` に `gh auth update-token` と `gh auth update-token --with-token` を追加し、対話更新と stdin 経由更新の両方を wrapper 経由で実行できるようにした
- 修正内容: `bin/gh` の未登録時メッセージを新導線に寄せ、対話時はそのまま更新フローへ遷移するようにした
- 検証: `bash -n bin/gh` と `bin/gh auth update-token --help` が成功し、新サブコマンドの導線が有効であることを確認した

### 2026-04-16: todo.md conflict and task-log convention

- 原因: `ai/tasks/todo.md` の Plan/Review がフラット運用と依頼単位運用で混在し、pull 時に別タスクの追記同士が同じ位置で conflict した
- 修正内容: conflict していた双方の Plan/Review を捨てず、依頼ごとの `### YYYY-MM-DD: タスク名` 見出しへ分離して統合した
- 修正内容: `config/codex/AGENTS.md` に `ai/tasks/todo.md` の依頼単位追記、既存履歴非並べ替え、conflict 時は双方を残す方針を追記した
- 修正内容: `ai/tasks/lessons.md` に今回の再発防止ルールを記録した
- 検証: conflict marker が残っていないこと、`git diff --check` が成功すること、`ai/tasks/todo.md` の未解決状態を解消できることを確認した

### 2026-04-17: tmux 3.5a OSC52 clipboard

- 原因: tmux 3.5a では `allow-passthrough` の既定値が `off` で、`osc52.sh` が出す `\033Ptmux;...\033\\` の DCS passthrough が tmux で止まり、外側端末の OSC52 クリップボード更新まで届いていなかった
- 修正内容: `config/tmux/tmux.conf` に tmux 3.3+ の場合だけ `set -g allow-passthrough on` を追加し、既存の `set-clipboard off` と明示的な `osc52.sh > "#{pane_tty}"` 経路は維持した
- 互換性: tmux 3.2a では version guard が false になるため、未対応 option を設定せず既存挙動を維持する
- 検証: tmux 3.5a の一時サーバーで `source-file config/tmux/tmux.conf` が成功し、`show-options -g allow-passthrough` が `on` になることを確認した
- 検証: `copy-mode-vi` の `y` / `Enter` が `TERM=tmux-256color TMUX=1 /usr/local/bin/osc52.sh > "#{pane_tty}"` のまま登録されることを確認した
- 検証: `printf test | TERM=tmux-256color TMUX=1 bin/osc52.sh` が DCS ラップ済み OSC52 を生成すること、`git diff --check -- config/tmux/tmux.conf ai/tasks/todo.md` が成功することを確認した
