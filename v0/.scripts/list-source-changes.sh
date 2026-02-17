#!/usr/bin/env bash
# Lists recent source code changes: commits and changed files.
# Used by /refresh-wiki to identify what needs syncing.
#
# Usage:
#   .scripts/list-source-changes.sh <source-dir> [commit-count]
#
# Arguments:
#   source-dir    — path to the cloned source repo
#   commit-count  — number of recent commits to examine (default: 50)
#
# Output (two sections, separated by a delimiter):
#   === COMMITS ===
#   <git log --oneline output>
#   === CHANGED FILES ===
#   <git diff --name-only output>
#
# Exit codes:
#   0 — success
#   1 — source dir not found or not a git repo

set -euo pipefail

SOURCE_DIR="${1:?error: source directory required as first argument}"
COUNT="${2:-50}"

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  echo "error: $SOURCE_DIR is not a git repository" >&2
  exit 1
fi

echo "=== COMMITS ==="
git -C "$SOURCE_DIR" log --oneline -"$COUNT" 2>/dev/null || true

echo "=== CHANGED FILES ==="
git -C "$SOURCE_DIR" diff --name-only "HEAD~${COUNT}..HEAD" 2>/dev/null || \
  git -C "$SOURCE_DIR" diff --name-only "$(git -C "$SOURCE_DIR" rev-list --max-parents=0 HEAD)..HEAD" 2>/dev/null || true
