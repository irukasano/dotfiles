#!/bin/bash
set -e

if [ -f .git/MERGE_MSG ] || \
   [ -f .git/REVERT_MSG ] || \
   [ -f .git/CHERRY_PICK_MSG ] || \
   [[ "$@" == *"--amend"* ]]; then
  echo "🛑 特別なGit操作中のため、テンプレートは使用しません"
  git commit "$@"
  exit 0
fi

if git diff --cached --quiet; then
  echo "💡 コミット対象の変更がありません"
  git status
  exit 0
fi

TEMPLATE=$(mktemp).base
COMMIT_MSG=$(mktemp).commit

# 1. コミットメッセージのガイドライン
cat <<'EOF' >> "$TEMPLATE"
#
# 以下の git diff の内容と、「コミットメッセージの書き方」をもとに
# コミットメッセージを平易な日本語でMarkdownで書きます
#
# 💬 コミットメッセージの書き方:
# プレフィクス＋要約
# 空行
# 箇条書きで変更内容の詳細（必要に応じて）
#
#‼️  注意事項
# * プレフィクスは refs または fixes
# * 要約はプレフィクスのあと半角スペース１とあけて 36 文字以内
# * 箇条書きは"*"ではじめ、60文字毎に改行する
#
EOF

# 2. ステージされた git diff をコメント付きで追加
{
  echo ""
  echo "# --- git diff (staged) ---"
  git diff --cached --no-color | sed 's/^/# /'
} >> "$TEMPLATE"

# 3. codex があればコミットメッセージを自動生成
if command -v codex >/dev/null 2>&1; then
  PROMPT=$(mktemp).prompt
  OUTPUT_LAST=$(mktemp).codex
  cat <<'EOF' > "$PROMPT"
以下の内容をもとに日本語でコミットメッセージを作成してください
作成内容をそのままコミットメッセージにできるようバックスラッシュ等でくくらず出力してください

EOF
  cat "$TEMPLATE" >> "$PROMPT"

  # codex でコミットメッセージを生成（標準出力は捨て、最終メッセージのみファイルに保存）
  if codex exec ${CODEX_MODEL:+-m "$CODEX_MODEL"} --output-last-message "$OUTPUT_LAST" - < "$PROMPT" >/dev/null 2>&1; then
    CODEX_MSG=$(cat "$OUTPUT_LAST")

    # COMMIT_MSG ファイルを作成
    {
      echo "$CODEX_MSG"
      echo ""
      echo "by codex : $(date +%s)"
      echo ""
      cat "$TEMPLATE"
    } > "$COMMIT_MSG"

    git commit -t "$COMMIT_MSG"
  else
    # codex 実行に失敗した場合は手動フローへフォールバック
    if [[ "$GIT_EDITOR" == *"code"* ]]; then
      {
        echo "refs"
        echo ""
        cat "$TEMPLATE"
      } > "$COMMIT_MSG"
      git commit -t "$COMMIT_MSG"
    else
      {
        echo "以下の内容をもとに日本語でコミットメッセージを作成してください"
        echo ""
        echo '```'
        cat "$TEMPLATE"
        echo '```'
      } > $COMMIT_MSG

      if command -v osc52.sh >/dev/null 2>&1 && [[ -x "$(command -v osc52.sh)" ]]; then
        cat "$COMMIT_MSG" | osc52.sh

        COMMENT_MSG=$(mktemp).comment
        echo "# クリップボードを ChatGPT に貼り付けしてコミットメッセージを取得してください" > "$COMMENT_MSG"
        git commit -t "$COMMENT_MSG"
        rm -f "$COMMENT_MSG"
      else
        cat "$COMMIT_MSG"
      fi
    fi
  fi

  rm -f "$PROMPT" "$OUTPUT_LAST"

# 4. codex がなければ GIT_EDITOR に応じて分岐
else
  if [[ "$GIT_EDITOR" == *"code"* ]]; then
    {
      echo "refs"
      echo ""
      cat "$TEMPLATE"
    } > "$COMMIT_MSG"
    git commit -t "$COMMIT_MSG"
  else
    # テンプレートを加工：先頭に文言と ```、末尾に ``` を追加
    {
      echo "以下の内容をもとに日本語でコミットメッセージを作成してください"
      echo ""
      echo '```'
      cat "$TEMPLATE"
      echo '```'
    } > $COMMIT_MSG

    if command -v osc52.sh >/dev/null 2>&1 && [[ -x "$(command -v osc52.sh)" ]]; then
      cat "$COMMIT_MSG" | osc52.sh

      COMMENT_MSG=$(mktemp).comment
      echo "# クリップボードを ChatGPT に貼り付けしてコミットメッセージを取得してください" > "$COMMENT_MSG"
      git commit -t "$COMMENT_MSG"
      rm -f "$COMMENT_MSG"

    else
      cat "$COMMIT_MSG"
    fi
  fi
fi


# 5. テンプレートファイル削除
rm -f "$TEMPLATE"
rm -f "$COMMIT_MSG"
