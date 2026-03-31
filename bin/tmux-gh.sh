#!/usr/bin/env bash
set -euo pipefail

LAYOUT_SCRIPT="$HOME/dotfiles/config/tmux/bin/layout-dev.sh"
SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
CACHE_TTL_SECONDS=60

usage() {
  cat <<EOF
Usage:
  $(basename "$0") issue
    - open issues assigned to @me, then open or create a matching worktree in tmux

  $(basename "$0") pr
    - open open PRs, then open or create a matching worktree in tmux
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required." >&2
    exit 1
  fi
}

cache_dir() {
  local user_name="${USER:-user}"
  printf '/tmp/tmux-gh-%s\n' "$user_name"
}

cache_file_for_mode() {
  local mode="$1"
  printf '%s/%s.list' "$(cache_dir)" "$mode"
}

cache_meta_file_for_mode() {
  local mode="$1"
  printf '%s/%s.updated_at' "$(cache_dir)" "$mode"
}

ensure_cache_dir() {
  mkdir -p "$(cache_dir)"
}

current_epoch() {
  date +%s
}

cache_is_fresh() {
  local mode="$1"
  local cache_file meta_file now updated_at age

  cache_file="$(cache_file_for_mode "$mode")"
  meta_file="$(cache_meta_file_for_mode "$mode")"

  [[ -f "$cache_file" && -f "$meta_file" ]] || return 1

  updated_at="$(<"$meta_file")"
  [[ "$updated_at" =~ ^[0-9]+$ ]] || return 1

  now="$(current_epoch)"
  age=$((now - updated_at))
  (( age >= 0 && age < CACHE_TTL_SECONDS ))
}

open_dir_in_tmux() {
  local dir="$1"
  local tab_name="$2"
  local session_name pane_id

  if [[ -n "${TMUX-}" ]]; then
    pane_id="$(tmux new-window -P -F '#{pane_id}' -c "$dir" -n "$tab_name")"
  else
    IFS=$'	' read -r session_name pane_id <<<"$(tmux new-session -d -P -F '#{session_name}	#{pane_id}' -c "$dir" -n "$tab_name")"
  fi

  "$LAYOUT_SCRIPT" "$pane_id" "$dir"

  if [[ -z "${TMUX-}" ]]; then
    cd "$dir"
    exec tmux attach-session -t "$session_name"
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

format_selection_rows() {
  local mode="$1"

  python3 -c '
import sys
import unicodedata

mode = sys.argv[1]
rows = [line.rstrip("\n").split("\x1f") for line in sys.stdin]

ELLIPSIS = "..."
ELLIPSIS_WIDTH = 3


def char_width(ch: str) -> int:
    if not ch or ch == "\0" or unicodedata.combining(ch):
        return 0
    if unicodedata.east_asian_width(ch) in {"F", "W"}:
        return 2
    return 1


def display_width(value: str) -> int:
    return sum(char_width(ch) for ch in value)


def fit_display_width(text: str, width: int) -> str:
    if width <= 0:
        return ""
    if width <= ELLIPSIS_WIDTH:
        return ELLIPSIS[:width].ljust(width)

    result = []
    current = 0

    for ch in text:
        w = char_width(ch)
        if current + w > width:
            while current + ELLIPSIS_WIDTH > width and result:
                current -= char_width(result.pop())
            result.append(ELLIPSIS)
            current += ELLIPSIS_WIDTH
            break
        result.append(ch)
        current += w

    rendered = "".join(result)
    return rendered + (" " * max(width - display_width(rendered), 0))


def format_updated_at(updated_at: str) -> str:
    if not updated_at:
        return "-"
    return updated_at[:16].replace("T", " ")


for row in rows:
    if mode == "issue":
        number, title, labels_csv, updated_at = (row + [""] * 4)[:4]
        display = (
            f"#{number:<6} "
            f"{fit_display_width(title, 60)}  "
            f"{fit_display_width(labels_csv, 26)}  "
            f"\033[2m{format_updated_at(updated_at)}\033[0m"
        )
        print("\t".join([display, number, title, labels_csv]))
    elif mode == "pr":
        number, title, branch_name, author, updated_at = (row + [""] * 5)[:5]
        display = (
            f"#{number:<6} "
            f"{fit_display_width(title, 60)}  "
            f"{fit_display_width(branch_name, 20)}  "
            f"{fit_display_width(author, 16)}  "
            f"\033[2m{format_updated_at(updated_at)}\033[0m"
        )
        print("\t".join([display, number, title, branch_name, author]))
    else:
        raise SystemExit(f"unsupported mode: {mode}")
' "$mode"
}

fetch_issue_rows() {
  gh issue list --state open --assignee @me --limit 200 \
    --json number,title,labels,updatedAt \
    --jq '.[] | [(.number | tostring), .title, ((.labels | map(.name)) | join(",")), .updatedAt] | join("\u001f")' \
    | format_selection_rows issue
}

fetch_pr_rows() {
  gh pr list --state open --limit 200 \
    --json number,title,headRefName,author,updatedAt \
    --jq '.[] | [(.number | tostring), .title, .headRefName, .author.login, .updatedAt] | join("\u001f")' \
    | format_selection_rows pr
}

write_cache() {
  local mode="$1"
  local cache_file meta_file tmp_file tmp_meta

  ensure_cache_dir
  cache_file="$(cache_file_for_mode "$mode")"
  meta_file="$(cache_meta_file_for_mode "$mode")"
  tmp_file="${cache_file}.tmp.$$"
  tmp_meta="${meta_file}.tmp.$$"

  cat >"$tmp_file"
  printf '%s\n' "$(current_epoch)" >"$tmp_meta"
  mv "$tmp_file" "$cache_file"
  mv "$tmp_meta" "$meta_file"
}

print_cached_rows() {
  local mode="$1"
  cat "$(cache_file_for_mode "$mode")"
}

list_rows() {
  local mode="$1"
  local force_refresh="${2:-0}"

  if [[ "$force_refresh" != "1" ]] && cache_is_fresh "$mode"; then
    print_cached_rows "$mode"
    return 0
  fi

  case "$mode" in
    issue)
      fetch_issue_rows | write_cache issue
      ;;
    pr)
      fetch_pr_rows | write_cache pr
      ;;
    *)
      echo "Error: unsupported mode '$mode'." >&2
      exit 1
      ;;
  esac

  print_cached_rows "$mode"
}

