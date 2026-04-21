# Todo

## Plan

### 2026-04-21: tig config management

- [x] `tig` 設定ファイルを `config/tig/config` に追加し、`D` で `git commit-diff` を呼べるようにする
- [x] `Makefile` に `tig-setting` と `tig-all` を追加し、`~/.config/tig/config` へリンクする導線を作る
- [x] 試験用 `ai/tasks/workspace` の `tigrc` を整理し、`make -n` と `tig --help` で設定反映導線を検証して Review に記録する
- [x] `starship` の `cyberpunk2077` パレットに寄せた `tig` 色設定を追加し、設定構文を確認する

### 2026-04-21: tig custom commit test bind

- [x] `tig` 設定の管理場所と既存導線を確認する
- [x] 試験用の `tigrc` を `ai/tasks/workspace` に追加して `bind status M !git commit-diff` を定義する
- [x] `TIGRC_USER` で読み込めることを確認し、Review に結果を記録する

### 2026-04-20: tmux-gh worktree source branch

- [x] `bin/tmux-gh.sh` の worktree 作成箇所と `git gtr new` のオプションを確認する
- [x] 現在ブランチが `master` / `main` / `develop` の場合だけ通常処理へ進む判定を追加する
- [x] 新規 worktree 作成時に現在ブランチを `--from` へ渡す
- [x] 構文確認と fake command による分岐検証を行う
- [x] 差分を確認し、Review に結果を記録する

### 2026-04-20: gh-ec2 Parameter Store token wrapper

- [x] 既存 `bin/gh` の互換対象オプションと分岐を確認する
- [x] `bin/gh-ec2` を追加し、`GH_TOKEN` 優先と Parameter Store 取得を実装する
- [x] `--ensure-auth` と `auth update-token` の EC2 向け挙動を実装する
- [x] 構文確認と fake `aws` / `gh` による主要パス検証を行う
- [x] 変更差分を確認し、Review に結果を記録する

### 2026-04-21: nvim task install and settings update

- [x] 既存 `Makefile` の `nvim-all` / `nvim-settings-repo` 導線と `~/.config/nvim` の前提を確認する
- [x] `nvim` タスクを追加し、`nvim-all: nvim nvim-settings-repo` へ更新する
- [x] `nvim-settings-repo` に clone / 更新の分岐を追加し、管理外ディレクトリは安全に停止する
- [x] `make -n` と一時ディレクトリ検証で `nvim` 本体導線と設定 repo 更新分岐を確認する
- [x] 差分と検証結果を Review に記録する

### 2026-04-17: codex config requested defaults

- [x] `codex-config` の既存生成内容と marker 冪等化を確認する
- [x] 指定された Codex config 値を `Makefile` の `codex-config` へ反映する
- [x] 一時 HOME で `make codex-config` を実行し、生成 TOML が指定値になることを確認する
- [x] begin/end marker を追加し、既存 marker 付き config は更新せず skip することを確認する
- [x] 差分と whitespace を検証し、Review に結果を記録する

### 2026-04-17: codex config task

- [x] 既存の `codex` / `codex-all` / `codex-gh-mcp` の config 更新順序を確認する
- [x] `codex` から notify 追記処理を外し、`codex-config` へ base config 生成を移す
- [x] `codex-all` に `codex-config` を追加し、MCP 追記との順序が壊れないことを確認する
- [x] `make -n` と差分確認で生成内容と変更範囲を検証する
- [x] marker コメントによる簡易冪等化を追加し、既存管理済み config を上書きしないことを検証する

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

### 2026-04-21: tig config management

- 背景: 試験用の `tigrc` は `ai/tasks/workspace` に置いて `M` バインドで確認していたが、本運用では dotfiles 管理下の `~/.config/tig/config` へ寄せたい
- 修正内容: `config/tig/config` を追加し、`bind status D !git commit-diff` を定義した
- 修正内容: `Makefile` に `tig-setting` を追加し、`~/.config/tig/config` への `ln -sf` 導線を追加した
- 修正内容: `Makefile` に `tig-all: tig tig-setting` を追加し、インストールと設定反映をまとめて実行できるようにした
- 修正内容: 試験用の `ai/tasks/workspace/tig-commit-diff-test.tigrc` は削除した
- 修正内容: `config/starship.toml` の `cyberpunk2077` パレットに合わせて、`config/tig/config` に title/status/main/diff/status-view の色設定を追加した
- 検証: `make -n tig-setting tig-all` で `mkdir -p "$HOME/.config/tig"` と `ln -sf "$HOME/dotfiles/config/tig/config" "$HOME/.config/tig/config"` を含む期待コマンド列が出ることを確認した
- 検証: `TIGRC_USER=/home/user/dotfiles/config/tig/config tig --help` が成功し、設定ファイル読み込みで parse error が出ないことを確認した
- 検証: `git diff --check -- Makefile config/tig/config ai/tasks/todo.md` が成功した

