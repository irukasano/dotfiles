## HLD

### 2026-10-07 12:02 : TTY と Codex session の token 差異診断
- 目的: 同一 host の TTY では `gh auth status` が成功し、`codex-with-gh` 経由の Codex session では `GH_TOKEN is invalid` となる原因を、token 本文を露出せず確定する。
- 変更対象: 診断コマンド、および原因確定後に必要なら `bin/codex-with-gh` と対応 fixture。
- 非変更対象: `pass` store、GPG 設定、GitHub token、Codex global config。原因が確定するまで実装変更・token 更新を行わない。
- 入出力: TTY の `pass show` 先頭行と Codex 内 `GH_TOKEN` の SHA-256（token 本文は出力しない）を比較する。
- 運用方法: 同じ `codex-with-gh` session と通常 TTY で比較する。hash が一致すれば Codex 側の環境処理を調査し、不一致なら launcher の取得・pipe 受け渡しを調査する。
- 失敗時挙動: `pass` 復号または hash コマンドが失敗したら、その終了状態のみを確認し、token を表示・更新しない。
- 既存機能への影響: 診断段階ではない。
- 未確定事項: hash が一致するか、Codex 実行時に環境変数が変換されているか。
- ユーザー確認が必要な項目: hash 値を会話へ貼ること（値自体は token ではないが、照合用の識別子となる）。

### 2026-10-07 12:16 : Git credential helper の対話的 GPG 復号
- 目的: 通常 terminal での HTTPS `git pull` / `git fetch` が、`pass + gpg` に保存した GitHub token を credential helper 経由で使えるようにする。
- 変更対象: `bin/gh` の `auth git-credential` 呼出し時だけの TTY 判定と `GPG_TTY` 設定、対応する fixture。
- 非変更対象: Git の credential helper 設定、`pass` store、GPG 設定、Codex launcher、`gh` の一般的な no-TTY 挙動。
- 入出力: Git credential protocol の stdin/stdout は `/usr/bin/gh auth git-credential` に維持する。GPG/pinentry の入出力だけ、利用可能な制御端末 `/dev/tty` を `GPG_TTY` として参照する。
- 運用方法: `auth git-credential` かつ `/dev/tty` が読み書き可能な場合にだけ既存の `pass show` 経路を使う。GPG cache 切れなら、その terminal 上で pinentry を表示する。
- 失敗時挙動: 制御端末がない場合（Codex/no-TTY/CI）は、`pass` や pinentry を起動せず、現在と同じ `GH_TOKEN` 設定要求で失敗する。
- 既存機能への影響: terminal からの Git HTTPS 操作が復旧する。非対話 `gh` と Codex 内の GPG 復号禁止は維持する。
- 未確定事項: `/dev/tty` を用いる GPG pinentry が対象環境で正しく表示されるか。
- ユーザー確認が必要な項目: 上記の「credential helper に限る」「制御端末なしでは復号しない」という挙動で実装してよいか。

#### 2026-10-07 15:19 : cache 切れ pinentry の再計画
- 再現報告: 制御端末がある terminal の `git pull` で、cache が空の初回は `github/cli-token が未設定` と誤認して登録を促した。直後に `pass show github/cli-token >/dev/null` を手動実行して cache を温めると、同じ `git pull` は成功した。
- 原因: 前回の実装は `GPG_TTY` だけを `/dev/tty` に向けたが、credential helper の `pass show` の stdin は Git credential protocol の pipe のままである。cache 切れ時の GPG/pinentry が対話に必要とする stdin を terminal へ渡していない。
- 変更対象: `bin/gh` の credential helper 専用 `pass show` 呼出し。元の Git credential protocol stdin を fd に退避し、`pass show` 実行中だけ stdin を `/dev/tty` にし、`/usr/bin/gh auth git-credential` 実行前に元の stdin を復元する。
- 非変更対象: `GPG_TTY`、通常 `gh`、Codex/no-TTY の復号禁止、Git credential protocol の内容、token 保存先。
- 失敗時挙動: `/dev/tty` がない場合は引き続き `pass` を起動しない。復号失敗は token 未設定として登録を促さず、復号失敗を明示して終了する。
- ユーザー確認が必要な項目: credential protocol の stdin を退避・復元し、`pass` のみ `/dev/tty` で実行する方式で修正してよいか。

##### 2026-10-07 15:27 : pinentry stderr の再計画
- 一次情報: `printf ... | env GPG_TTY=(tty) pass show github/cli-token </dev/tty >/dev/null` は exit 0 となった。stdin の `/dev/tty` 切替と GPG_TTY は正しい。一方、wrapper は credential helper の token 存在確認を `show_token >/dev/null 2>&1` で行っており、cache 切れ時に pinentry/GPG が必要とする stderr も破棄している。
- 変更対象: `bin/gh` の credential helper 専用 token 取得経路。
- 修正: credential helper は事前の無出力確認を行わず、`pass show` を一度だけ command substitution で実行する。復号 plaintext は shell 変数内に保持され stdout に出さず、stderr は terminal へ残す。失敗時は復号エラーで終了する。
- 非変更対象: 通常 TTY の初回登録導線、no-TTY/Codex の復号禁止、Git credential protocol、token 保存先。

###### 2026-10-07 15:33 : credential helper 内 pinentry の TTY 取得失敗
- 再現報告: `gpgconf --kill gpg-agent` と `git credential-cache exit` の後の `git pull` は、`gpg: 公開鍵の復号に失敗しました: そのようなデバイスやアドレスはありません` と表示した。Git helper は credential を返せず `Username for 'https://github.com'` にフォールバックした。
- 訂正: pinentry stderr の破棄が根本原因だと判断したが、stderr を残した結果、credential helper 内の pinentry 自体が terminal を取得できないことが判明した。単独 `pass show` の成功を helper 内の pinentry 可用性の証明としては扱えない。
- 次の一次情報: 対象 host の `~/.gnupg/gpg-agent.conf` にある `keep-tty` と `pinentry-program`、および `gpgconf --list-options gpg-agent` の該当設定を確認する。

