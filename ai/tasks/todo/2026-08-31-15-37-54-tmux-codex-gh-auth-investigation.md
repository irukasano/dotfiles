## HLD

### 2026-08-31 15:37 : tmux Codex gh authentication investigation
- 目的: `Alt-p c` で起動する Codex が `gh` を利用できない原因と、`codex-with-gh` の認証情報の引継ぎ範囲を確認する。
- 変更対象: 調査のみ。設定・実装は変更しない。
- 非変更対象: tmux、Codex、gh、gpg-agent の設定および認証情報。
- 入出力: 起動スクリプトと gh ラッパーの実装を入力とし、プロセス環境と gpg-agent キャッシュの挙動を説明として出力する。
- 運用方法: 現行の `Alt-p c` 起動経路を確認する。
- 失敗時挙動: 一次情報だけで断定できない点は追加確認項目として明示する。
- 既存機能への影響: なし。
- 未確定事項: 実際の Codex MCP 実行時のエラー本文。
- ユーザー確認が必要な項目: 修正を行う場合は、MCP が `GH_TOKEN` を親環境から受け取るかの実測結果と、望む認証方式。

### 2026-08-31 16:00 : Codex 専用の GitHub token 引継ぎ
- 目的: `Alt-p c` で起動した Codex の sandbox 内で、`gh` CLI が `pass + gpg` にアクセスせず GitHub API を利用できるようにする。
- 変更対象: `bin/codex-with-gh` のみ。起動前に `pass` から `github/cli-token` を復号し、`GH_TOKEN` として `codex` プロセスへ渡す。
- 非変更対象: `bin/gh`、`pass + gpg` での token 保存方法、tmux の起動分岐、`~/.codex/config.toml`。
- 入出力: 入力は `pass show github/cli-token` の先頭行と任意の Codex 引数。出力は `GH_TOKEN` を継承した `codex "$@"` の実行。token は stdout/stderr に出力しない。
- 運用方法: GitHub の `origin` を持つ repo では既存どおり `Alt-p c` が `codex-with-gh` を起動する。
- 失敗時挙動: token を取得できない、または空の場合は `codex` を起動せず非 0 終了する。gpg の対話認証は sandbox 外の launcher で行う。
- 既存機能への影響: Codex とその sandbox 内 subprocess が GitHub token を利用可能になる。通常 shell の `gh` と他の Codex 起動経路は変更しない。
- 未確定事項: 現行 Codex の環境変数ポリシーで、親から export した `GH_TOKEN` が sandbox command execution に継承されるか。公式設定に `shell_environment_policy` があるが、本タスクでは設定を先に変更せず実測する。
- ユーザー確認: 2026-08-31 に、`bin/gh` は維持し `codex-with-gh` のみで対応する方針を合意。

### 2026-08-31 16:20 : Codex sandbox の GitHub API 通信
- 目的: token を引継いだ Codex の `gh` CLI が `api.github.com` を名前解決・接続できるようにする。
- 変更対象候補: `Makefile` の `codex-config` が生成する `~/.codex/config.toml` に `sandbox_workspace_write.network_access = true` を追加する。あわせて既存の active config `~/.codex/config.toml` へ同値を反映するかを決定する。
- 非変更対象: `bin/gh`、`pass + gpg` の保存方法、`bin/codex-with-gh` の token 引継ぎ仕様、workspace-write の writable roots。
- 入出力: Codex sandbox 内で `api.github.com` への DNS/HTTPS 通信を許可し、`gh issue view 14` が API 応答を取得できるようにする。
- 運用方法: 設定はすべての local Codex `workspace-write` セッションに適用される。
- 失敗時挙動: GitHub 接続に失敗すれば `gh` は既存どおりエラーを返す。既存 config の反映が未実施なら generator のみの変更では現在の session に効かない。
- 既存機能への影響: Codex sandbox 内の任意コマンドに outbound network access が与えられる。今回 `GH_TOKEN` も継承するため、信頼できないリポジトリでの起動時は token の外部送信リスクがある。
- 未確定事項: すべての local Codex session に恒久適用するか、active config も直接更新するか。
- ユーザー確認が必要な項目: network access を有効にする範囲と、生成元 `Makefile` と現在の active config の両方を更新する許可。

