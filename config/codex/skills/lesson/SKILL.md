---
name: lesson
description: Record user-correction lessons and verify a final answer against project lessons. Use for lesson capture, lesson migration, or final answer review; not for ordinary task planning.
---

# Lesson

Use this skill when a user correction needs to become a reusable lesson, when migrating legacy lessons, and at the end of a task that changes code or configuration.

Resolve `AI_BASE_DIR` from the applicable AGENTS instructions. Use `~/.codex/bin/codex-lesson --ai-base "$AI_BASE_DIR" check` before relying on vector search.

## Check and initialize the repository index

Run `check` in the current repository before using vector search. Read its JSON result:

- If `vector_available` is `false`, do not run `init` or `sync`. The model or vector dependencies are unavailable, so use the Markdown-only fallback below.
- If `vector_available` is `true` and `index_available` is `false`, run `codex-lesson --ai-base "$AI_BASE_DIR" init`. It builds `AI_BASE_DIR/tasks/lessons.sqlite` from that repository's Markdown lessons.
- If both are `true`, the repository-local vector index is ready. Do not use another repository's SQLite file.

`init` and `sync` use the same index-generation implementation. Use `init` for first-time repository setup; retain `sync` for an explicit rebuild of an existing index.

## Record a correction

First record the original correction in the current task's `Review`. Extract a reusable Rule from it:

- Keep relevant technology, layer, and situation in Scope.
- Remove incidental filenames, class names, and method names from Rule.
- Do not over-generalize beyond the demonstrated situation.

Choose a concise human-readable title, then use `codex-lesson add` with the title, Rule, Scope, and the Review file-and-heading reference. The command assigns the UUID. If its result reports `indexed: false`, the Markdown record is still valid; do not attempt to install dependencies as part of ordinary task work.

## Verify before completion

Run `codex-lesson check` and apply the repository-index initialization procedure above first.

- If `vector_available` and `index_available` are true, search the final answer with `codex-lesson search --query`. Inspect all five results, use Scope to judge applicability, and read each applicable Review. Revise and repeat until there are no applicable findings.
- If it is false, use `rg` to search both Rule and Scope in `AI_BASE_DIR/tasks/lessons.md`; inspect applicable entries and revise until there are no findings.

Report which verification path was used and its outcome in the task Review.

## Migrate legacy lessons

Only migrate when the user explicitly asks. First use `codex-lesson migrate-init` to preserve the original `lessons.md` as `lessons-legacy.md` and create a new empty `lessons.md`. For each legacy item, record its original text and the generalization judgment in the migration task Review, then add a new lesson that references that Review. Do not infer a missing historical Review reference.