### 2026-10-07 15:37 : gh 認証分岐の単純化
- 目的: GPG/pinentry を Git credential helper 内で起動する不成立な経路を撤去し、gh の認証判断を明確にする。
- 変更対象: `bin/gh` の `auth git-credential` 向け制御端末・GPG 復号分岐、対応 fixture。
- 非変更対象: `pass + gpg` による token 保存、Codex launcher の session 限定 `GH_TOKEN` 継承、通常 TTY での token 登録導線。
- 認証優先順位: (1) `GH_TOKEN` が設定済みなら常に `/usr/bin/gh` を実行する。(2) `GH_TOKEN` 未設定で no-TTY（credential helper を含む）なら、`pass`、GPG、pinentry を呼ばず失敗する。(3) `GH_TOKEN` 未設定かつ通常 TTY の `gh` だけが `pass + gpg` で復号する。
- 入出力: credential helper に `GH_TOKEN` が渡されれば既存の `/usr/bin/gh auth git-credential` が credential protocol を返す。未設定時の helper は token を返さない。
- 失敗時挙動: credential helper が未設定 token で失敗した際に、Git の Username/Password prompt を抑止するため `quit=true` を credential protocol の stdout へ返す案。一般 no-TTY `gh` は従来どおりエラーだけを stderr に出す。
- 既存機能への影響: 通常 terminal の `git pull` は `GH_TOKEN` を明示供給しない限り復号されず失敗する。helper 内の cache 切れ pinentry は表示されない。
- 未確定事項: credential helper の未設定 token 時に `quit=true` を返して Git prompt を止めるか、現状どおり Git の prompt へフォールバックさせるか。
- ユーザー確認が必要な項目: `quit=true` で Git の Username prompt を止めるか。

#### 2026-10-07 15:37 : 10b917c の credential helper 互換復元
- 目的: user が正常動作を確認していた `10b917c` の Git credential helper に限る GPG 復号経路を復元する。
- 根拠: `10b917c` は `auth git-credential` を特別扱いせず、no-TTY でも通常の `pass show` を実行していた。helper 内で `GPG_TTY` を上書きせず、親 fish が export した terminal 値を GPG/pinentry に渡していた。`9145c7e` で全 no-TTY を `GH_TOKEN` 必須にしたことが、当時の helper 経路を削除した。
- 変更対象: `bin/gh` の credential helper 専用 `credential_tty`、`/dev/tty` stdin、単発復号・復号失敗分岐を撤去し、`10b917c` と同じ通常 `pass show` 経路を helper にだけ適用する。
- 非変更対象: `GH_TOKEN` 優先、一般 no-TTY の `GH_TOKEN` 必須、通常 TTY の `pass + gpg` と token 登録、Codex launcher。
- 入出力: `auth git-credential` かつ `GH_TOKEN` 未設定なら、親環境の `GPG_TTY` を維持した `pass show` で token を取得し `/usr/bin/gh auth git-credential` へ渡す。その他 no-TTY は `pass` を呼ばずエラーにする。
- 失敗時挙動: helper の `pass` 復号失敗は `10b917c` と同じく、no-TTY 用の復元不能メッセージで終了する。Git の Username prompt を抑止する変更はこの復元には含めない。
- 既存機能への影響: terminal からの Git HTTPS 操作は、親 fish の `GPG_TTY` が有効なら `10b917c` と同じ挙動へ戻る。Codex 内の一般 no-TTY では GPG 復号を行わない。
- ユーザー確認が必要な項目: `10b917c` の credential helper 経路だけを復元すること。

#### 2026-10-07 15:37 : 修正前 credential helper の cache-only 挙動
- 履歴確認: `9145c7e` より前の `bin/gh` は、credential helper を含む no-TTY で `pass show` を実行した。ただし `PASSWORD_STORE_GPG_OPTS` に `--batch --pinentry-mode error` を付与していたため、gpg-agent cache が有効なら復号でき、cache 切れでは pinentry を出さず失敗する。
- 訂正: 修正前に helper が動いていたという観察は、GPG 復号そのものが helper 内で常に可能だったことではなく、agent cache を使えたことと整合する。今回追加した credential helper の TTY/pinentry special-case は、この既存 cache-only 経路を cache 切れの対話復号へ拡張しようとして失敗した。

### 2026-10-07 10:42 : gh 認証の現行仕様調査
- 目的: 過去の gh / Codex 認証調整の内容と、現行の対話・非対話における `pass + gpg` 復号条件を説明する。
- 変更対象: 調査・記録のみ。
- 非変更対象: `bin/gh`、`bin/codex-with-gh`、GPG、`pass`、GitHub token、および Codex 設定。
- 入出力: 実装・Git 履歴・既存タスク記録を入力に、認証フローと制約の説明を出力する。
- 運用方法: 現行スクリプトの静的確認と履歴確認に限定する。
- 失敗時挙動: 実行時環境が必要な点は、静的確認による結論と区別して記載する。
- 既存機能への影響: なし。
- 未確定事項: 現在の gpg-agent キャッシュ状態および実行時の復号可否。
- ユーザー確認が必要な項目: 修正を希望する場合のみ、Codex 起動時に復号を許可するか、別の token 供給経路にするか。