### 2026-08-31 16:30 : Codex network 設定生成と gh-ec2 の pass 非依存確認
- 目的: 新規生成する Codex config に `sandbox_workspace_write.network_access = true` を含める。あわせて `bin/gh-ec2` が `pass` を実行せず AWS SSM から token を取得することを検証する。
- 変更対象: `Makefile` の `codex-config` 生成内容のみ。
- 非変更対象: 既存の `~/.codex/config.toml`、`bin/gh-ec2`、`bin/gh`、`bin/codex-with-gh`、gpg 設定。
- 入出力: `make codex-config` が新規に生成する config に network access 許可を出力する。`gh-ec2` は token 未設定時に `aws ssm get-parameter` の出力を `GH_TOKEN` として `/usr/bin/gh` に渡す。
- 運用方法: 既存 config が管理済みなら `codex-config` は従来どおり skip するため、この変更だけでは active config に反映されない。
- 失敗時挙動: `aws`/SSM token 取得に失敗した `gh-ec2` は非 0 終了する。`pass` は fallback としても実行しない。
- 既存機能への影響: 以後新規生成される Codex config では workspace-write sandbox の outbound network が有効になる。
- 未確定事項: 既存 active config への network access 反映は本依頼の対象外。
- ユーザー確認: 2026-08-31 に Makefile への追加と `gh-ec2` の pass 非依存確認を依頼された。

### 2026-08-31 16:40 : local / EC2 共通の Codex token 引継ぎ再設計
- 目的: local の `pass + gpg` と EC2 の AWS SSM のどちらでも、既存の `~/bin/gh` wrapper を通じて Codex へ `GH_TOKEN` を渡す。
- 調査結果: `codex-with-gh` が `pass show` を直接実行する方式は、EC2 で `~/bin/gh` が `gh-ec2` へ symlink される運用を迂回するため不適合。
- 変更対象候補: `bin/gh` と `bin/gh-ec2` に、token を stdout へ出さず指定 command へ `GH_TOKEN` を渡して exec する共通 subcommand を追加し、`bin/codex-with-gh` はその subcommand で `codex` を起動する。
- 非変更対象: token の保存先（local: pass+gpg / EC2: AWS SSM）、`~/bin/gh` の host 別 symlink 運用、通常の `gh` コマンド互換動作。
- 未確定事項: 新規共通 subcommand の名前と引数形式。
- ユーザー確認が必要な項目: `gh auth exec -- <command> [args...]` を wrapper 独自の共通インターフェースとして追加するか。
- 訂正: EC2 の Codex は現行経路で `gh` を利用できる。Codex 内で起動された `gh-ec2` が command ごとに AWS SSM から token を再取得し、`GH_TOKEN` を設定して `/usr/bin/gh` を exec するためである。親 `codex-with-gh` からの環境変数継承は不要。対策対象は local の `pass + gpg` wrapper に限定する。

### 2026-08-31 16:50 : capability 判定による local Codex token 引継ぎ
- 目的: local の Codex sandbox へだけ `pass + gpg` の GitHub token を渡し、EC2 は現在の SSM 再取得経路を維持する。
- 変更対象: `bin/gh`、`bin/gh-ec2`、`bin/codex-with-gh`、`Makefile` の `codex-config` 生成内容。
- 非変更対象: token 保存先、`~/bin/gh` の symlink 運用、通常の `gh` の API/CLI 呼び出し、既存 active config `~/.codex/config.toml`。
- 入出力:
  - local `bin/gh --print-token`: `pass + gpg` から token の先頭行だけを stdout へ出し、成功時は 0、復号失敗時は非 0 を返す。
  - EC2 `bin/gh-ec2 --print-token`: stdout を出さず、capability 未対応を表す 64 を返す。
  - `codex-with-gh`: `gh --print-token` が 0 のときだけ token を `GH_TOKEN` として export して `codex` を exec する。64 のときは既存の `gh --ensure-auth` 後の起動経路を使う。それ以外の非 0 は Codex を起動せず終了する。
  - `Makefile`: 新規に生成する Codex config に `sandbox_workspace_write.network_access = true` を追加する。
