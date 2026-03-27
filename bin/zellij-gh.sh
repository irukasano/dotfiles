#!/usr/bin/env bash
set -euo pipefail

LAYOUT_FILE="$HOME/dotfiles/config/zellij/layouts/codex-develop.kdl"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") issue
    - open issues assigned to @me, then open or create a matching worktree

  $(basename "$0") pr
    - open open PRs, then open or create a matching worktree
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required." >&2
    exit 1
  fi
}

open_dir_in_zellij() {
  local dir="$1"
  local tab_name="$2"

  if [[ -n "${ZELLIJ-}" ]]; then
    zellij action new-tab \
      --cwd "$dir" \
      --layout "$LAYOUT_FILE" \
      --name "$tab_name"
  else
    cd "$dir"
    zellij --layout "$LAYOUT_FILE"
  fi
}

resolve_worktree_dir() {
  local id="$1"
  local dir
  dir="$(git gtr go "$id")"

  if [[ -z "$dir" ]]; then
    echo "Error: could not resolve worktree path for '$id' via 'git gtr go'." >&2
    exit 1
  fi

  printf '%s\n' "$dir"
}

list_worktrees() {
  git gtr list --porcelain
}

find_worktree_by_branch() {
  local target_branch="$1"
  local path branch status

  while IFS=$'\t' read -r path branch status; do
    [[ -z "${path:-}" || -z "${branch:-}" ]] && continue
    if [[ "$branch" == "$target_branch" ]]; then
      printf '%s\t%s\n' "$branch" "$path"
      return 0
    fi
  done < <(list_worktrees)

  return 1
}

find_worktree_by_issue_number() {
  local issue_number="$1"
  local path branch status

  while IFS=$'\t' read -r path branch status; do
    [[ -z "${path:-}" || -z "${branch:-}" ]] && continue
    if [[ "$branch" =~ \#${issue_number}$ ]]; then
      printf '%s\t%s\n' "$branch" "$path"
      return 0
    fi
  done < <(list_worktrees)

  return 1
}

normalize_slug() {
  local raw="${1:-}"
  local slug

  slug="$(printf '%s' "$raw" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[[:space:]]+/-/g; s/[^a-z0-9_-]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')"

  if [[ -z "$slug" ]]; then
    slug="misc"
  fi

  printf '%s\n' "$slug"
}

char_display_width() {
  local ch="$1"

  if [[ "$ch" =~ [[:ascii:]] ]]; then
    printf '1\n'
  else
    printf '2\n'
  fi
}

fit_display_width() {
  local text="$1"
  local width="$2"

  python3 - "$text" "$width" <<'PY'
import sys
import unicodedata

text = sys.argv[1]
width = int(sys.argv[2])

ellipsis = "..."
ellipsis_width = 3


def char_width(ch: str) -> int:
    if not ch:
        return 0
    if unicodedata.combining(ch):
        return 0
    if ch == "\0":
        return 0
    if unicodedata.east_asian_width(ch) in {"F", "W"}:
        return 2
    return 1


def display_width(value: str) -> int:
    return sum(char_width(ch) for ch in value)

if width <= 0:
    print("")
    sys.exit(0)

if width <= ellipsis_width:
    print(ellipsis[:width].ljust(width))
    sys.exit(0)

result = ""
current = 0

for ch in text:
    w = char_width(ch)

    if current + w > width:
        while current + ellipsis_width > width and result:
            last = result[-1]
            current -= char_width(last)
            result = result[:-1]

        result += ellipsis
        current += ellipsis_width
        break

    result += ch
    current += w

print(result + (" " * max(width - display_width(result), 0)))
PY
}

pad_for_display() {
  fit_display_width "${1:-}" "$2"
}

format_updated_at() {
  local updated_at="${1:-}"

  if [[ -z "$updated_at" ]]; then
    printf '%s\n' "-"
    return 0
  fi

  printf '%s\n' "${updated_at:0:16}" | tr 'T' ' '
}

build_issue_display() {
  local issue_number="$1"
  local title="$2"
  local labels_csv="$3"
  local updated_at="$4"
  local updated_text

  updated_text="$(format_updated_at "$updated_at")"
  printf '#%-6s %s  %s  \033[2m%s\033[0m\n' \
    "$issue_number" \
    "$(pad_for_display "$title" 60)" \
    "$(pad_for_display "$labels_csv" 26)" \
    "$updated_text"
}

build_pr_display() {
  local pr_number="$1"
  local title="$2"
  local branch_name="$3"
  local author="$4"
  local updated_at="$5"
  local updated_text

  updated_text="$(format_updated_at "$updated_at")"
  printf '#%-6s %s  %s  %s  \033[2m%s\033[0m\n' \
    "$pr_number" \
    "$(pad_for_display "$title" 60)" \
    "$(pad_for_display "$branch_name" 20)" \
    "$(pad_for_display "$author" 16)" \
    "$updated_text"
}

prompt_branch_name() {
  local default_value="$1"
  local branch_name

  if [[ ! -t 0 ]]; then
    echo "Error: branch confirmation requires an interactive terminal." >&2
    exit 1
  fi

  read -e -i "$default_value" -p "Branch name: " branch_name

  if [[ -z "${branch_name:-}" ]]; then
    echo "Error: branch name is required." >&2
    exit 1
  fi

  printf '%s\n' "$branch_name"
}

record_delim=$'\037'

select_issue() {
  local number title labels_csv updated_at display issue_rows

  issue_rows="$(
    gh issue list --state open --assignee @me --limit 200 \
      --json number,title,labels,updatedAt \
      --jq '.[] | [(.number | tostring), .title, ((.labels | map(.name)) | join(",")), .updatedAt] | join("\u001f")'
  )"

  while IFS="$record_delim" read -r number title labels_csv updated_at; do
    display="$(build_issue_display "$number" "$title" "$labels_csv" "$updated_at")"
    printf '%s\t%s\t%s\t%s\n' "$display" "$number" "$title" "$labels_csv"
  done <<<"$issue_rows" | fzf --ansi --delimiter=$'\t' --with-nth=1
}

select_pr() {
  local pr_number title branch_name author updated_at display pr_rows

  pr_rows="$(
    gh pr list --state open --limit 200 \
      --json number,title,headRefName,author,updatedAt \
      --jq '.[] | [(.number | tostring), .title, .headRefName, .author.login, .updatedAt] | join("\u001f")'
  )"

  while IFS="$record_delim" read -r pr_number title branch_name author updated_at; do
    display="$(build_pr_display "$pr_number" "$title" "$branch_name" "$author" "$updated_at")"
    printf '%s\t%s\t%s\t%s\t%s\n' "$display" "$pr_number" "$title" "$branch_name" "$author"
  done <<<"$pr_rows" | fzf --ansi --delimiter=$'\t' --with-nth=1
}