### 2026-10-07 10:42 : no-tty Codex の gh 認証対策検討
- 目的: Codex の no-tty 実行で、共有 gpg-agent のキャッシュが有効なら `pass` から GitHub token を復号して `gh` を使い、キャッシュ切れなら pinentry-curses を起動せず安全に失敗させる。
- 変更対象: `bin/gh` の token 読出し経路と no-tty 時のエラー文言、検証用スクリプト。
- 非変更対象: `bin/codex-with-gh`、Codex sandbox 権限、GPG agent、token 保存先、`GH_TOKEN` の Codex への継承。
- 入出力: 入力は TTY の有無、gpg-agent キャッシュ、`pass show github/cli-token`。出力はキャッシュ有効時の `/usr/bin/gh` 実行、またはキャッシュ切れ時の非対話・非表示エラー。
- 運用方法: キャッシュ切れ時は別の対話端末で `pass show github/cli-token >/dev/null` を実行して GPG 認証を完了してから、Codex の gh 操作を再実行する。
- 失敗時挙動: no-tty 時の `pass show` に `--batch --pinentry-mode error` を強制して pinentry を起動しない。失敗時は token を出力せず、対話端末での復号手順を stderr に表示して非 0 終了する。
- 既存機能への影響: 対話端末では従来どおり pinentry を利用可能。no-tty 時だけ、キャッシュ切れの GPG 認証を即時失敗へ変更する。
- 未確定事項: なし。`pass` 1.7.4 が `PASSWORD_STORE_GPG_OPTS` を GPG 起動オプションとして受け入れること、GnuPG 2.4.8 が `--pinentry-mode error` を提供することを確認済み。
- ユーザー確認: 2026-10-07 に、`--batch --pinentry-mode error` を用いて Codex/no-tty 内の pinentry 起動を抑止し、gpg-agent キャッシュだけを利用する方針を合意。

### 2026-10-07 10:42 : Codex sandbox の gpg-agent 接続許可
- 目的: Codex sandbox から共有 gpg-agent のキャッシュを利用可能にし、no-tty ではキャッシュ切れだけを安全に失敗させる。
- 変更対象候補: user-level Codex `config.toml` と、それを生成する `Makefile` の `codex-config`。
- 非変更対象: `bin/gh` の token 保存先、`GH_TOKEN` の Codex への継承、gpg-agent socket の場所、GitHub token。
- 入出力: `sandbox_workspace_write.writable_roots` へ `~/.gnupg` を追加することで、GPG の lock file 作成を許可し、同一 agent socket を使う no-tty `pass show` がキャッシュ済みなら成功する。
- 運用方法: 対話端末でキャッシュを温め、Codex は no-prompt GPG option で復号する。キャッシュ切れ時は pinentry を起動せず既存の案内で失敗する。
- 失敗時挙動: config の変更が効かない、または GPG 復号に失敗した場合は token を出力せず既存のエラーで終了する。
- 既存機能への影響: Codex の全 subprocess に `~/.gnupg` への書込みを許可する。GPG config・keyring・agent 関連ファイルを変更し得るため、信頼できるリポジトリでの Codex 起動に限定する必要がある。
- 未確定事項: active config が `Makefile` の生成物か、変更後に Codex の再起動以外の反映手順が必要か。
- ユーザー確認が必要な項目: `~/.gnupg` 全体を Codex sandbox の writable root に追加することの承認。

### 2026-10-07 10:42 : Codex launcher での GitHub token 継承
- 目的: `bin/codex-with-gh` が sandbox 外かつ TTY のある段階で GitHub token を復号し、Codex 内の `gh` が `pass + gpg` を実行せず利用できるようにする。
- 変更対象: `bin/codex-with-gh` と、token を使わない fixture 検証スクリプト。
- 非変更対象: `bin/gh` の token 保存方法・通常実行時の復号、Codex sandbox の writable roots、`~/.gnupg`、GitHub token の権限・値。
- 入出力: 入力は `pass show github/cli-token` の先頭行と任意の Codex 引数。出力はその値を `GH_TOKEN` として環境に持つ `codex "$@"` の実行であり、token は stdout・stderr・引数に出さない。
- 運用方法: `codex-with-gh` は既存の `gh --ensure-auth` により初回登録・対話認証導線を維持した後、token を取得して `GH_TOKEN="$token" exec codex "$@"` を実行する。
- 失敗時挙動: token 取得が失敗・空値の場合は Codex を起動せず、token を含まないエラーを stderr に出して非 0 終了する。
- 既存機能への影響: Codex とその sandbox 内の子プロセスは `GH_TOKEN` を読める。`.gnupg` への書込み許可は追加しない。
- 未確定事項: なし。OpenAI Docs の `shell_environment_policy.ignore_default_excludes` は既定で token 名を含む環境変数を保持するとしている。実装後は fake token を使い、実 Codex sandbox で `GH_TOKEN` の有無だけを検証する。
- ユーザー確認: 2026-10-07 に、`GH_TOKEN="$token" exec codex "$@"` で launcher から Codex へ限定継承する方針を合意。

### 2026-10-07 10:42 : no-tty gh の環境 token 必須化
- 目的: no-tty 実行では `pass` と GPG を一切起動せず、`GH_TOKEN` が設定済みの場合だけ gh を実行する。
- 変更対象: `bin/gh` と既存 no-tty fixture。
- 非変更対象: TTY がある場合の `pass + gpg` 復号・token 更新導線、`bin/codex-with-gh` の token 継承、token 保存先。
- 入出力: `GH_TOKEN` と TTY 有無を入力に、token ありでは `/usr/bin/gh` 実行、token なしの no-tty では復号せず token 設定を求めるエラーを出力する。
- 運用方法: Codex は launcher が継承した `GH_TOKEN` を使う。他の no-tty 実行では呼出元が `GH_TOKEN` を設定する。
- 失敗時挙動: `GH_TOKEN` 未設定の no-tty 実行は `pass`、GPG、pinentry を起動せず非 0 終了する。
- 既存機能への影響: no-tty で GPG agent キャッシュを用いる復号は利用できなくなる。対話端末では既存の認証方式を維持する。
- 未確定事項: なし。
- ユーザー確認: 2026-10-07 に、no-tty では `GH_TOKEN` を必須とし復号を行わない方針を合意。