- 運用方法: 実行ファイルの symlink 解決先ではなく、`--print-token` の終了コードによる capability 判定を行う。
- 失敗時挙動: local の gpg/pass 失敗は EC2 経路へフォールバックせず元のエラーで終了する。EC2 は `--ensure-auth` と Codex 内の SSM token 再取得を維持する。
- 既存機能への影響: local の GitHub repo で起動した Codex は `GH_TOKEN` を環境に持つ。新規生成の Codex config は network access を有効にする。
- 未確定事項: なし。
- ユーザー確認: 2026-08-31 に capability 判定と、EC2 が 64 を返す仕様を合意。
- 中止: fixture 検証時に実 token が stdout へ露出したため、`--print-token` の実装を即時 rollback した。secret を stdout に出す設計は再設計が必要であり、再開前に token の失効・再発行と安全な仕様の再合意が必要。

## Plan

### 2026-08-31 15:37 : tmux Codex gh authentication investigation
- [x] 関連する `AGENTS.md` と `ai/tasks/lessons.md` を確認する。
- [x] `Alt-p c` から `codex-with-gh` までの起動経路を確認する。
- [x] `gh --ensure-auth` と `exec codex` の環境変数・gpg-agent キャッシュの引継ぎを確認する。
- [x] 変更を加えず、調査結果を Review に記録する。

### 2026-08-31 16:00 : Codex 専用の GitHub token 引継ぎ
- [x] OpenAI Docs の公式設定リファレンスを確認し、`shell_environment_policy` と sandbox の追加 writable root の仕様を確認する。
- [x] 現在の `bin/codex-with-gh` と `~/.codex/config.toml` を確認し、`GH_TOKEN` 継承を設定していないことと `gh` MCP の存在を記録する。
- [ ] `bin/codex-with-gh` で token を非表示のまま取得・検証・export し、既存の引数を保ったまま `exec codex` する（EC2 運用と不整合のため rollback）。
- [x] stub の `pass` / `codex` で、token が launcher の子にだけ渡り、引数が保持され、空 token 時には Codex を起動しないことを検証する。
- [x] `sh -n bin/codex-with-gh` と `git diff --check` を実行する。
- [ ] fixture の `GH_TOKEN` を設定して `codex sandbox sh -c ...` を実行し、導入済み Codex CLI 0.151.0 の実際の引数形式で sandbox への継承可否を確認する。
- [ ] 実機 tmux で `Alt-p c` から起動した Codex に `gh issue view 14` を依頼し、token を露出せず成功を確認する。継承されない場合は実装を止め、`shell_environment_policy` 設定を追加する HLD を再合意する。
- [ ] Review に修正内容と検証結果を記録する。

#### 2026-08-31 16:10 : 検証計画の再計画
- 変更理由: 公式ドキュメントの `codex sandbox --sandbox workspace-write` は、導入済み Codex CLI 0.151.0 では未対応で `unexpected argument '--sandbox'` となった。ローカル `codex sandbox --help` に従い、現行 `config.toml` の `sandbox_mode = "workspace-write"` を使用する `codex sandbox sh -c ...` へ検証手順を変更する。
- 変更なし: 実装の対象・仕様・token の保存方式・最終実機検証の内容。

#### 2026-08-31 16:15 : 実機検証でのネットワーク障害
- 実測: token 引継ぎ後の Codex で `gh` の認証は通過したが、`error connecting to api.github.com` で GitHub API 接続に失敗した。
- 未確定原因: 現行 `~/.codex/config.toml` は `sandbox_mode = "workspace-write"` で `sandbox_workspace_write.network_access` を設定していない。ネットワークが sandbox 方針により遮断されている可能性が高いが、DNS・proxy・実ネットワーク障害との区別には Codex 内の接続コマンドの一次エラーが必要。
- 変更制約: `sandbox_workspace_write.network_access = true` の追加は sandbox の権限拡大であり、既存 HLD の非変更対象外となる。原因確認と新規 HLD 合意なしに変更しない。
- 原因確定: Codex 内で `getent ahostsv4 api.github.com` は無出力、`curl -I https://api.github.com` は `curl: (6) Could not resolve host` となった。DNS 名前解決が sandbox 内で遮断されている。

### 2026-08-31 16:30 : Codex network 設定生成と gh-ec2 の pass 非依存確認
- [x] `Makefile` の `codex-config` 生成方式と active config の管理状態を確認する。
- [x] `bin/gh-ec2` に `pass` 呼び出しがないことを静的確認する。
- [ ] `Makefile` の生成行へ `sandbox_workspace_write.network_access = true` を追加する。
- [ ] `make -n codex-config` で生成内容と既存 config の skip 挙動を確認する。
- [ ] fake `aws` と失敗する fake `pass` を使い、`gh-ec2 --ensure-auth` が SSM token 取得だけで成功し `pass` を呼ばないことを検証する。
- [ ] `make -n` の実行結果、`sh -n bin/gh-ec2`、`git diff --check` を確認し、Review に結果を記録する。

