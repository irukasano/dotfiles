#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   md-preview path/to/file.md [port]
#
# Example:
#   md-preview ./HLD.md 6444

md_file="${1:-}"
port="${2:-6444}"

if [[ -z "${md_file}" ]]; then
  echo "Usage: $(basename "$0") <markdown-file> [port]" >&2
  exit 1
fi

if [[ ! -f "${md_file}" ]]; then
  echo "Error: file not found: ${md_file}" >&2
  exit 1
fi

# Where we keep reusable assets (css/template)
cache_dir="${HOME}/.cache/md-preview"
mkdir -p "${cache_dir}"

css_cache="${cache_dir}/github-markdown.css"
tpl_cache="${cache_dir}/tpl.html"

# Where we serve from
serve_dir="/tmp/md-preview-${USER}"
mkdir -p "${serve_dir}"

css_serve="${serve_dir}/github-markdown.css"
html_serve="${serve_dir}/preview.html"

# 1) Ensure CSS exists (cache)
if [[ ! -s "${css_cache}" ]]; then
  curl -fsSL \
    https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown.css \
    -o "${css_cache}"
fi

# 2) Ensure template exists (cache)
if [[ ! -s "${tpl_cache}" ]]; then
  cat > "${tpl_cache}" <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <link rel="stylesheet" href="github-markdown.css">
  <style>
    .markdown-body { box-sizing: border-box; min-width: 200px; max-width: 980px; margin: 0 auto; padding: 45px; }
  </style>
</head>
<body>
  <article class="markdown-body">
  $body$
  </article>
</body>
</html>
HTML
fi

# 3) Copy CSS into serve dir (so browser can fetch it)
cp -f "${css_cache}" "${css_serve}"

# 4) Convert target md -> HTML into serve dir
pandoc "${md_file}" --template="${tpl_cache}" -o "${html_serve}"

# 5) Start server (bind localhost only)
echo "Serving: ${html_serve}"
echo "Open:    http://localhost:${port}/preview.html"
echo "Dir:     ${serve_dir}"
echo

cd "${serve_dir}"

# If a server is already running on that port, this will fail fast with a clear error.
python3 -m http.server "${port}" --bind 127.0.0.1

