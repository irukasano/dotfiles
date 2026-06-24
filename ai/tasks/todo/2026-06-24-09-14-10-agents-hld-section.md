## HLD

### 2026-06-24 09:14 : AGENTS todo HLD section
- 目的: `ai/tasks/todo/` の記録形式に HLD の保存先を明示し、HLD 合意の運用と記録構造を一致させる
- 変更対象: `config/codex/AGENTS.md` の `タスク管理` と `ai/tasks/todo/ の運用`、必要に応じて `HLD 合意前の実装禁止`
- 非変更対象: 他の運用ルール、既存 todo ファイルの一括変換
- 入出力:
  - 入力: 既存 `AGENTS.md` の運用規約と今回の合意
  - 出力: `## HLD` 配下に依頼ごとの `### ...` を置くことが明文化された `AGENTS.md`
- 運用方法: 新規セッション todo は `## HLD` `## Plan` `## Review` を持ち、各セクション配下に同じ依頼見出しを置いて追記する
- 失敗時挙動: 文言に曖昧さや矛盾が見つかった場合は編集を止めて再整理する
- 既存機能への影響: 今後の記録フォーマットのみ変更し、既存ファイルはそのまま残す
- 未確定事項: なし
- ユーザー確認が必要な項目: `## HLD` 配下に依頼ごとの `###` を置く構成

### 2026-06-24 09:20 : AGENTS HLD first workflow
- 目的: `AGENTS.md` のワークフローと `todo` 構成を、HLD 合意が Plan に先行する依存関係に合わせて整理する
- 変更対象: `config/codex/AGENTS.md` の `タスク管理` と `ai/tasks/todo/ の運用`
- 非変更対象: `HLD` 必須ルールそのもの、既存 todo ファイルの内容移行
- 入出力:
  - 入力: 現在の `AGENTS.md` 文言と今回の合意
  - 出力: `仕様確認 -> HLD 作成/合意 -> Plan 作成/確認 -> Review` の流れが読める `AGENTS.md`
- 運用方法: `todo` は `## HLD` `## Plan` `## Review` の順で保持し、タスク管理表も同じ依存順で読む
- 失敗時挙動: 順序定義が曖昧になる場合は文言を増やさず、依存関係が読める最小差分で止める
- 既存機能への影響: 今後の記録とチェックイン順序の解釈が明確になる
- 未確定事項: なし
- ユーザー確認が必要な項目: `Plan` より前に `HLD` を明示的なステップとして置くこと

### 2026-06-24 09:28 : AGENTS skill reread for plan
- 目的: `Plan` 作成時に会話の記憶だけへ依存せず、使用スキルの必須手順と検証手順を取りこぼさない運用を明文化する
- 変更対象: `config/codex/AGENTS.md` の `計画を立てる`、`ai/tasks/todo/ の運用`、必要に応じて補足禁止事項
- 非変更対象: スキルの内容そのもの、既存 todo ファイルの遡及修正
- 入出力:
  - 入力: 現在の `AGENTS.md` と今回の合意
  - 出力: スキル使用時は `Plan` 作成前に定義を再読し、必須手順を `## Plan` に転記することが明記された `AGENTS.md`
- 運用方法: `Plan` を書くときは、使用するスキルがあれば `SKILL.md` を再読し、必須手順・制約・検証手順をチェック項目へ落とす
- 失敗時挙動: 記憶ベースでしか Plan を組めない状態なら進めず、必要なスキル定義や制約を先に読み直して記録する
- 既存機能への影響: context compress 後も `todo` を読み返せばスキル由来の作業要件を復元しやすくなる
- 未確定事項: なし
- ユーザー確認が必要な項目: スキル使用時の `Plan` は再読・転記ベースで作ること

## Plan

### 2026-06-24 09:14 : AGENTS todo HLD section
- [x] `ai/tasks/lessons.md` と `config/codex/AGENTS.md` を確認する
- [x] この依頼の HLD を整理し、合意内容を記録する
- [x] `config/codex/AGENTS.md` を `## HLD` 構成に合わせて修正する
- [x] 変更後の文面を確認し、todo の Review を記録する

### 2026-06-24 09:20 : AGENTS HLD first workflow
- [x] 現在の `AGENTS.md` のタスク管理と `todo` 構成を確認する
- [x] この依頼の HLD を整理し、順序方針を記録する
- [x] `config/codex/AGENTS.md` のワークフロー順序を HLD 先行に修正する
- [x] 差分確認後に Review を記録する

### 2026-06-24 09:28 : AGENTS skill reread for plan
- [x] 現在の `AGENTS.md` の Plan 関連文言を確認する
- [x] この依頼の HLD を整理し、スキル再読方針を記録する
- [x] `config/codex/AGENTS.md` にスキル再読と転記ルールを追加する
- [x] 差分確認後に Review を記録する

## Review

### 2026-06-24 09:14 : AGENTS todo HLD section
- 原因: `AGENTS.md` では HLD 合意が必須だった一方、`ai/tasks/todo/` の保存構造は `## Plan` と `## Review` しか定義しておらず、HLD の正式な記録先が曖昧だった
- 修正内容:
  - `タスク管理` の `計画を立てる` を HLD を含む表現へ更新
  - `ai/tasks/todo/ の運用` を `## HLD` `## Plan` `## Review` 構成へ拡張
  - `HLD 合意前の実装禁止` に、HLD を当該セッション todo の `## HLD` に記録することを追加
- 検証結果:
  - 更新後の `config/codex/AGENTS.md` を目視確認し、`todo` 構成と HLD 記録先の記述が一貫していることを確認
  - `git diff -- config/codex/AGENTS.md ai/tasks/todo/2026-06-24-09-14-10-agents-hld-section.md` で差分が意図どおりであることを確認

### 2026-06-24 09:20 : AGENTS HLD first workflow
- 原因: `## HLD` を追加しただけでは、タスク管理表の順序がなお `仕様確認 -> 計画 -> Review` 寄りで、HLD が Plan に先行する依存関係が読み取りにくかった
- 修正内容:
  - `タスク管理` に `HLD を作成する` と `HLD を確認する` を追加した
  - `計画を立てる` を「合意済み HLD に基づく `## Plan` 記入」に変更した
  - `ai/tasks/todo/ の運用` に `## HLD` `## Plan` `## Review` をこの順で置くことを明記した
- 検証結果:
  - 更新後の `config/codex/AGENTS.md` を目視確認し、表の順序と `todo` セクション順が一致していることを確認
  - `git diff -- config/codex/AGENTS.md ai/tasks/todo/2026-06-24-09-14-10-agents-hld-section.md` で差分が意図どおりであることを確認

### 2026-06-24 09:28 : AGENTS skill reread for plan
- 原因: `Plan` 作成時に会話の記憶だけへ依存すると、context compress や会話要約を挟んだ際に、スキル定義にある必須手順・制約・検証手順が Plan へ転記されず漏れる懸念があった
- 修正内容:
  - `計画を立てる` を、使用スキルがある場合は定義を再読し、必須手順・制約・検証手順を `## Plan` へ転記する文言に更新した
  - `ai/tasks/todo/ の運用` に、`Plan` へスキル由来の必須事項を漏れなく記録することを追加した
  - 会話の記憶だけを根拠に `Plan` を作成してはいけないことを明記した
- 検証結果:
  - 更新後の `config/codex/AGENTS.md` を目視確認し、`Plan` の作成根拠が HLD とスキル再読に固定されていることを確認
  - `git diff -- config/codex/AGENTS.md ai/tasks/todo/2026-06-24-09-14-10-agents-hld-section.md` で差分が意図どおりであることを確認
