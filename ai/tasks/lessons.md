# Lessons
## 表示の情報優先度

- ID: `6be9a63e-4b60-4ba4-8830-467c5fe5db95`
- Rule: 表示フォーマットを提案するときは、識別子を補助情報として主要情報の後ろに置くことを優先して検討する。
- Scope: UI表示設計、情報階層、フォーマット提案
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 不要なプレースホルダを避ける

- ID: `30ed721f-0c1f-42c2-9718-ffd565c7b8e5`
- Rule: 空でも意味が通る UI では、親切さを理由にプレースホルダ文言を追加しない。
- Scope: UI、空状態、入力補助文言
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 引用記法の意味を保つ

- ID: `9e86dc63-a970-4600-8529-d772f9ebfe53`
- Rule: 引用である意味がない補足本文には引用記法を使わず、通常の段落を使う。
- Scope: Markdown、文書作成、引用
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## Bash と Python の stdin 競合

- ID: `0e2427aa-6358-44b4-ad5e-d05390446acd`
- Rule: Bash のパイプ入力を処理する際、Python のプログラム入力に heredoc を使って stdin を競合させない。標準入力データには `python -c` または一時ファイルを使う。
- Scope: Bash、Python、パイプ、標準入力
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 対話 UI 前の認証

- ID: `0aefbf1b-9c2c-4890-9eba-7bb03fc01c97`
- Rule: 全画面対話 UI と認証プロンプトを組み合わせるときは、UI 起動前に親プロセスで認証を完了し、認証情報を子へ引き継ぐ。
- Scope: CLI、fzf、認証、対話 UI
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 既存トークンを継承するラッパー

- ID: `8426d209-886f-4f4c-a7c5-c70beeae7669`
- Rule: 認証を復元する CLI ラッパーは、既存のトークン環境変数があれば認証処理をスキップし、全画面 UI の起動前に認証を完了する。
- Scope: CLIラッパー、fzf、gpg、環境変数、認証
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 認証確認で秘密を出力しない

- ID: `fd201125-0f88-4a10-a484-0db4a5f7daa2`
- Rule: 認証成立だけが目的なら、平文シークレットを stdout に出すフローではなく無出力の確認フローを使う。
- Scope: CLI、認証、シークレット、stdout
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## LLM 入力前の差分文字コード正規化

- ID: `fd690c8b-f5a9-4b1b-9cd2-40f393600a8d`
- Rule: git diff を LLM の入力に渡すときは、非 UTF-8 のファイルが混ざる前提で、入力直前に UTF-8 安全なテキストへ変換する。
- Scope: Git、LLMプロンプト、文字コード、CP932
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## タスク記録の構造を保つ

- ID: `718732a3-9fb8-477d-8c04-336f65b92d8a`
- Rule: タスク記録は依頼ごとの見出し内に Plan と Review を追記し、マージ競合時は双方のタスクブロックを残して解消する。
- Scope: AIタスク管理、Markdown、Gitマージ競合
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 設定生成の冪等性

- ID: `3f9801c6-9bda-4aa7-b9ce-fa4e97bd83e9`
- Rule: 設定ファイルを生成・更新するときは、後続の追記設定を消さない管理範囲または marker を設け、再実行の冪等性を確認する。
- Scope: 設定生成、冪等性、ファイル更新
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 管理済み設定を自動更新しない

- ID: `817aac36-fa65-4646-991b-33165f16970a`
- Rule: 既存の管理済み設定を、ユーザーの明示なしに自動更新しない。生成処理では既存 marker を検出したら更新をスキップする。
- Scope: 設定管理、生成スクリプト、ユーザー承認
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## symlink 前に親ディレクトリを作る

- ID: `f5e9e378-c7d2-4744-8dd1-09d04cd4a8d1`
- Rule: セットアップで symlink を作るときは、初回実行で親ディレクトリがない前提で先に `mkdir -p` を行う。
- Scope: セットアップ、symlink、Bash、初回実行
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## runtime config の実バイナリ検証

- ID: `023a4845-4788-42f3-b915-589054896087`
- Rule: 実行時に読まれる設定へ editor 補助用の schema キーなどを加えたときは、対象バイナリを起動してパース互換性を確認する。
- Scope: runtime config、schema、互換性、設定検証
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## Yazi 設定の非対話検証

- ID: `a1506615-d626-4c91-93ab-cd4418bbd2a4`
- Rule: Yazi の設定変更後は、まず `yazi --debug </dev/null` を実行して設定パースと依存解決を確認する。
- Scope: Yazi、設定変更、非対話検証
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 外部 Lua plugin の API 互換性

- ID: `f8f52ce6-0b0e-426c-9367-8f1e7ad9c71f`
- Rule: 外部 plugin の不具合では README だけに頼らず導入済み実装を確認し、現行ホスト API との名前・仕様のずれを調べる。
- Scope: Lua plugin、ホストAPI、互換性調査、Yazi
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 表示不具合では実データを確認する

- ID: `a87321ad-f6c8-435f-a459-a6c027546c1a`
- Rule: 表示崩れを診断するときは、余白やフォーマットだけでなく、表示元の実データ値を先に確認する。
- Scope: UI、表示不具合、デバッグ、一次情報
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## ラッパーの環境変数の出所を追う

- ID: `5b545710-6902-43f9-b9a2-f7ebb4bd598b`
- Rule: CLI ラッパーの出力に現れる環境変数を親 shell の状態と決めつけず、子プロセスの分岐と export を含む伝播経路を確認する。
- Scope: CLIラッパー、環境変数、プロセス境界、デバッグ
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## ラッパー認証の再取得を区別する