### 2026-08-31 16:40 : local / EC2 共通の Codex token 引継ぎ再設計
- [x] EC2 の `~/bin/gh -> gh-ec2` 運用と、`pass` 直呼びが不適合であることを確認する。
- [ ] 共通 wrapper subcommand の仕様をユーザーと合意する。
- [ ] 合意後に HLD と Plan を詳細化し、実装・検証を再開する。

### 2026-08-31 16:50 : capability 判定による local Codex token 引継ぎ
- [x] `bin/gh`、`bin/gh-ec2`、`bin/codex-with-gh` の既存引数分岐と token 取得経路を再確認する。
- [x] HLD の capability 判定・終了コード・EC2 の現行経路維持を合意する。
- [ ] `bin/gh` に local 専用 `--print-token` を追加する（secret 露出が発生したため rollback）。
- [ ] `bin/gh-ec2` に `--print-token` の無出力・終了コード 64 を追加する（secret 露出が発生したため rollback）。
- [ ] `bin/codex-with-gh` を capability 判定へ変更し、0/64/その他の終了コードを正しく扱う（secret 露出が発生したため rollback）。
- [ ] `Makefile` の新規 Codex config へ network access 設定を追加する。
- [ ] fake `pass` / `gh` を使い、local 成功・local 認証失敗・EC2 capability 未対応の各 launch 経路と引数保持を検証する。
- [ ] fake `aws` / 失敗する fake `pass` を使い、`gh-ec2 --ensure-auth` が SSM token 取得だけで成功し `pass` を呼ばないことを検証する。
- [ ] `sh -n`、`make -n codex-config`、`git diff --check` を実行し、実機 local Codex の `gh issue view 14` を token 非表示で確認する。
- [ ] Review に修正内容と検証結果を記録する。

## Review

### 2026-08-31 15:37 : tmux Codex gh authentication investigation
- 原因: `bin/codex-with-gh` は `gh --ensure-auth` を子プロセスとして起動する。`bin/gh` はトークンを `pass show` で復号しても、`--ensure-auth` 時は `export GH_TOKEN`（101 行目）より前の 97--99 行目で終了する。このためトークン値は Codex へ渡らない。仮に子 `gh` が export しても、子から親の環境変数を変更することはできない。
- 確認: `GPG_TTY` は `codex-with-gh` 自身で export されるため `exec codex` 後も継承される。一方、事前復号で温められた gpg-agent のキャッシュはプロセス環境ではなく agent 側の状態であり、Codex が後から `gh` を起動した際にも利用できる。
- 既存記録: `ai/tasks/todo.md` の既存 Review では、親環境の `GH_TOKEN` を Codex MCP へ渡す方式は届かなかったため、gpg-agent キャッシュを使う方式へ変更した経緯がある。
- 検証: `nl -ba bin/gh bin/codex-with-gh config/tmux/bin/codex-pane.sh config/tmux/bin/open-codex-pane.sh` で起動経路と分岐を確認した。`git diff --check` は成功した。

### 2026-08-31 15:45 : tmux window-level gh availability
- 調査結果: tmux の各 pane は起動時の親プロセスの環境を継承する。pane 内で後から export した `GH_TOKEN` は tmux server や既存の別 pane には反映されない。また `Alt-p c` は `run-shell` から起動されるため、現在の shell pane ではなく tmux server 側の環境が起点となる。
- 確認方針: 利用可能・不可のそれぞれの pane で、トークン値を表示せず `GH_TOKEN` の設定有無、`GPG_TTY`、解決される `gh` のパス、`gh auth status` の結果を比較する。
- 実測結果: 両 pane とも `GH_TOKEN` は未設定、`gh` は `/home/user/dotfiles/bin/gh`、`origin` は GitHub、かつ `gh auth status` は終了コード 1 で同じ非対話復元エラーとなった。したがって、提示された一次情報上は「利用可能 pane」と「利用不可 pane」の `gh CLI` 認証状態に差はない。
- 原因の確度: Codex の command execution は `tty=not a tty` で実行される。`bin/gh` は gpg-agent の復号キャッシュが使えない場合、非対話実行では token 復元を行わず終了するため、この時点では gpg-agent キャッシュが利用不能だったことが直接確認できる。

