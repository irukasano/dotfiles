## Plan

### 2026-06-05 08:58 : notify backhaul sender

- [x] 関連するローカル規約、既存レッスン、過去タスク履歴を確認する
- [x] `bin/notify-backhaul.sh` と通知設定の現状を確認する
- [x] HLD の論点を整理し、未確定事項をユーザー確認する
- [x] 合意済み HLD に基づいて必要な変更を実装する
- [x] スクリプト構文確認と payload 動作確認で検証する
- [x] 変更差分と検証結果を Review に記録する

## Review

### 2026-06-05 08:58 : notify backhaul sender

- 合意仕様: 通知 payload のトップレベル object に `sender` を追加し、値は `SSH_CONNECTION` の 3 番目の要素を優先し、取得できない場合のみ `HOSTNAME` へフォールバックする
- 修正内容: `bin/notify-backhaul.sh` に `resolve_sender` を追加し、`SSH_CONNECTION` の 3 番目を `sender` として解決するようにした
- 修正内容: 送信前に `python3` で payload を JSON として解釈し、トップレベルが object の場合のみ `sender` を追加するようにした
- 修正内容: `SSH_CONNECTION` が欠けている環境向けに `HOSTNAME` フォールバックを維持し、payload 変換成否をログへ残すようにした
- 検証: `bash -n bin/notify-backhaul.sh` が成功した
- 検証: `{"event":"agent-turn-complete"}` に対する変換式の単体実行で `{"event":"agent-turn-complete","sender":"192.168.56.138"}` になることを確認した
- 検証: `XDG_CACHE_HOME=/tmp/codex-cache SSH_CONNECTION='192.168.56.1 49779 192.168.56.138 22' HOSTNAME='fallback-host' bash bin/notify-backhaul.sh ...` 実行時のログで `sender: 192.168.56.138` と `payload_augmented: object sender added` を確認した
- 検証制約: このサンドボックスでは `/dev/tcp/127.0.0.1/53245` が `Operation not permitted` となるため、実 TCP 転送完了まではここでは確認できなかった
