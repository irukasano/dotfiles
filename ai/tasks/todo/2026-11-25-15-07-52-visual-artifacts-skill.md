## HLD

### 2026-11-25 15:07 : 画像成果物を使った人間確認スキル

- 目的: 人間が画面・図などを確認しやすい成果物は PNG で作成し、ユーザーに `kitten icat <filename>` で確認する方法を案内する Codex スキルを追加する。
- 変更対象: `config/codex/skills/image-artifacts/SKILL.md` の新規スキル。
- 非変更対象: 既存スキル、Codex 設定、画像生成ツールや既存の成果物。
- 入出力: 作業内容から画像確認が有益な場合に、`AI_BASE_DIR/tasks/workspace` 配下に PNG を作る。ユーザーには生成先と `kitten icat <filename>` を案内する。
- 運用方法: 通常のスキル自動選択に従い、視覚的確認が有益なタスクで適用する。
- 失敗時挙動: PNG を生成できない場合はその制約を説明し、存在しないファイルを案内しない。
- 既存機能への影響: 新規スキルのみ追加。
- 未確定事項: なし。
- ユーザー確認: `image-artifacts` というスキル名と、この HLD の内容で進めることを 2026-11-25 に承認済み。

### 2026-11-25 15:32 : codex-settings から画像スキルを導入

- 目的: `make codex-settings` を実行したときに `image-artifacts` も利用可能にする。
- 変更対象: `Makefile` の `codex-settings` recipe と本タスク記録。
- 非変更対象: `lesson` の導入方法、スキル本文、他の Codex 設定。
- 入出力: `config/codex/skills/image-artifacts` を `$HOME/.codex/skills/image-artifacts` に symlink する。
- 運用方法: 既存の lesson と同様に `ln -sfn` でリンクし、`make codex-settings` で反映する。
- 失敗時挙動: make または symlink 作成が失敗した場合はエラーとして終了する（Makefile の既存コマンド挙動に従う）。
- 既存機能への影響: `codex-settings` が作成するスキルリンクが 1 件増える。
- 未確定事項: なし。
- ユーザー確認: この HLD の内容で変更することを 2026-11-25 に承認済み。

## Plan

### 2026-11-25 15:07 : 画像成果物を使った人間確認スキル

- [x] HLD 合意後に skill-creator の定義を再読する。
- [x] `config/codex/skills/image-artifacts/SKILL.md` を作成する。スキルは PNG 画像だけを対象にし、必要時のみ `AI_BASE_DIR/tasks/workspace` に保存する。
- [x] 生成した画像のファイル名を人間に示し、`kitten icat <filename>` で確認するよう案内する手順を含める。
- [x] skill-creator の `quick_validate.py` でスキル形式を検証する。
- [x] 差分をレビューし、lesson skill の手順に従って lesson を確認する。
- [x] 検証結果を Review に記録する。

## Review

### 2026-11-25 15:07 : 画像成果物を使った人間確認スキル

- 実装: `image-artifacts` を新規作成し、画面案・図・グラフなど人間の目視確認に役立つ画像を PNG で `AI_BASE_DIR/tasks/workspace/` に保存し、成功を確かめた後に実パスの `kitten icat <filename>` コマンドを案内する手順を記載した。HTML 等の非画像成果物は対象外と明記した。
- 検証: skill-creator の `quick_validate.py` は `Skill is valid!`。`git diff --check` は成功。差分対象は新規スキルと本タスク記録のみ。
- Lesson 最終確認: `codex-lesson check` で vector search と index が利用可能。最上位 5 件を Scope で確認し、該当するタスク記録構造 lesson の Review を参照した。HLD / Plan / Review の記録単位を維持した。ほかの 4 件は本スキルの適用領域外で、追加対応なし。

### 2026-11-25 15:32 : codex-settings から画像スキルを導入

- [x] HLD の合意を得る。
- [x] `codex-settings` に `image-artifacts` の symlink 作成を追加する。
- [x] Makefile の recipe を実行し、symlink の参照先を検証する。
- [x] 差分を確認し、Review に結果を記録する。

### 2026-11-25 15:32 : codex-settings から画像スキルを導入

- 変更: `Makefile` の `codex-settings` に `config/codex/skills/image-artifacts` から `$HOME/.codex/skills/image-artifacts` への `ln -sfn` を追加した。
- 検証: `make codex-settings` が成功し、`readlink "$HOME/.codex/skills/image-artifacts"` が `/home/sano/dotfiles/config/codex/skills/image-artifacts` を返すことを確認した。
- 影響: `make codex-settings` によって既存ターゲットの symlink も通常どおり再適用された。
- Lesson 最終確認: vector 検索可能。上位 5 件を確認し、symlink の親ディレクトリを先に作る lesson の Review を確認した。ターゲットには既存の `mkdir -p "$HOME/.codex/skills"` があり、今回のリンクにも適用済み。残り 4 件は今回の変更の適用領域外。