### 2026-10-07 10:42 : 最小環境での Codex session token 継承
- 目的: GitHub token は `pass + gpg` にのみ保存し、TTY の `codex-with-gh` が復号した token を起動する Codex session にだけ渡す。
- 変更対象候補: `bin/codex-with-gh`、同 launcher の fixture、必要なら `Makefile` の生成設定。
- 非変更対象: `pass + gpg` の保存方式、`~/.gnupg` の sandbox 権限、GitHub CLI の credential store、global な Codex config の環境継承方針。
- 入出力: TTY launcher が `pass show github/cli-token` の先頭行を入力に、最小化した環境で `GH_TOKEN` を持つ Codex session を出力する。Codex session 外・他 session・tmux server には token を渡さない。
- 運用方法: launcher は起動時だけ復号し、Codex の child command には `shell_environment_policy.inherit = "all"` を一回限り指定して `GH_TOKEN` を継承させる。
- 失敗時挙動: token 復号失敗時は Codex を起動しない。環境継承が失敗すれば `bin/gh` は no-tty の `GH_TOKEN` 未設定エラーで終了する。
- 既存機能への影響: Codex session は `GH_TOKEN` を読める。一方で `env -i` により launcher 親の不要な環境変数・他の credential を Codex に渡さない。
- 未確定事項: 最小環境に残す非 secret 変数の範囲。
- ユーザー確認: 2026-10-07 に、`pass + gpg` を維持し、session 限定で `GH_TOKEN` を渡す方針を合意。

## Plan

### 2026-10-07 12:16 : Git credential helper の対話的 GPG 復号
- [x] `auth git-credential` と `/dev/tty` の利用可能性を起動時に判定し、通常の stdin/stderr TTY 判定と区別する。
- [x] credential helper に限り、制御端末を `GPG_TTY` に設定して既存の `pass` 復号経路へ進める。
- [x] 制御端末のない credential helper、一般の no-TTY `gh`、`GH_TOKEN` 設定済み経路が従来どおりであることを fixture で確認する。
- [x] 構文・fixture・差分チェックを実行し、実 terminal の `git pull` による pinentry/credential の確認手順を Review に記録する。

#### 2026-10-07 15:19 : cache 切れ pinentry の再計画
- [x] credential helper 専用の `pass show` を `/dev/tty` stdin で実行し、Git credential protocol stdin を変更しない。
- [x] credential helper での復号失敗を token 未設定として登録へ進めず、復号失敗として終了する。
- [x] fixture で、credential helper の `pass` が TTY stdin を受けること、no-TTY では `pass` を実行しないこと、通常 TTY の登録導線が維持されることを確認する。
- [x] 構文・fixture・差分チェックを実行し、実 terminal での cache 切れ `git pull` 確認を Review に記録する。

#### 2026-10-07 15:37 : 10b917c の credential helper 互換復元
- [x] `auth git-credential` を識別し、当該経路だけ一般 no-TTY の早期エラー対象から外す。
- [x] helper の `/dev/tty` 操作・GPG_TTY 上書き・単発復号を撤去し、`10b917c` と同じ `pass show` 経路を使う。
- [x] fixture で helper が親の `GPG_TTY` を維持して `pass` を実行すること、一般 no-TTY が `pass` を実行しないこと、helper の復号失敗が登録導線へ進まないことを確認する。
- [x] 構文・fixture・差分チェックを実行し、実 terminal の `git pull` 確認を Review に記録する。

### 2026-10-07 10:42 : gh 認証の現行仕様調査
- [x] 関連スクリプト、Git 履歴、既存の認証調査記録を確認する。
- [x] 対話・非対話・`--ensure-auth`・Codex 起動時の分岐を静的に確認する。
- [x] 確認結果と制約を Review に記録し、ユーザーへ報告する。

### 2026-10-07 10:42 : no-tty Codex の gh 認証対策検討
- [x] GPG agent キャッシュ、Codex sandbox、token 継承の制約を整理する。
- [x] token を Codex に渡さず、共有 gpg-agent キャッシュだけを使う方針の合意を得る。
- [x] `pass` の GPG option 注入と GnuPG の `--pinentry-mode error` 対応を確認する。
- [x] no-tty の `pass show` にだけ `--batch --pinentry-mode error` を付与する helper を実装する。
- [x] no-tty の失敗時メッセージを、別端末での無表示復号手順に更新する。
- [x] fake `pass` とネットワーク不要の `/usr/bin/gh --version` で、no-tty の option 付与、token 非出力、成功実行、失敗時の pinentry 非起動指定、TTY 時の既存挙動維持を検証する。
- [x] `sh -n`、`git diff --check`、基準ブランチ `master` との差分を確認し、Review に結果を記録する。

#### 2026-10-07 10:42 : TTY 判定の再計画
- 変更理由: token の存在確認は stdout/stderr を `/dev/null` にリダイレクトしているため、`show_token()` の内部で TTY を判定すると、元の起動が対話端末でも no-tty と誤判定する。これは対話時の pinentry 利用を維持する HLD に反する。
- 変更内容: `bin/gh` 起動直後に stdin/stderr の TTY 有無を一度だけ記録し、`show_token()` はその記録値で通常 GPG と no-prompt GPG を分岐する。fixture の疑似 TTY 実行では実システムの `PATH` を保持する。
- 変更なし: no-tty 時の `--batch --pinentry-mode error` 強制、token 非出力、Codex への `GH_TOKEN` 非継承。

### 2026-10-07 10:42 : Codex launcher での GitHub token 継承
- [x] OpenAI Docs の環境変数継承設定と、`GH_TOKEN` を Codex に渡す方針を確認する。
- [x] HLD の目的・token の露出範囲・失敗時挙動を合意する。
- [x] `bin/codex-with-gh` で既存の対話認証完了後に token を取得・検証し、`GH_TOKEN="$token" exec codex "$@"` を実装する。
- [x] fake `gh` / `pass` / `codex` で、token が Codex の環境にだけ渡ること、引数が保持されること、token 取得失敗時には Codex を起動しないこと、token が出力されないことを検証する。
- [ ] fake `GH_TOKEN` を使い、実 Codex sandbox で token 値を出力せず環境変数が設定されていることを検証する（実行中 sandbox 内での nested sandbox 作成が app-server socket directory 権限エラーで失敗したため、実機 launcher で確認が必要）。
- [x] `sh -n`、`git diff --check`、`git diff master --check` を実行し、Review に修正内容と検証結果を記録する。

