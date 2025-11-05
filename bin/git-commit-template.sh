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

# 3. まず GIT_EDITOR が "code" を含む場合を最初に処理
if [[ "$GIT_EDITOR" == *"code"* ]]; then
  {
    echo "refs"
    echo ""
    cat "$TEMPLATE"
  } > "$COMMIT_MSG"
  git commit -t "$COMMIT_MSG"

else
  # 4. 非 code エディタの場合は codex -> osc52 -> cat の順で処理
  if command -v codex >/dev/null 2>&1; then
    PROMPT=$(mktemp).prompt
    OUTPUT_LAST=$(mktemp).codex
    cat <<'EOF' > "$PROMPT"
以下の内容をもとに日本語でコミットメッセージを作成してください
作成内容をそのままコミットメッセージにできるようバックスラッシュ等でくくらず出力してください

EOF
    cat "$TEMPLATE" >> "$PROMPT"

    # codex でコミットメッセージを生成（標準出力は捨て、最終メッセージのみファイルに保存）
    codex exec ${CODEX_MODEL:+-m "$CODEX_MODEL"} --skip-git-repo-check --output-last-message "$OUTPUT_LAST" - < "$PROMPT" >/dev/null 2>&1 || echo ""

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

    rm -f "$PROMPT" "$OUTPUT_LAST"
  else
    # codex がなければ osc52 -> cat の順
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