### 2026-04-21: tig custom commit test bind

- 背景: dotfiles 管理下には `tig` 設定がなく、`Makefile` も `tig` 本体インストールだけで `~/.tigrc` への導線は持っていなかった
- 修正内容: 試験用の `ai/tasks/workspace/tig-commit-diff-test.tigrc` を追加し、`bind status M !git commit-diff` を定義した
- 検証: `TIGRC_USER=/home/user/dotfiles/ai/tasks/workspace/tig-commit-diff-test.tigrc tig --help` と `tig --version` が成功し、設定ファイル読み込みで parse error が出ないことを確認した
- 制約: この実行環境では `tig` の対話起動に必要な TTY を再現できず、`M` 押下後の editor 起動成否までは自動検証していない

### 2026-04-20: tmux-gh worktree source branch

- 原因: `bin/tmux-gh.sh` の issue worktree 作成が常に `--from develop` 固定で、PR worktree 作成は `--from` 未指定だったため、現在の作業ブランチに応じた作成元を選べなかった
- 修正内容: 通常モード `issue` / `pr` / `file` の開始時に現在ブランチを確認し、`master` / `main` / `develop` 以外では `gh` や `fzf` を起動せず終了するようにした
- 修正内容: issue / PR の新規 worktree 作成時に、許可された現在ブランチを `git gtr new ... --from <branch>` へ渡すようにした
- 互換性: fzf から呼ばれる内部の list / preview / cache clear サブコマンドには現在ブランチ判定を入れず、既存のプレビュー更新経路を維持した
- 検証: `bash -n bin/tmux-gh.sh` が成功した
- 検証: fake 関数で `create_issue_worktree` が `git gtr new feature/bug#123 --from main`、`create_pr_worktree` が `git gtr new feature/pr-branch --from develop` を呼ぶことを確認した
- 検証: fake `git` で現在ブランチを `feature/foo` にした `bin/tmux-gh.sh issue` が終了コード 0 で早期終了し、`gh` / `fzf` へ進まないことを確認した
- 検証: `resolve_worktree_source_branch` が `master` / `main` / `develop` を許可し、それ以外を拒否することを確認した
- 検証: `git diff --check -- bin/tmux-gh.sh ai/tasks/todo.md` が成功した

### 2026-04-20: gh-ec2 Parameter Store token wrapper

- 背景: EC2 では pass/gpg の利用者や鍵管理が曖昧になるため、GitHub token を Parameter Store `/app/github/llm_github_token` から取得する `gh` 互換ラッパーが必要だった
- 修正内容: `bin/gh-ec2` を追加し、`GH_TOKEN` が既にある場合は Parameter Store を読まずに `/usr/bin/gh` を実行するようにした
- 修正内容: `GH_TOKEN` がない場合は `aws ssm get-parameter --with-decryption --name /app/github/llm_github_token --query Parameter.Value --output text` でトークンを取得し、`GH_TOKEN` として `/usr/bin/gh` へ渡すようにした
- 修正内容: `--ensure-auth` は Parameter Store から取得できることだけを確認して終了し、`auth update-token` は AWS 側で更新する旨を出して非ゼロ終了するようにした
- 検証: `bash -n bin/gh-ec2` と `sh -n bin/gh-ec2` が成功した
- 検証: `GH_TOKEN=test-token bin/gh-ec2 --version` が `/usr/bin/gh --version` を実行できることを確認した
- 検証: `bin/gh-ec2 auth update-token` が AWS 側更新を促すメッセージを出して終了コード 1 になることを確認した
- 検証: `aws` 未導入時の `bin/gh-ec2 --ensure-auth` が終了コード 127 で分かるエラーを出すことを確認した
- 検証: fake `aws` を使い、`--ensure-auth` が取得成功時に無出力で終了コード 0、空相当の値では非ゼロになることを確認した
- 検証: `git diff --check -- ai/tasks/todo.md` と `git diff --no-index --check /dev/null bin/gh-ec2` で whitespace error がないことを確認した