### 2026-10-07 10:42 : 最小環境での Codex session token 継承
- [x] `pass + gpg` を維持し、session 限定で `GH_TOKEN` を渡す HLD をユーザーと合意する。
- [x] 維持する非 secret 環境変数を `HOME`、`PATH`、`USER`、`TERM`、`LANG`、`LC_*`、`TZ`、`TMPDIR`、`XDG_RUNTIME_DIR` と合意する。`SSH_AUTH_SOCK` とその他の親環境変数は渡さない。
- [x] `bin/codex-with-gh` を Bash 化し、許可した環境変数だけで Codex を起動する。
- [x] token を argv・stdout・stderr へ出さず pipe で child shell へ渡し、元の TTY stdin を復元して `GH_TOKEN="$token" exec codex -c 'shell_environment_policy.inherit="all"'` を実行する。
- [x] fake `gh` / `pass` / `codex` で token・必要な環境変数・Codex config override・引数・TTY stdin の継承、不要な secret・`SSH_AUTH_SOCK` の非継承、失敗経路、token 非出力を検証する。
- [x] 実機の tmux `Alt-p c` 起動後、Codex 内で token 値を表示せず `test -n "$GH_TOKEN"` と `gh auth status` を確認する。
- [x] `bash -n`、fixture、`git diff --check`、`git diff master --check` を実行し、Review に記録する。

### 2026-10-07 10:42 : no-tty gh の環境 token 必須化
- [x] HLD の no-tty 分岐・影響範囲をユーザーと合意する。
- [x] `GH_TOKEN` 未設定の no-tty 分岐を `pass` 実行より前に追加する。
- [x] fixture で no-tty token なしの場合に fake `pass` が呼ばれないこと、token ありの場合に gh 実行へ進むこと、TTY 時の既存復号経路を検証する。
- [x] `sh -n`、`git diff --check`、`git diff master --check` を実行し、Review に修正内容と検証結果を記録する。

## Review

### 2026-10-07 12:16 : Git credential helper の対話的 GPG 復号
- 原因: `credential.https://github.com.helper` は `!/home/sano/bin/gh auth git-credential` を呼び出す。Git は credential protocol を stdin pipe で渡すため、親が対話 terminal でも `bin/gh` は stdin/stderr 両方の TTY を要求する既存判定で no-TTY と誤判定していた。
- 修正内容: `auth git-credential` に限り、読み書き可能な `/dev/tty` から端末名を取得できれば対話可能とみなし、その値を `GPG_TTY` に設定する。credential protocol の stdin/stdout は変更せず `/usr/bin/gh auth git-credential` に渡す。制御端末がなければ `pass` / GPG / pinentry を呼ばず、従来どおり `GH_TOKEN` を要求して終了する。
- 検証: `sh -n bin/gh`、fixture の構文確認、`ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-codex-with-gh.sh`、`git diff --check`、`git diff master --check` が成功した。fixture は no-TTY の credential helper が `pass` を呼ばないこと、疑似 terminal で credential helper が `pass` を呼び `GPG_TTY=/dev/pts/...` を渡すこと、credential protocol の password 応答を確認した。
- 実機確認: 実 terminal の `git pull` で、GPG cache が切れていれば pinentry が terminal に表示され、認証後に pull が継続することを確認する必要がある。
- 追随修正: 制御端末のない Git hook 実行で `/dev/tty` の open error が stderr に漏れることを検出した。`tty` の stderr リダイレクトを input リダイレクトより先に評価する順序へ直し、no-TTY credential helper fixture で `/dev/tty` という診断が出ないことを確認した。

### 2026-10-07 15:19 : cache 切れ pinentry の再計画
- 原因: credential helper の cache 切れ初回に `GPG_TTY` を設定しても、`pass show` の stdin が Git credential protocol の pipe のままだった。その結果、pinentry が対話を開始できず、復号失敗を既存の token 未設定・登録導線が誤って処理していた。手動 `pass show` で cache を温めた後に `git pull` が成功する再現報告と一致する。
- 修正内容: credential helper で制御端末を検出できたときだけ、`show_token` 内の `pass show` 子プロセスへ `< /dev/tty` を指定する。これは Git credential protocol の親 stdin を変更しないため、後続の `/usr/bin/gh auth git-credential` は元の request を受け取る。credential helper の復号失敗は token 未設定として `pass insert` を起動せず、復号失敗メッセージで終了する。
- 検証: `sh -n bin/gh`、fixture の構文確認、`ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-codex-with-gh.sh`、`git diff --check`、`git diff master --check` が成功した。fixture は疑似 terminal で credential helper の fake `pass` が `GPG_TTY=/dev/pts/...` と TTY stdin を受けること、token 非設定の no-TTY helper は `pass` を呼ばないこと、復号失敗時は登録導線へ進まないことを確認した。
- 実機確認: cache を切らした terminal の `git pull` で pinentry が表示され、認証後に pull が継続することを確認する必要がある。

### 2026-10-07 15:27 : pinentry stderr の再計画
- 原因: `/dev/tty` stdin を渡した単独 `pass show` は成功したため、stdin 切替は有効だった。credential helper の wrapper だけが token 存在確認を `>/dev/null 2>&1` で行い、cache 切れの pinentry/GPG に必要な stderr を捨てていた。
- 修正内容: credential helper は無出力の事前存在確認を廃止し、`pass show` を一度だけ command substitution で実行する。token の stdout は shell 変数に閉じ、stderr は terminal に残す。失敗時は復号エラーを返し、登録導線に進まない。
- 検証: `sh -n bin/gh`、fixture の構文確認、`ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-codex-with-gh.sh`、`git diff --check`、`git diff master --check` が成功した。credential helper の fixture は成功・復号失敗の双方で `pass` を一度だけ実行し、TTY stdin を受けることを確認した。
- 実機確認: `gpgconf --kill gpg-agent` と `git credential-cache exit` の後に terminal の `git pull` を実行し、pinentry 表示と Git 操作の継続を確認する必要がある。

