#!/usr/bin/env bash
set -euo pipefail

# ===== 設定ここから =====
# Zellij に適用したい layout.kdl のパス
LAYOUT_FILE="$HOME/dotfiles/config/zellij/layouts/codex-develop.kdl"
# ===== 設定ここまで =====

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <worktree-id> [gtr-new-options...]
    - git gtr new <worktree-id> を実行し、
      その worktree を cwd にした Zellij タブを layout 付きで開く

  $(basename "$0") open
    - git gtr list の結果から worktree を選び、
      その worktree を cwd にした Zellij タブを layout 付きで開く
      (fzf が必要)

Examples:
  # worktree を作成して、すぐ Zellij タブで開く
  $(basename "$0") feature/foo

  # gtr のオプションもそのまま渡せます (--from-current 等)
  $(basename "$0") feature/foo --from-current

  # 既存 worktree を選んで開く
  $(basename "$0") open
EOF
}

create_worktree_and_tab() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  # gtr 上での「識別子」
  # 通常はブランチ名または、feature-auth-backend のような worktree 名
  local id="$1"
  shift

  # worktree 作成 (オプションはそのまま git gtr new に渡す)
  git gtr new "$id" "$@"

  # 作成された worktree のパスを取得
  # git gtr go <id> は worktree のフルパスを標準出力します
  local dir
  dir="$(git gtr go "$id")"

  if [[ -z "$dir" ]]; then
    echo "Error: could not resolve worktree path for '$id' via 'git gtr go'." >&2
    exit 1
  fi

  # すでに Zellij セッション内かどうかで挙動を変える
  if [[ -n "${ZELLIJ-}" ]]; then
    # 既存セッション内：新しいタブとして開く
    zellij action new-tab \
      --cwd "$dir" \
      --layout "$LAYOUT_FILE" \
      --name "$id"
  else
    # セッション外：そのディレクトリに移動して新規セッション起動
    cd "$dir"
    zellij --layout "$LAYOUT_FILE"
  fi
}

open_existing_worktree() {
  # fzf が必要
  if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is required for 'open' subcommand." >&2
    exit 1
  fi

  # git gtr list の出力から 1 行選択
  # ※ list --porcelain のフォーマットに依存しないよう、
  #   とりあえず通常の list を使い、1列目を識別子とみなします
  local selected
  selected="$(git gtr list --porcelain | awk -F'\t' '{print $2 "\t" $1 "\t" $3}' | fzf || true)"

  if [[ -z "$selected" ]]; then
    echo "No worktree selected."
    exit 0
  fi

  # 先頭のフィールド(ブランチ名)を worktree の ID とみなす
  # list --porcelain は: path<TAB>branch<TAB>status
  # fzf では: branch<TAB>path<TAB>status を表示している
  local id
  id="$(awk -F'\t' '{print $1}' <<<"$selected")"

  if [[ -z "$id" ]]; then
    echo "Error: could not extract worktree id from selection." >&2
    exit 1
  fi

  local dir
  dir="$(git gtr go "$id")"

  if [[ -z "$dir" ]]; then
    echo "Error: could not resolve worktree path for '$id' via 'git gtr go'." >&2
    exit 1
  fi

  if [[ -n "${ZELLIJ-}" ]]; then
    zellij action new-tab \
      --cwd "$dir" \
      --layout "$LAYOUT_FILE" \
      --name "$id"
  else
    cd "$dir"
    zellij --layout "$LAYOUT_FILE"
  fi
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    open)
      shift
      open_existing_worktree "$@"
      ;;
    -*)
      usage
      exit 1
      ;;
    *)
      create_worktree_and_tab "$@"
      ;;
  esac
}

main "$@"
