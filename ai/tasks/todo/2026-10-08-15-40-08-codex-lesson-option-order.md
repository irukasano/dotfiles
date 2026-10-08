## HLD

### 2026-10-08 15:40 : codex-lesson オプション順序の調査

- 目的: `codex-lesson` が `--ai-base` を誤った位置で実行される原因を調査する。
- 変更対象: `config/codex/skills/lesson/SKILL.md` の `check` 実行例、調査記録および再発防止 lesson。
- 非変更対象: `codex-lesson` の CLI 仕様、他の subcommand の文書、依存関係。
- 入出力: ユーザー提示ログを入力に、一次情報に基づく原因と影響範囲を出力する。
- 運用方法: global option はサブコマンドより前に置く。変更後に同一コマンドを実行し、commit・push する。
- 失敗時挙動: 検証または push が失敗した場合は、成功した変更だけを記録し、失敗内容を報告する。
- 既存機能への影響: skill が参照する実行例のみ修正され、CLI の挙動は不変。
- 未確定事項: なし。
- ユーザー確認が必要な項目: 2026-10-08 に、当該文書の修正、commit、push をユーザーが明示承認。

## Plan

### 2026-10-08 15:40 : codex-lesson オプション順序の調査

- [x] skill 文書と CLI の argparse 定義を照合する。
- [x] ユーザー指摘を Review に記録し、再発防止 lesson を追加する。
- [x] `check` の例を global option がサブコマンドに先行する構文へ修正する。
- [x] 実コマンド、差分整合性、lesson 検証を実行する。
- [x] 対象変更を commit する。
- [ ] 現在の upstream へ push する。

## Review

### 2026-10-08 15:40 : codex-lesson オプション順序の調査

- 原因: `config/codex/skills/lesson/SKILL.md` が `codex-lesson check --ai-base "$AI_BASE_DIR"` と記載している。一方、CLI は `--ai-base` をサブコマンド前に定義する global option としているため、この例は usage error になる。
- 修正内容: 本ターンでは診断のみ。ユーザー指摘を lesson として記録する。
- 検証: `codex-lesson --ai-base ai check` は `sqlite_vec` 未導入のためベクトル検索不可と報告した。フォールバックとして `ai/tasks/lessons.md` を `rg` で照合し、追加 lesson と CLI 文書に関する既存 Rule を確認する。
- ユーザー承認: 2026-10-08 に `SKILL.md` の修正、commit、push を明示依頼された。
- 修正内容: `SKILL.md` の `check` 例を `codex-lesson --ai-base "$AI_BASE_DIR" check` に修正した。
- 検証: 正しい順序で `codex-lesson --ai-base ai check` が成功し、`test-codex-lesson.sh` の Markdown-only fixture も成功した。旧構文が skill 文書に存在しないこと、新構文が存在すること、対象差分の `git diff --check` 成功を確認した。
- lesson 最終確認: `codex-lesson --ai-base ai check` は `sqlite_vec` 未導入のためベクトル検索不可だった。フォールバックで `ai/tasks/lessons.md` の Rule と Scope を照合し、今回追加した「global option はサブコマンド前に置く」以外に適用すべき指摘はなかった。
- commit: `fb80ed3 fix(codex): correct lesson command option order` を作成した。