build_reload_command() {
  local subcommand="$1"
  local refresh_cmd fallback_cmd reload_cmd

  printf -v refresh_cmd '%q %q %q' "$SCRIPT_PATH" "$subcommand" "--refresh"
  printf -v fallback_cmd '%q %q' "$SCRIPT_PATH" "$subcommand"
  printf -v reload_cmd '%s || %s' "$refresh_cmd" "$fallback_cmd"

  printf '%s\n' "$reload_cmd"
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

select_issue() {
  local reload_cmd

  reload_cmd="$(build_reload_command __list-issue --refresh)"
  list_rows issue \
    | fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=1 \
      --header='ctrl-r: refresh issues (TTL 60s)' \
      --bind "ctrl-r:reload($reload_cmd)+clear-query"
}

select_pr() {
  local reload_cmd

  reload_cmd="$(build_reload_command __list-pr --refresh)"
  list_rows pr \
    | fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=1 \
      --header='ctrl-r: refresh PRs (TTL 60s)' \
      --bind "ctrl-r:reload($reload_cmd)+clear-query"
}

create_issue_worktree() {
  local issue_number="$1"
  local labels_csv="$2"
  local first_label default_branch branch_name dir existing branch path

  if existing="$(find_worktree_by_issue_number "$issue_number")"; then
    branch="$(awk -F'\t' '{print $1}' <<<"$existing")"
    path="$(awk -F'\t' '{print $2}' <<<"$existing")"
    open_dir_in_tmux "$path" "$branch"
    return 0
  fi

  first_label="${labels_csv%%,*}"
  default_branch="feature/$(normalize_slug "$first_label")#${issue_number}"
  branch_name="$(prompt_branch_name "$default_branch")"

  git gtr new "$branch_name" --from develop
  dir="$(resolve_worktree_dir "$branch_name")"
  open_dir_in_tmux "$dir" "$branch_name"
}

create_pr_worktree() {
  local pr_number="$1"
  local branch_name="$2"
  local dir existing branch path

  if existing="$(find_worktree_by_branch "$branch_name")"; then
    branch="$(awk -F'\t' '{print $1}' <<<"$existing")"
    path="$(awk -F'\t' '{print $2}' <<<"$existing")"
    open_dir_in_tmux "$path" "$branch"
    return 0
  fi

  git gtr new "$branch_name"
  dir="$(resolve_worktree_dir "$branch_name")"
  open_dir_in_tmux "$dir" "$branch_name"
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
  require_cmd tmux

  case "${1:-}" in
    issue)
      [[ $# -eq 1 ]] || { usage; exit 1; }
      handle_issue
      ;;
    pr)
      [[ $# -eq 1 ]] || { usage; exit 1; }
      handle_pr
      ;;
    __list-issue)
      [[ $# -le 2 ]] || { usage; exit 1; }
      list_rows issue "${2:+1}"
      ;;
    __list-pr)
      [[ $# -le 2 ]] || { usage; exit 1; }
      list_rows pr "${2:+1}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