- ID: `a1481642-590e-4b2d-a18c-3ab493df6316`
- Rule: ラッパーが後続コマンドで認証情報を再取得する経路と、親プロセスからの環境変数継承を混同せず、最後の exec まで実装を追って判断する。
- Scope: CLIラッパー、認証、環境変数、exec
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## シークレット出力テストを隔離する

- ID: `46059043-c367-43f3-9751-dfa8535dcf68`
- Rule: シークレットを stdout に出しうる経路の fixture テストでは、対象環境変数をコマンドごとに明示的に unset し、実トークンを出力する分岐に入らないことを確認する。
- Scope: テスト、fixture、シークレット、環境変数、stdout
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## 移行方針と実行手段を分ける

- ID: `2b52b44d-7eb8-4c28-ab52-953a5473922e`
- Rule: データ移行を提案するときは、移行方針と、専用 skill・一回限りの既存コマンド・手作業のどれで実行するかを明示して区別する。
- Scope: データ移行、提案、運用、実行手段
- Review: `ai/tasks/todo/2026-09-25-17-01-48-lesson-migration.md#2026-09-25-1701--lesson`
## no-tty 認証試行で pinentry を起動しない

- ID: `1026e089-0f75-44e2-998c-6fc4ed2ef6cf`
- Rule: no-tty 実行で認証キャッシュの状態を調べるときは、キャッシュ切れ時に pinentry や対話 UI を起動しないことを明示的に保証し、単なる復号試行の成否を判定に使わない。
- Scope: CLIラッパー、GPG、pinentry、no-tty、認証
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1042--no-tty-での-pinentry-起動リスク訂正`
## GPG キャッシュ共有は agent 接続可能性を確認する

- ID: `63b0466c-0708-4f0a-adaa-719ac29b0e72`
- Rule: 対話端末と no-tty sandbox 間で GPG agent キャッシュの共有を前提にするときは、キャッシュ有無だけで成功を判断せず、両環境の agent socket 到達性と GPG の必要なファイル書込み可否を一次情報で確認する。
- Scope: GPG、gpg-agent、sandbox、no-tty、認証
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1042--gpg-agent-キャッシュ共有失敗の再調査`
## Codex sandbox 内で pass と GPG の復号を前提にしない

- ID: `516ecaff-b0d4-4f73-8a02-9435f644346e`
- Rule: Codex CLI の workspace-write sandbox で認証情報を利用する設計では、pass と GPG による sandbox 内の復号を前提にしない。GPG の agent 接続や lock file・状態管理はホームディレクトリへの書込みを要し、書込み許可で回避すると秘密鍵領域への権限を広げすぎる。復号は sandbox 外の信頼境界で完了し、必要な認証情報の受け渡し範囲を明示的に限定する。
- Scope: Codex CLI、workspace-write sandbox、GPG、pass、認証情報、権限境界
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1042--codex-sandbox-内の-gpg-復号に関する-lesson`
## Codex の環境変数継承は基礎モードも確認する

- ID: `a0d9ef3b-957c-4e3a-a0fe-0620d51b7b4f`
- Rule: Codex CLI の子コマンドへ認証用環境変数を渡す設計では、TOKEN 名の自動除外設定だけで継承を判断しない。shell_environment_policy の inherit による基礎継承モードと、実際の sandbox 内での存在確認を合わせて検証する。
- Scope: Codex CLI、shell_environment_policy、環境変数、認証、GH_TOKEN
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1042--codex-の環境継承基礎モードに関する訂正`
## 認証比較は実行経路まで一致させる

- ID: `8e41b8c8-6685-4ace-b5ac-91072451296d`
- Rule: 認証の成否が食い違うときは、host だけでなく token の取得元・変換・受け渡し経路を一致させ、secret 本文を出さないハッシュ等の一次情報で比較してから token の失効や更新要否を判断する。
- Scope: 認証、CLIラッパー、GitHub CLI、pass、GPG、環境変数
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1202--同一-host-であることの再訂正`
## 制限環境の認証表示は通信結果で検証する

- ID: `2eb6010a-b8c7-41b4-b00a-b2bbed68dc2e`
- Rule: ネットワーク制限下の CLI が token invalid と表示しても、認証失敗と断定しない。認証ヘッダーを伏せた API 呼出しの HTTP 応答などで、通信失敗と credential 失効を分けて確認する。
- Scope: 認証、GitHub CLI、Codex sandbox、ネットワーク制限、環境変数
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1211--token-同一性の確認`
## credential helperのTTYはGPG入出力まで切り替える

- ID: `21fe64d7-3b43-41d8-ad03-63fbce55697b`
- Rule: Git credential helper のように標準入力がプロトコル用 pipe で占有される経路で対話的な GPG 復号を行う場合、GPG_TTY の設定だけでなく、復号処理の子プロセスだけの stdin を制御端末へ切り替える。親プロセスの protocol stdin は変更しない。
- Scope: Git credential helper、GPG、pinentry、pass、TTY、標準入力
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1519--cache-切れ-pinentry-の再計画`
## pinentry経路のstderrを捨てない

- ID: `94e7154b-40b5-4788-8846-5631e8f4d7a2`
- Rule: pinentry を起動し得る GPG 復号経路では、存在確認のために stderr を無条件に破棄しない。secret の stdout は command substitution 等で閉じ、pinentry/GPG の対話用 stderr は制御端末へ残す。
- Scope: GPG、pinentry、pass、Git credential helper、TTY、標準エラー、認証
- Review: `ai/tasks/todo/2026-10-07-10-42-01-gh-auth-current-specification-investigation.md#2026-10-07-1527--pinentry-stderr-の再計画`