### 2026-10-07 15:37 : 10b917c の credential helper 互換復元
- 原因: `9145c7e` が一般 no-TTY の GPG 復号を止めたことで、過去に機能していた Git credential helper の `pass show` 経路も同時に失われた。後続の `/dev/tty` / GPG_TTY 上書きによる pinentry 起動拡張は、実機で `ENXIO` となり不成立だった。
- 修正内容: `auth git-credential` を識別し、`GH_TOKEN` 未設定でも `10b917c` と同じ通常の `pass show` 経路を使う。helper の `/dev/tty` stdin 操作、GPG_TTY 上書き、単発復号分岐を撤去した。親 fish が export した `GPG_TTY` は変更しない。その他の no-TTY 呼出しは、従来どおり `GH_TOKEN` 未設定で `pass` を呼ばず終了する。
- 検証: `sh -n bin/gh`、fixture の構文確認、`ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-codex-with-gh.sh`、`git diff --check`、`git diff master --check` が成功した。fixture は helper が親 `GPG_TTY` を維持して `pass` を呼び credential protocol を返すこと、helper の復号失敗が登録導線へ進まないこと、一般 no-TTY が `pass` を呼ばないことを確認した。
- 実機確認: 対象 terminal の fish が `GPG_TTY` を export している状態で、`git pull` を実行して過去と同じ helper 経路が動作することを確認する必要がある。

### 2026-10-07 10:42 : gh 認証の現行仕様調査
- 該当履歴: 2026-04-07 の `62806b1`（`Codex用のGH認証とGPG設定を整備`）で、`pinentry-curses` と `GPG_TTY` を整備し、非対話時は `pass insert` を起動せず、事前の `gh --ensure-auth` を促す仕様になった。2026-04-09 の `8c356c5` は token 更新用の `gh auth update-token` を追加した変更である。
- 現行 `bin/gh`: `GH_TOKEN` が設定済みなら `pass` / GPG を実行しない。未設定なら、対話・非対話を問わず最初に `pass show github/cli-token >/dev/null` を実行する。失敗時だけ、非対話では token 登録をせずエラー終了する。成功時は token 取得のため `pass show` をもう一度実行し、子プロセスの `GH_TOKEN` として `/usr/bin/gh` に渡す。
- 現行 `bin/codex-with-gh`: 常に `gh --ensure-auth >/dev/null` を実行してから `codex` を起動する。この呼び出しでも上記の `pass show` / GPG 復号は行うが、`--ensure-auth` は token を export する前に終了するため、Codex には `GH_TOKEN` を引き渡さない。
- 結論: ユーザーの認識どおり、`GH_TOKEN` が外部から渡されない限り Codex 内で `gh` を使うたびに `pass + gpg` が必要となる。既存の 2026-08-31 調査では、Codex sandbox 内の `pass show` は `~/.gnupg` へ lock file を作れず、`can't connect to the gpg-agent: Read-only file system` で失敗することを実測済みである。従って、現在の launcher は「起動前に認証を促す」だけで、Codex 内での gh 利用を成立させる token 引継ぎにはなっていない。
- 検証: `sh -n bin/gh`、`sh -n bin/codex-with-gh`、`git diff --check` は成功。実 token を扱う実行テストは行わなかった。
- lesson 最終確認: `codex-lesson --ai-base ai check` は vector 検索不可（`sqlite_vec` 未導入）だったため、`ai/tasks/lessons.md` を全件確認した。認証・token・シークレット関連の Rule と矛盾する報告はない。

### 2026-10-07 10:42 : no-tty での pinentry 起動リスク訂正
- 原因: GPG agent キャッシュの有効性を `pass show` の成否で判定すればよいと説明したが、キャッシュ切れ時には `pass show` が pinentry-curses の起動を試みる。Codex の no-tty 実行において UI 出力が表示崩れを起こす可能性を考慮していなかった。
- 訂正: Codex 内では、キャッシュ切れ時に pinentry を起動しないことを明示的に保証する必要がある。単なる `pass show` の試行をキャッシュ判定としては採用しない。

### 2026-10-07 10:42 : no-tty Codex の gh 認証対策
- 原因: `bin/gh` は non-interactive な `pass show` でも通常の GPG 起動を使うため、gpg-agent のキャッシュ切れ時に pinentry-curses を起動し得た。一方で `GH_TOKEN` を Codex へ継承する方式は token を Codex の子プロセスへ公開するため採用しない。
- 修正内容: 起動時に TTY 有無を記録し、no-tty 起動時の token 読出しに限って `PASSWORD_STORE_GPG_OPTS` へ `--batch --pinentry-mode error` を追加した。キャッシュ済みの GPG agent は通常どおり復号でき、キャッシュ切れ時は pinentry を起動せず失敗する。対話端末からの起動は従来どおりの GPG option と pinentry を使う。失敗時メッセージは、別の対話端末で `pass show github/cli-token >/dev/null` を実行する手順へ更新した。
- TTY 判定の注意: token 存在確認は stdout/stderr を `/dev/null` にリダイレクトするため、helper 内ではなくスクリプト起動時に TTY 状態を記録する。これにより、対話端末の事前確認を誤って no-tty 扱いしない。
- 検証: `bash -n bin/gh`、`sh -n ai/tasks/workspace/gh-no-tty-test-bin/pass`、`sh -n ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-gh-no-tty.sh`、`git diff --check`、`git diff master --check` が成功した。fixture は `GH_TOKEN` をコマンドごとに unset し、fake `pass` により no-tty の option 付与・token 非出力・失敗時の内部エラー非表示、および疑似 TTY での option 非付与を確認した。通常の `gh` 経路も、ネットワーク不要の `/usr/bin/gh --version` で token を 2 回読出すことを確認した。実 token・実 `pass show` は実行していない。
- 実機 no-tty 確認: `bin/gh --ensure-auth` は exit 1 となり、token を stdout に出さず、pinentry-curses を表示せず、別の対話端末で `pass show github/cli-token >/dev/null` を実行する案内だけを stderr に出した。これはキャッシュ未利用時の想定された失敗挙動である。対話端末で GPG 認証後に同じ Codex session から成功する確認は、実 token を持つ対話端末での操作が必要なため未実施。
- lesson 最終確認: `codex-lesson --ai-base ai check` は vector 検索不可（`sqlite_vec` 未導入）だったため、`ai/tasks/lessons.md` の GPG・認証・秘密出力関連 Rule を照合した。今回の実装・検証は適用対象の Rule に従っている。

