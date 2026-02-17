#!/usr/bin/env bash
# Stages, commits, and pushes all wiki changes. Used by /save.
# The commit message must be provided — the LLM generates it.
#
# Usage:
#   .scripts/wiki-save.sh <wiki-dir> <commit-message>
#
# Outputs:
#   - diff --stat of what was committed
#   - push result
#
# Exit codes:
#   0 — pushed successfully
#   1 — no changes to commit
#   2 — commit failed
#   3 — push failed

set -euo pipefail

WIKI_DIR="${1:?error: wiki directory required as first argument}"
MESSAGE="${2:?error: commit message required as second argument}"

if [[ ! -d "$WIKI_DIR/.git" ]]; then
  echo "error: $WIKI_DIR is not a git repository" >&2
  exit 2
fi

# --- check for changes ---
STATUS="$(git -C "$WIKI_DIR" status --porcelain)"
if [[ -z "$STATUS" ]]; then
  echo "No changes to commit — wiki is up to date."
  exit 1
fi

# --- stage all changes ---
git -C "$WIKI_DIR" add -A

# --- show what will be committed ---
echo "=== Changes ==="
git -C "$WIKI_DIR" diff --cached --stat
echo ""

# --- commit ---
if ! git -C "$WIKI_DIR" commit -m "$MESSAGE" 2>&1; then
  echo "error: commit failed" >&2
  exit 2
fi

# --- push ---
if ! git -C "$WIKI_DIR" push 2>&1; then
  echo "error: push failed" >&2
  exit 3
fi

echo "Wiki changes pushed successfully."
