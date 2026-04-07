#!/usr/bin/env bash
set -euo pipefail

LAYOUT_SCRIPT="$HOME/dotfiles/config/tmux/bin/layout-dev.sh"
SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
CACHE_TTL_SECONDS=300

usage() {
  cat <<EOF
Usage:
  $(basename "$0") issue
    - open issues assigned to @me, then open or create a matching worktree in tmux

  $(basename "$0") pr
    - open open PRs, then open or create a matching worktree in tmux

  $(basename "$0") file
    - select files from open PRs, then open or create the matching PR worktree in tmux
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required." >&2
    exit 1
  fi
}

ensure_gh_auth() {
  gh --ensure-auth >/dev/null
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

preview_cache_file() {
  local mode="$1"
  local item_id="$2"
  printf '%s/preview-%s-%s.txt' "$(cache_dir)" "$mode" "$item_id"
}

preview_cache_meta_file() {
  local mode="$1"
  local item_id="$2"
  printf '%s/preview-%s-%s.updated_at' "$(cache_dir)" "$mode" "$item_id"
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

preview_cache_is_fresh() {
  local mode="$1"
  local item_id="$2"
  local cache_file meta_file now updated_at age

  cache_file="$(preview_cache_file "$mode" "$item_id")"
  meta_file="$(preview_cache_meta_file "$mode" "$item_id")"

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

format_pr_tab_name() {
  local pr_number="$1"
  local branch_name="$2"

  printf '%s[PR#%s]\n' "$branch_name" "$pr_number"
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
    slug="no-label"
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
    elif mode == "file":
        file_path, number, title, branch_name, created_at = (row + [""] * 5)[:5]
        display = (
            f"{fit_display_width(file_path, 56)}  "
            f"#{number:<6} "
            f"{fit_display_width(title, 44)}  "
            f"{fit_display_width(branch_name, 20)}  "
            f"\033[2m{format_updated_at(created_at)}\033[0m"
        )
        print("\t".join([display, number, file_path, title, branch_name, created_at]))
    else:
        raise SystemExit(f"unsupported mode: {mode}")
' "$mode"
}

format_preview_json() {
  local mode="$1"

  python3 -c '
import json
import sys

mode = sys.argv[1]
payload = json.load(sys.stdin)


def join_names(values):
    names = []
    for value in values or []:
        name = value.get("name") or value.get("login") or ""
        if name:
            names.append(name)
    return ", ".join(names) if names else "-"


def text(value):
    return value if value else "-"


if mode == "issue":
    number = payload.get("number", "-")
    title = payload.get("title", "")
    state = text(payload.get("state"))
    author = text((payload.get("author") or {}).get("login"))
    assignees = join_names(payload.get("assignees"))
    labels = join_names(payload.get("labels"))
    updated_at = text(payload.get("updatedAt"))
    url = text(payload.get("url"))
    body = payload.get("body") or "(no body)"
    lines = [
        f"# Issue #{number}: {title}",
        "",
        f"State: {state}",
        f"Author: {author}",
        f"Assignees: {assignees}",
        f"Labels: {labels}",
        f"Updated: {updated_at}",
        f"URL: {url}",
        "",
        "Body",
        "----",
        body,
    ]
elif mode == "pr":
    number = payload.get("number", "-")
    title = payload.get("title", "")
    state = text(payload.get("state"))
    author = text((payload.get("author") or {}).get("login"))
    assignees = join_names(payload.get("assignees"))
    labels = join_names(payload.get("labels"))
    base_ref = text(payload.get("baseRefName"))
    head_ref = text(payload.get("headRefName"))
    review = text(payload.get("reviewDecision"))
    merge_state = text(payload.get("mergeStateStatus"))
    updated_at = text(payload.get("updatedAt"))
    url = text(payload.get("url"))
    body = payload.get("body") or "(no body)"
    lines = [
        f"# PR #{number}: {title}",
        "",
        f"State: {state}",
        f"Author: {author}",
        f"Assignees: {assignees}",
        f"Labels: {labels}",
        f"Base/Head: {base_ref} <- {head_ref}",
        f"Review: {review}",
        f"Merge: {merge_state}",
        f"Updated: {updated_at}",
        f"URL: {url}",
        "",
        "Body",
        "----",
        body,
    ]
else:
    raise SystemExit(f"unsupported mode: {mode}")

print("\n".join(lines))
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

fetch_file_rows() {
  python3 -c '
import json
import subprocess

prs = json.loads(
    subprocess.check_output(
        [
            "gh",
            "pr",
            "list",
            "--state",
            "open",
            "--limit",
            "200",
            "--json",
            "number,title,headRefName,createdAt",
        ],
        text=True,
    )
)

separator = "\x1f"

for pr in prs:
    pr_number = str(pr["number"])
    title = pr.get("title", "")
    branch_name = pr.get("headRefName", "")
    created_at = pr.get("createdAt", "")
    filenames = subprocess.check_output(
        [
            "gh",
            "api",
            f"repos/:owner/:repo/pulls/{pr_number}/files",
            "--paginate",
            "--jq",
            ".[].filename",
        ],
        text=True,
    ).splitlines()

    for file_path in filenames:
        if not file_path:
            continue
        print(separator.join([file_path, pr_number, title, branch_name, created_at]))
' | LC_ALL=C sort | format_selection_rows file
}

fetch_issue_preview() {
  local issue_number="$1"

  gh issue view "$issue_number" \
    --json number,title,state,author,assignees,labels,updatedAt,url,body \
    | format_preview_json issue
}

fetch_pr_preview() {
  local pr_number="$1"

  gh pr view "$pr_number" \
    --json number,title,state,author,assignees,labels,updatedAt,url,body,baseRefName,headRefName,reviewDecision,mergeStateStatus \
    | format_preview_json pr
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

write_preview_cache() {
  local mode="$1"
  local item_id="$2"
  local cache_file meta_file tmp_file tmp_meta

  ensure_cache_dir
  cache_file="$(preview_cache_file "$mode" "$item_id")"
  meta_file="$(preview_cache_meta_file "$mode" "$item_id")"
  tmp_file="${cache_file}.tmp.$$"
  tmp_meta="${meta_file}.tmp.$$"

  cat >"$tmp_file"
  printf '%s\n' "$(current_epoch)" >"$tmp_meta"
  mv "$tmp_file" "$cache_file"
  mv "$tmp_meta" "$meta_file"
}

print_cached_preview() {
  local mode="$1"
  local item_id="$2"
  cat "$(preview_cache_file "$mode" "$item_id")"
}

preview_item() {
  local mode="$1"
  local item_id="${2:-}"
  local force_refresh="${3:-0}"

  [[ -n "$item_id" ]] || exit 0
  ensure_cache_dir

  if [[ "$force_refresh" != "1" ]] && preview_cache_is_fresh "$mode" "$item_id"; then
    print_cached_preview "$mode" "$item_id"
    return 0
  fi

  case "$mode" in
    issue)
      fetch_issue_preview "$item_id" | write_preview_cache issue "$item_id"
      ;;
    pr)
      fetch_pr_preview "$item_id" | write_preview_cache pr "$item_id"
      ;;
    file)
      fetch_pr_preview "$item_id" | write_preview_cache file "$item_id"
      ;;
    *)
      echo "Error: unsupported mode '$mode'." >&2
      exit 1
      ;;
  esac

  print_cached_preview "$mode" "$item_id"
}

clear_preview_cache() {
  local mode="$1"
  local pattern path

  pattern="$(cache_dir)/preview-${mode}-"*
  for path in $pattern; do
    [[ -e "$path" ]] || continue
    rm -f "$path"
  done
}

list_rows() {
  local mode="$1"
  local force_refresh="${2:-0}"

  ensure_cache_dir

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
    file)
      fetch_file_rows | write_cache file
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

build_preview_command() {
  local subcommand="$1"
  local preview_cmd

  printf -v preview_cmd '%q %q %s || true' "$SCRIPT_PATH" "$subcommand" '{2}'
  printf '%s\n' "$preview_cmd"
}

build_clear_preview_command() {
  local subcommand="$1"
  local clear_cmd

  printf -v clear_cmd '%q %q' "$SCRIPT_PATH" "$subcommand"
  printf '%s\n' "$clear_cmd"
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
  local reload_cmd preview_cmd clear_preview_cmd

  reload_cmd="$(build_reload_command __list-issue --refresh)"
  preview_cmd="$(build_preview_command __preview-issue)"
  clear_preview_cmd="$(build_clear_preview_command __clear-preview-issue)"
  list_rows issue \
    | fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=1 \
      --preview "$preview_cmd" \
      --preview-window 'right,60%,border-left,wrap' \
      --header=$'ctrl-r: refresh issues (TTL 300s)\nassignee @me の ISSUE のみ表示しています' \
      --bind "ctrl-r:execute-silent($clear_preview_cmd)+reload($reload_cmd)+clear-query"
}

select_pr() {
  local reload_cmd preview_cmd clear_preview_cmd

  reload_cmd="$(build_reload_command __list-pr --refresh)"
  preview_cmd="$(build_preview_command __preview-pr)"
  clear_preview_cmd="$(build_clear_preview_command __clear-preview-pr)"
  list_rows pr \
    | fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=1 \
      --preview "$preview_cmd" \
      --preview-window 'right,60%,border-left,wrap' \
      --header='ctrl-r: refresh PRs (TTL 300s)' \
      --bind "ctrl-r:execute-silent($clear_preview_cmd)+reload($reload_cmd)+clear-query"
}

select_file() {
  local reload_cmd preview_cmd clear_preview_cmd

  reload_cmd="$(build_reload_command __list-file --refresh)"
  preview_cmd="$(build_preview_command __preview-file)"
  clear_preview_cmd="$(build_clear_preview_command __clear-preview-file)"
  list_rows file \
    | fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=1 \
      --preview "$preview_cmd" \
      --preview-window 'right,60%,border-left,wrap' \
      --header='ctrl-r: refresh PR files (TTL 300s)' \
      --bind "ctrl-r:execute-silent($clear_preview_cmd)+reload($reload_cmd)+clear-query"
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
  local dir existing branch path tab_name

  tab_name="$(format_pr_tab_name "$pr_number" "$branch_name")"

  if existing="$(find_worktree_by_branch "$branch_name")"; then
    branch="$(awk -F'\t' '{print $1}' <<<"$existing")"
    path="$(awk -F'\t' '{print $2}' <<<"$existing")"
    open_dir_in_tmux "$path" "$tab_name"
    return 0
  fi

  git gtr new "$branch_name"
  dir="$(resolve_worktree_dir "$branch_name")"
  open_dir_in_tmux "$dir" "$tab_name"
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

handle_file() {
  local selected display pr_number file_path title branch_name created_at

  selected="$(select_file || true)"
  if [[ -z "$selected" ]]; then
    echo "No file selected."
    exit 0
  fi

  IFS=$'\t' read -r display pr_number file_path title branch_name created_at <<<"$selected"
  create_pr_worktree "$pr_number" "$branch_name"
}

main() {
  require_cmd gh
  require_cmd fzf
  require_cmd git
  require_cmd tmux
  ensure_gh_auth

  case "${1:-}" in
    issue)
      [[ $# -eq 1 ]] || { usage; exit 1; }
      handle_issue
      ;;
    pr)
      [[ $# -eq 1 ]] || { usage; exit 1; }
      handle_pr
      ;;
    file)
      [[ $# -eq 1 ]] || { usage; exit 1; }
      handle_file
      ;;
    __list-issue)
      [[ $# -le 2 ]] || { usage; exit 1; }
      list_rows issue "${2:+1}"
      ;;
    __list-pr)
      [[ $# -le 2 ]] || { usage; exit 1; }
      list_rows pr "${2:+1}"
      ;;
    __list-file)
      [[ $# -le 2 ]] || { usage; exit 1; }
      list_rows file "${2:+1}"
      ;;
    __preview-issue)
      [[ $# -eq 2 ]] || exit 0
      preview_item issue "$2"
      ;;
    __preview-pr)
      [[ $# -eq 2 ]] || exit 0
      preview_item pr "$2"
      ;;
    __preview-file)
      [[ $# -eq 2 ]] || exit 0
      preview_item file "$2"
      ;;
    __clear-preview-issue)
      [[ $# -eq 1 ]] || exit 0
      clear_preview_cache issue
      ;;
    __clear-preview-pr)
      [[ $# -eq 1 ]] || exit 0
      clear_preview_cache pr
      ;;
    __clear-preview-file)
      [[ $# -eq 1 ]] || exit 0
      clear_preview_cache file
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