### 2026-10-07 10:42 : gpg-agent キャッシュ共有失敗の再調査
- 再現報告: 別環境で、対話 TTY 側では GPG agent のキャッシュが有効にもかかわらず、Codex 側の `gh` は「非対話では復元できない」と失敗した。
- 訂正: no-tty の pinentry 起動を抑止するだけでは、対話端末と Codex が同一の gpg-agent socket に接続できること、または Codex sandbox で GPG が必要な lock file を作成できることを保証しない。
- 次の一次情報: token 本文を stdout に出さず、TTY 側・Codex 側の `gpgconf --list-dirs agent-socket`、`GNUPGHOME`、および no-prompt `pass show` の stderr と終了コードを比較する。
- 原因確定: TTY 側・Codex 側とも `GNUPGHOME=/home/user/.gnupg`、agent socket は `/run/user/1000/gnupg/S.gpg-agent` だった。TTY 側は `--batch --pinentry-mode error` で exit 0 のため agent キャッシュも有効である。Codex 側は `~/.gnupg/.#lk...` を read-only で作成できず、agent 接続に失敗して exit 2 となった。
- 追加検証: `--lock-never` は GnuPG 2.4.8 の正式 option であり、lock file の作成は抑止できた。しかし Codex sandbox では既存 agent への接続に失敗し、`gpg-agent` の起動を試みて General error になった。lock file だけを止めても復号できない。
- 対応判断: `~/.gnupg` を writable root にする案は、読み取り目的に対して書込み権限が広すぎるため採用しない。token も GPG home も sandbox に渡さないなら、GitHub 操作は sandbox 外の認証済みプロセスへ委譲する必要がある。

### 2026-10-07 10:42 : Codex launcher での GitHub token 継承
- 原因: Codex sandbox 内の GPG は `~/.gnupg` が read-only のため、共有 gpg-agent キャッシュが有効でも復号できない。`.gnupg` への書込み許可は権限が広すぎる。
- 修正内容: `bin/codex-with-gh` は既存の `gh --ensure-auth` を通して対話認証・初回登録の導線を維持した後、`pass show github/cli-token` の先頭行を取得・検証する。成功時は `GH_TOKEN="$token" exec codex "$@"` で Codex プロセスにだけ token を渡す。`pass` 不在、復号失敗、空値では Codex を起動しない。
- セキュリティ: token は標準出力・標準エラー・コマンド引数に出さない。Codex とその子プロセスは `GH_TOKEN` を読めるため、信頼できるリポジトリでの起動と、最小権限・短命の token を前提にする。`.gnupg` の writable root は追加しない。
- 検証: fake `gh` / `pass` / `codex` で、起動前の `gh` と `pass` には `GH_TOKEN` がなく、Codex にだけ token が渡ること、引数が保持されること、`pass` と `gh --ensure-auth` の各失敗時に Codex が起動しないこと、成功・失敗時とも token が stdout/stderr に出ないことを確認した。`sh -n bin/gh`、`sh -n bin/codex-with-gh`、fixture の構文確認、`ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-codex-with-gh.sh`、`git diff --check`、`git diff master --check` が成功した。
- 実機 sandbox 検証: fake `GH_TOKEN` を用いた `codex sandbox` は、実行中の sandbox 内で nested sandbox を作る際に `app-server socket directory must be a user-owned directory with mode 0700` で失敗した。token の値は出力されなかった。実機の `codex-with-gh` 起動後に、値を表示しない `test -n "$GH_TOKEN"` で最終確認が必要である。
- lesson 最終確認: `codex-lesson --ai-base ai check` は vector 検索不可（`sqlite_vec` 未導入）だったため、`ai/tasks/lessons.md` の認証・secret 出力・GPG cache 共有関連 Rule を照合した。実装と fixture は適用対象の Rule に従っている。

### 2026-10-07 10:42 : Codex sandbox 内の GPG 復号に関する lesson
- ユーザー指摘: Codex CLI 内では GPG 復号を安全に行えない点を lesson として残す。
- 根拠: `workspace-write` sandbox 内では `~/.gnupg` が read-only で、共有 gpg-agent socket のキャッシュが有効でも GPG が必要とする lock file・状態管理に失敗した。これを回避するため `.gnupg` 全体を書込み可能にすると、読み取り目的に対して権限が広すぎる。

### 2026-10-07 10:42 : Codex の環境継承基礎モードに関する訂正
- ユーザー確認: tmux の `Alt-p c` で起動し、worktree の `origin` は GitHub URL、`$HOME/dotfiles/bin/codex-with-gh` は `GH_TOKEN="$token" exec codex "$@"` を含み、`~/.codex` の user/profile config に明示的な `shell_environment_policy` は存在しない。それでも Codex 内の `gh` は `GH_TOKEN` 未設定と判定した。
- 訂正: `shell_environment_policy.ignore_default_excludes` が既定で true であっても、それだけでは token が子コマンドに継承される保証にならない。`shell_environment_policy.inherit` の基礎継承モードと合わせて検証する必要がある。

