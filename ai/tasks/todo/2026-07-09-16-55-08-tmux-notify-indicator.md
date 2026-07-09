## HLD

### 2026-07-09 16:55 : tmux notify indicator
- 目的: tmux の通知フラグ `!` を視認しやすい表示へ変更する
- 変更対象: `config/tmux/tmux.conf` の window status format 周辺
- 非変更対象: pane keybind、theme 全体の配色、通知発火条件そのもの
- 入出力:
  - 入力: tmux の `window_flags` / bell flag
  - 出力: status line 上の通知インジケータ表示
- 運用方法: `tmux.conf` を reload すると新しい表示が反映される
- 失敗時挙動: 設定に問題があれば `tmux -f ... start-server` 検証で検出し、既存表示へ戻す
- 既存機能への影響: window status format を明示設定するため、現在 theme が暗黙に出している `window_flags` 表示をこちらで管理する
- 未確定事項:
  - 置換対象を bell の `!` のみに限定するか、`window_flags` 全体を独自表示へ置き換えるか
  - 表示文字を絵文字 `❗` / `🔴` 系にするか、色付き記号にするか
- ユーザー確認が必要な項目:
  - まず bell の `!` だけを赤い強調表示へ置き換える方針でよいか
  - 絵文字を優先するか、フォント依存が少ない記号を優先するか

### 2026-07-09 17:xx : tmux notify spacing cleanup
- 目的: bell 表示時の `🔴 - タブ名` 風の見え方と、bell 非表示時の左余白ずれを解消する
- 変更対象: `config/tmux/tmux.conf` の window status format と flags format
- 非変更対象: bell 通知条件、全体テーマ配色、window index/title の内容
- 入出力:
  - 入力: `window_bell_flag` と `window_flags`
  - 出力: status line 上の bell インジケータと tab 名の並び
- 運用方法: `tmux.conf` reload で反映する
- 失敗時挙動: format が壊れた場合は `tmux -f ... start-server` 検証で検出する
- 既存機能への影響: flags と title の間隔を動的に制御するため、window status の横幅がわずかに変わる
- 未確定事項:
  - bell 表示時に `🔴` とタイトルを直結するか、1 文字分だけ空けるか
- ユーザー確認が必要な項目:
  - `🔴 タブ名` のように 1 スペースだけ残すか、`🔴タブ名` まで詰めるか

## Plan

### 2026-07-09 16:55 : tmux notify indicator
- [x] `AGENTS.md` と `ai/tasks/lessons.md` を確認する
- [x] 現在の `tmux` window status format と通知フラグの出所を確認する
- [x] HLD を整理してユーザー確認を取る
- [x] 合意した範囲だけ `config/tmux/tmux.conf` を修正する
- [x] `TMUX_TMPDIR` を作業ディレクトリ配下へ切り替えて `tmux -f ... start-server` で設定構文を検証する
- [x] Review を記録する

### 2026-07-09 17:00 : tmux notify spacing cleanup
- [x] 現在の format から `-` 風の見え方と左余白の原因を確認する
- [x] HLD を整理してユーザー確認を取る
- [x] 合意した spacing だけ `config/tmux/tmux.conf` を修正する
- [x] `tmux -f ... start-server` で設定構文を再検証する
- [x] Review を記録する

### 2026-07-09 17:10 : tmux last-window flag cleanup
- [x] 実際の `window_flags` を確認して `-` の正体を特定する
- [x] ユーザー合意に沿って表示から `-` を外す方針を確定する
- [x] 合意した範囲だけ `config/tmux/tmux.conf` を修正する
- [x] `tmux -f ... start-server` で設定構文を再検証する
- [x] Review を記録する

### 2026-07-09 17:15 : tmux inactive tab left padding
- [x] inactive tab だけ左寄せになった原因を現在の format から確認する
- [x] inactive tab のみ基準スペースを戻す最小修正を `config/tmux/tmux.conf` に入れる
- [x] `tmux -f ... start-server` で設定構文を再検証する
- [x] Review を記録する

### 2026-07-09 17:20 : tmux visible-flags condition fix
- [x] live の `window_flags` を再確認して条件が効かない原因を特定する
- [x] 表示用 flags と余白判定で同じ「可視 flags」を使うよう `config/tmux/tmux.conf` を修正する
- [x] `tmux -f ... start-server` で設定構文を再検証する
- [x] Review を記録する

