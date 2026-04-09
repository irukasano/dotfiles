# Todo

## Plan

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

## Review

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