### 2026-10-07 10:42 : no-tty gh の環境 token 必須化
- 原因: `GH_TOKEN` が未設定の no-tty 実行でも `bin/gh` が `pass show` を試すため、Codex sandbox 内で GPG 復号を試みる余地が残っていた。
- 修正内容: `GH_TOKEN` の既存分岐直後、`pass` の存在確認・GPG TTY 設定・`pass show` より前に no-tty 判定を追加した。未設定時は `GH_TOKEN` の設定を求めて非 0 終了する。no-tty 用の GPG option 付与 helper は不要になったため、token 読出しは TTY 経路だけの通常 `pass show` にした。
- 検証: `ai/tasks/workspace/test-gh-no-tty.sh` は、no-tty・token 未設定時に fake `pass` が呼ばれずエラーだけを返すこと、`GH_TOKEN` 設定時は fake `pass` を使わず `/usr/bin/gh --version` が成功すること、疑似 TTY では `pass` が呼ばれることを確認した。`sh -n bin/gh`、`sh -n ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-gh-no-tty.sh`、`ai/tasks/workspace/test-codex-with-gh.sh`、`git diff --check`、`git diff master --check` が成功した。

### 2026-10-07 10:42 : 最小環境での Codex session token 継承
- 原因: `codex-with-gh` が `GH_TOKEN` を Codex プロセスへ渡しても、Codex の子コマンドはデフォルトの基礎環境継承で token を受け取れなかった。global config で継承を広げると、他の Codex session にも影響する。
- 修正内容: launcher を Bash に変更し、`HOME`、`PATH`、`USER`、`TERM`、`LANG`、`LC_*`、`TZ`、`TMPDIR`、`XDG_RUNTIME_DIR` だけを新しい環境に残す。token は `env -i` の argv に置かず pipe で child shell へ渡し、child shell は元の stdin を fd 3 から復元して `GH_TOKEN="$token" exec codex -c 'shell_environment_policy.inherit="all"'` を実行する。これにより token は Codex session 内だけで継承され、global `config.toml` は変更しない。
- 検証: `ai/tasks/workspace/test-codex-with-gh.sh` は擬似 TTY で、Codex に `GH_TOKEN`、`LANG`、`TMPDIR`、CLI config override、既存引数、TTY stdin が届くこと、`UNRELATED_SECRET` と `SSH_AUTH_SOCK` は届かないこと、復号・事前認証失敗時に Codex が起動しないこと、token が出力されないことを確認した。`bash -n bin/codex-with-gh`、`sh -n bin/gh`、両 fixture、`git diff --check`、`git diff master --check` が成功した。
- 実機確認: tmux の `Alt-p c` で起動した新規 Codex session で `gh auth status` を実行したところ、`The token in GH_TOKEN is invalid` と出た。これは `GH_TOKEN` が Codex 内の gh へ継承されている一次情報であり、環境継承は成功している。一方、`pass` に保存された token は GitHub 側で無効であるため、対話端末で有効な token へ更新する必要がある。

### 2026-10-07 10:42 : host をまたぐ token 有効性判断の訂正
- ユーザー指摘: `UM880Plus` の対話 terminal では `gh auth status` が成功している。一方、invalid token が出た Codex は `harutaka-bill2` 上で起動しており、同一 host ではない。
- 訂正: 異なる host の `pass` store・GPG key・token 状態を同一とみなして、token 更新を案内してはならない。`UM880Plus` で token 更新は不要であり、`harutaka-bill2` の対話 terminal で `gh auth status` を実行して同 host の保存 token を確認する必要がある。

### 2026-10-07 12:02 : 同一 host であることの再訂正
- ユーザー訂正: invalid token が出た Codex session も `UM880Plus` で実行していた。直前の host が異なるという前提は誤りだった。
- 訂正: TTY の `gh auth status` 成功と Codex の `GH_TOKEN is invalid` は同一 host 上の食い違いである。token 更新の要否はまだ確定しておらず、TTY wrapper と Codex launcher が token を取得・受け渡す経路の値を、token 本文を出さないハッシュ等で比較してから判断する。

### 2026-10-07 12:11 : token 同一性の確認
- 検証結果: TTY で `pass show github/cli-token` の先頭行を launcher と同じ手順で整形した SHA-256 と、Codex 内の `GH_TOKEN` の SHA-256 を、値を出さない一致判定で比較した。結果は `match` だった。
- 判断: launcher の `pass` 取得、先頭行の抽出、pipe による受け渡しは token を変化させていない。TTY の `gh auth status` 成功は、親 fish/tmux に既にある別の `GH_TOKEN` を `bin/gh` が優先している可能性を先に検証する。
- 追加検証: TTY で `env -u GH_TOKEN gh auth status` を実行しても成功した。`bin/gh` は `pass` から token を復号しているため、`pass` 側の token は有効である。次は launcher の最小環境（`env -i`）が原因か、Codex sandbox が原因かを切り分ける。
- 追加検証 2: TTY で launcher と同じ token 抽出を行い、`HOME`、`PATH`、`USER`、`TERM`、`LANG`、`GH_TOKEN` だけの `env -i` から `/usr/bin/gh auth status` を実行しても成功した。最小環境化は原因ではない。Codex sandbox 内の command 解決またはネットワーク経路を調査する。
- 原因確定: Codex 内の `/usr/bin/gh api user` は、ネットワーク許可付き実行で `Authorization: [REDACTED]` を使い `https://api.github.com/user` から HTTP 200 と `irukasano` を返した。通常 sandbox 実行では DNS 通信が遮断される。GitHub CLI の `gh auth status` はこの種の transport failure も `The token in GH_TOKEN is invalid` と表示する既知の誤表示であり、token・launcher・GPG 復号の失敗ではない。
- 回帰検証: `bash -n bin/codex-with-gh`、`sh -n bin/gh`、両 fixture、`git diff --check`、`git diff master --check` は成功した。lesson 最終確認は vector 検索不可（`sqlite_vec` 未導入）のため `ai/tasks/lessons.md` を `rg` で照合し、GPG 復号境界、環境継承、secret 非出力、通信失敗の認証誤判定に関する Rule へ適合していることを確認した。