create_issue_worktree() {
  local issue_number="$1"
  local labels_csv="$2"
  local first_label default_branch branch_name dir existing branch path

  if existing="$(find_worktree_by_issue_number "$issue_number")"; then
    branch="$(awk -F'\t' '{print $1}' <<<"$existing")"
    path="$(awk -F'\t' '{print $2}' <<<"$existing")"
    open_dir_in_zellij "$path" "$branch"
    return 0
  fi

  first_label="${labels_csv%%,*}"
  default_branch="feature/$(normalize_slug "$first_label")#${issue_number}"
  branch_name="$(prompt_branch_name "$default_branch")"

  git gtr new "$branch_name" --from develop
  dir="$(resolve_worktree_dir "$branch_name")"
  open_dir_in_zellij "$dir" "$branch_name"
}

create_pr_worktree() {
  local pr_number="$1"
  local branch_name="$2"
  local dir existing branch path

  if existing="$(find_worktree_by_branch "$branch_name")"; then
    branch="$(awk -F'\t' '{print $1}' <<<"$existing")"
    path="$(awk -F'\t' '{print $2}' <<<"$existing")"
    open_dir_in_zellij "$path" "$branch"
    return 0
  fi

  git gtr new "$branch_name"
  dir="$(resolve_worktree_dir "$branch_name")"
  open_dir_in_zellij "$dir" "$branch_name"
}

handle_issue() {
  local selected display issue_number title labels_csv

  selected="$(select_issue || true)"
  if [[ -z "$selected" ]]; then
    echo "No issue selected."
    exit 0
  fi

  IFS=$'\t' read -r display issue_number title labels_csv <<<"$selected"
  create_issue_worktree "$issue_number" "$labels_csv"
}

handle_pr() {
  local selected display pr_number title branch_name author

  selected="$(select_pr || true)"
  if [[ -z "$selected" ]]; then
    echo "No PR selected."
    exit 0
  fi

  IFS=$'\t' read -r display pr_number title branch_name author <<<"$selected"
  create_pr_worktree "$pr_number" "$branch_name"
}

main() {
  require_cmd gh
  require_cmd fzf
  require_cmd git
  require_cmd zellij

  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    issue)
      handle_issue
      ;;
    pr)
      handle_pr
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
