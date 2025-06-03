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


TEMPLATE=$(mktemp)

# 0. 空行を2行挿入
echo -e "\n\n" > "$TEMPLATE"

# 1. コミットメッセージのガイドライン
cat <<'EOF' >> "$TEMPLATE"
#
# 以下の git diff の内容と、「コミットメッセージの書き方」をもとに
# コミットメッセージを平易な日本語で書きます
#
# 💬 コミットメッセージの書き方:
# プレフィクス＋要約
# 空行
# 箇条書きで変更内容の詳細（必要に応じて）
#
#‼️  注意事項
# * プレフィクスは refs または fixes
# * 要約はプレフィックスのあと半角スペース１とあけて 36 文字以内
# * 箇条書きは"*"ではじめ、60文字毎に改行する
#
EOF

# 2. ステージされた git diff をコメント付きで追加（エスケープ除去）
{
  echo ""
  echo "# --- git diff (staged) ---"
  git diff --cached --no-color | sed 's/^/# /'
} >> "$TEMPLATE"

# 3. コミットメッセージエディタを起動
if [[ "$GIT_EDITOR" == *"code"* ]]; then
  git commit -t "$TEMPLATE"
else
  echo -e "\n📝 エディタが code 以外のため、テンプレート内容のみ表示します："
  echo "----------------------------------------"
  cat "$TEMPLATE"
  echo "----------------------------------------"
fi

# 4. テンプレートファイル削除
rm -f "$TEMPLATE"


