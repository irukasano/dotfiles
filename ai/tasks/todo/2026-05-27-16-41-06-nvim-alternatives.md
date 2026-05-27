## Plan

### 2026-05-27 16:41 : nvim alternatives task
- [x] 既存の `Makefile`、関連タスク履歴、レッスンを確認する
- [x] `alternatives` / `update-alternatives` の切替方式と既存 `nvim` 導線の整合を整理する
- [x] HLD を作成し、未確定事項をユーザー確認する
- [x] 合意後に必要な `Makefile` 変更を実装する
- [x] `make -n` と安全な確認コマンドで検証する

## Review

### 2026-05-27 16:41 : nvim alternatives task
- 背景: AlmaLinux では `vim` 実行時に Vim 本体が起動し、`~/.config/nvim` と同じ設定ファイルを読んでも見た目が揃わないため、RHEL 系では `alternatives` で `vim` を `nvim` に寄せる明示タスクが必要だった。
- 修正内容: `Makefile` に `nvim-alternative-setting` タスクを追加し、`YUM=apt` のときは skip、`dnf` 系では `alternatives` パッケージを導入してから `nvim` の存在確認を行うようにした。
- 修正内容: `vim` グループに `/usr/bin/nvim` が未登録なら `alternatives --install /usr/bin/vim vim /usr/bin/nvim 30` で登録し、その後 `alternatives --set vim /usr/bin/nvim` で切り替えるようにした。
- 検証: `make -n nvim-alternative-setting` で `dnf` 系の実行内容が `alternatives` 導入、`nvim` 確認、`vim` グループへの登録、`vim -> nvim` 切替の順で生成されることを確認した。
- 検証: `make help | rg "nvim-alternative-setting"` で新規タスクがヘルプに表示されることを確認した。