## Review

### 2026-07-09 16:55 : tmux notify indicator
- 原因: `!` は tmux 既定の bell フラグではなく、`tmux2k` が `window-status-format` で表示している `#{window_flags}` の中身だった。そのままでは小さく色差も弱く、通知の視認性が低かった
- 修正内容:
  - `config/tmux/tmux.conf` に通常 window 用と current window 用の flags format を追加
  - `window_bell_flag` が立っている場合だけ赤丸 `🔴` を先頭表示し、`window_flags` から `!` を除去するようにした
  - `tmux2k` が生成していた window status format を明示設定し、既存テーマ配色は維持したまま bell 表示だけ差し替えた
- 検証結果:
  - `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-verify start-server \; show -gv window-status-format \; show -gv window-status-current-format` が成功し、更新後の format を tmux が受理することを確認
  - sandbox では tmux ソケット作成が `Operation not permitted` で失敗したため、同コマンドを権限付きで再実行して検証した

### 2026-07-09 17:00 : tmux notify spacing cleanup
- 原因: window title 側に固定の先頭スペースがあり、bell 非表示時でも左余白が残っていた。bell 表示時は `flags` と title の境界が固定区切りとして見え、`🔴 - タブ名` のような違和感につながっていた
- 修正内容:
  - `@window-status-flags` と `@window-status-current-flags` で bell 時の `🔴` にだけ末尾スペースを持たせた
  - `window-status-format` と `window-status-current-format` の title 側先頭スペースを削除し、bell なしでは余白ゼロ、bell ありでは `🔴 タブ名` になるようにした
- 検証結果:
  - `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-verify-2 start-server \; show -gv window-status-format \; show -gv window-status-current-format` が成功し、調整後の format を tmux が受理することを確認
  - この検証も tmux ソケット制約のため権限付きで実行した

### 2026-07-09 17:10 : tmux last-window flag cleanup
- 原因: 通知時に見えていた `-` は title ではなく `window_flags` の `-` で、tmux の last-window フラグだった。live の `tmux list-windows -a -F ...` で通知 window が `flags=[!-]` になっていることを確認した
- 修正内容:
  - `@window-status-flags` と `@window-status-current-flags` で `window_flags` から `!` に加えて `-` も除去するようにした
  - bell 表示は引き続き独立した `🔴` だけを出すため、通知時の表示は `🔴 タブ名` になる
- 検証結果:
  - `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-verify-3 start-server \; show -gv @window-status-flags \; show -gv @window-status-current-flags` が成功し、更新後の置換式を tmux が受理することを確認
  - この検証も tmux ソケット制約のため権限付きで実行した

### 2026-07-09 17:15 : tmux inactive tab left padding
- 原因: `window-status-format` から title 側の固定先頭スペースを外したため、inactive tab のうち通知も他フラグもないケースだけ旧テーマより 1 文字左に寄って見えるようになっていた。active 側は別 format なので影響していなかった
- 修正内容:
  - `window-status-format` の title 直前に `#{?window_flags,, }` を追加し、inactive tab で flags が一切ない場合だけ先頭スペース 1 つを戻した
  - bell や他フラグがある inactive tab では既存の flags 側表示を優先し、余計な二重スペースは入れない
- 検証結果:
  - `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-verify-4 start-server \; show -gv window-status-format` が成功し、調整後の inactive format を tmux が受理することを確認
  - この検証も tmux ソケット制約のため権限付きで実行した

### 2026-07-09 17:20 : tmux visible-flags condition fix
- 原因: live の inactive tab は `flags=[-]` で、`window_flags` 自体は空ではなかった。一方で表示用には `-` を除去していたため、見た目は空でも余白判定だけは「flags あり」のままになり、前回の修正が効かなかった
- 修正内容:
  - `@window-status-visible-flags` を追加し、`window_flags` から `!` と `-` を除去した「実際に表示する flags」を一箇所で定義した
  - inactive tab の表示と左余白判定の両方を `@window-status-visible-flags` と `window_bell_flag` ベースに切り替えた
- 検証結果:
  - `tmux -f /home/sano/dotfiles/config/tmux/tmux.conf -L codex-verify-5 start-server \; show -gv @window-status-visible-flags \; show -gv window-status-format` が成功し、更新後の条件式を tmux が受理することを確認
  - この検証も tmux ソケット制約のため権限付きで実行した