### 2026-08-31 15:48 : shell と Codex の認証状態の差分再調査
- 訂正: shell の `gh auth status` に表示される `(GH_TOKEN)` は、親 shell に `GH_TOKEN` が存在する証拠ではない。`bin/gh` は `pass show` 成功後に子プロセス内で `GH_TOKEN` を export して `/usr/bin/gh auth status` を exec する（91--102 行目）ため、その表示となる。`rg -l` の結果にも shell 設定内の `GH_TOKEN` 設定はない。
- 未確定原因: shell の `gh --ensure-auth` 直後に Codex の非対話 `pass show` が失敗する理由。wrapper は最初の `pass show` の標準エラーを抑制するため、現状のエラーだけでは gpg-agent socket への接続失敗、鍵の不一致、sandbox による socket アクセス不可などを区別できない。
- 次の一次情報: Codex で `pass show github/cli-token >/dev/null` を実行し、標準エラーと終了コードを取得する。token 本文は stdout を `/dev/null` に捨てるため露出しない。
- 根本原因（実測）: Codex 内の `pass show github/cli-token >/dev/null` は終了コード 2 となり、`/home/user/.gnupg/.#lk...: Read-only file system` と `can't connect to the gpg-agent: Read-only file system` を返した。Codex の command execution sandbox が `~/.gnupg` を read-only にしており、gpg が agent socket 接続時に必要な lock file を作れない。よって gpg-agent のキャッシュ有効期間、tmux pane、`GPG_TTY` は主因ではない。
- 対応判断が必要な項目: Codex sandbox から `~/.gnupg`（少なくとも gpg-agent socket と lock file が必要な領域）への書込みを許可するか、gpg を介さず Codex sandbox から安全に利用できる GitHub token 供給方式へ変更するかをユーザーと合意してから実装する。

### 2026-08-31 16:40 : pass 直呼び実装の rollback
- 原因: EC2 では `~/bin/gh` が `bin/gh-ec2` へ symlink され、AWS SSM から token を取得する。`bin/codex-with-gh` の `pass show github/cli-token` 直呼びはこの host 別 wrapper を迂回するため、EC2 で起動できない。
- 対応: `codex-with-gh` に一時追加した `pass show`、`GH_TOKEN` export、空 token 検証を削除し、`gh --ensure-auth` の既存導線へ戻した。
- 訂正: EC2 で現行経路が利用可能である点を見落としていた。`gh-ec2` は後続の Codex 内 `gh` 実行時に SSM token を再取得するため、親プロセスへの token 引継ぎが不要である。

### 2026-08-31 17:00 : print-token 検証時の secret 露出
- 原因: fixture の local `bin/gh --print-token` 検証で `GH_TOKEN` を明示的に unset せず、実環境の token を参照する分岐へ入った。結果として token が command output に露出した。
- 対応: 実装した `bin/gh --print-token`、`bin/gh-ec2 --print-token`、`bin/codex-with-gh` の capability 分岐を即時 rollback した。以後の実装・検証を停止した。
- 必要な対応: 露出した GitHub personal access token を失効し、新しい token を発行する。新 token を保存する前に、stdout へ token を出さない代替設計を再合意する。

### 2026-08-31 17:10 : 次セッションへの引継ぎ
- 現在の実装状態: `bin/gh`、`bin/gh-ec2`、`bin/codex-with-gh` の `--print-token` / capability 判定は rollback 済み。`codex-with-gh` は `gh --ensure-auth` の従来実装へ戻っている。
- 確定した原因: local Codex sandbox は `~/.gnupg` が read-only のため、Codex 内の `pass + gpg` 復号に失敗する。EC2 の `gh-ec2` は Codex 内で呼ばれるたびに AWS SSM から token を再取得するため、現行経路で動作する。
- Makefile: `codex-config` の新規生成内容に `sandbox_workspace_write.network_access = true` を追加済み。ただし既存の `~/.codex/config.toml` は変更していないため、現在の local Codex にはまだ反映されない。
- セキュリティ状態: 実 token が tool output に露出したため、ローカル session log を削除した。新 token の失効・再発行後にのみ認証導線の実装を再開する。
- 再開条件: token を stdout に出さない方式を改めて合意し、HLD と Plan を新規に確定する。今回の `--print-token` 案は未採用であり、そのまま実装してはならない。