### 2026-04-21: nvim task install and settings update

- 背景: `base` では既に `nvim-all` を呼んでいたが、実際には Neovim 本体を入れておらず、設定 repo も既存 clone があると `git clone` で失敗して更新できなかった
- 修正内容: `Makefile` に `nvim` タスクを追加し、`sudo $(YUM) install -y neovim` で Neovim 本体をインストールまたは更新するようにした
- 修正内容: `nvim-all` を `nvim nvim-settings-repo` へ変更し、Node.js 依存を外して本体導線と設定 repo 導線を分離した
- 修正内容: `nvim-settings-repo` は `~/.config/nvim/.git` がある場合に `git -C ... pull --ff-only` で更新し、未作成なら clone、Git 管理外ディレクトリが既にある場合は安全のため非ゼロ終了するようにした
- 修正内容: `~/.vimrc` と `~/.vim/coc-settings.json` のリンク作成は `ln -snf` に変更し、再実行でも張り直せるようにした
- 検証: `make -n nvim nvim-all` で `nvim` が `sudo dnf install -y neovim` を実行し、`nvim-all` が `nvim-settings-repo` を呼ぶことを確認した
- 検証: 一時 HOME と fake `git` で `make nvim-settings-repo` を 2 回実行し、初回が clone、2 回目が `pull --ff-only` になること、`~/.vimrc` と `~/.vim/coc-settings.json` が期待する symlink になることを確認した
- 検証: Git 管理外の `~/.config/nvim` を用意した一時 HOME では `make nvim-settings-repo` がエラーメッセージ付きで停止することを確認した
- 検証: `git diff --check -- Makefile ai/tasks/todo.md` が成功し、whitespace error がないことを確認した

### 2026-04-17: codex config requested defaults

- 原因: `codex-config` の生成内容が以前の既定値のままで、`approval_policy = "never"` になっており、guardian approval と model 指定も含まれていなかった
- 修正内容: `Makefile` の `codex-config` が `sandbox_mode = "workspace-write"`、`approval_policy = "on-request"`、`approvals_reviewer = "guardian_subagent"`、`model = "gpt-5.4"`、`notify`、`personality = "pragmatic"` を生成するように更新した
- 修正内容: `[tui]` の通知設定を維持し、`[features] guardian_approval = true` を追加した
- 修正内容: 新規生成 config に `# BEGIN auto config by irukasano/dotfiles` と `# END auto config by irukasano/dotfiles` を入れるようにした
- 互換性: 既存の旧 marker または begin marker 付き config は管理済みと見なし、`codex-config` 再実行では更新せず skip する方針にした
- 検証: 一時 HOME に対して `make HOME=<tmp> codex-config` を実行し、生成 TOML が指定値になることを確認した
- 検証: begin marker 付き config と旧 marker 付き config の再実行で checksum が変わらず、既存内容を更新しないことを確認した
- 検証: `python3` の `tomllib` で生成 TOML を parse できることを確認した
- 検証: `make -n codex-config` / `make -n codex-all` / `make -n codex-gh-mcp` と `git diff --check -- Makefile ai/tasks/todo.md ai/tasks/lessons.md` が成功した

### 2026-04-17: codex config task

- 原因: `codex` タスク内で `notify` だけを既存 config へ差し込んでおり、Codex の基本設定をまとめて再生成するタスクがなかった
- 修正内容: `codex` から config 更新処理を外し、`codex-config` で `notify` / `personality` / `sandbox_mode` / `approval_policy` / `[tui]` 設定を `~/.codex/config.toml` へ生成するようにした
- 修正内容: `codex-all` に `codex-config` を追加し、`codex-gh-mcp` も `codex-config` に依存させて base config 生成後に MCP 設定を追記する順序にした
- 修正内容: `# auto config by irukasano/dotfiles` を marker として config 先頭に書き、同じ marker が既にある場合は `codex-config` が上書きしないようにした
- 検証: 一時 HOME に対して `make HOME=<tmp> codex-config` を実行し、期待する TOML が生成されることを確認した
- 検証: marker 付き config に `[mcp_servers.gh]` を追記した後で `make HOME=<tmp> codex-config` を再実行し、checksum が変わらず追記内容が保持されることを確認した
- 検証: `make -n codex-config` / `make -n codex-all` / `make -n codex-gh-mcp` と `git diff --check -- Makefile ai/tasks/todo.md ai/tasks/lessons.md` が成功した

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
