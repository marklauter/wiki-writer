#!/usr/bin/env bash
# Checks a wiki repo for uncommitted changes and unpushed commits.
# Used by /down before removing a workspace.
#
# Usage:
#   .scripts/check-wiki-safety.sh <wiki-dir>
#
# Output (to stdout):
#   UNCOMMITTED=true|false
#   UNPUSHED=true|false
#   UNCOMMITTED_FILES=<newline-separated list>
#   UNPUSHED_COMMITS=<newline-separated list>
#
# Exit codes:
#   0 — check completed (read output for results)
#   1 — wiki dir doesn't exist or isn't a git repo

set -euo pipefail

WIKI_DIR="${1:?error: wiki directory required as first argument}"

if [[ ! -d "$WIKI_DIR/.git" ]]; then
  echo "error: $WIKI_DIR is not a git repository" >&2
  exit 1
fi

# --- uncommitted changes ---
UNCOMMITTED_OUTPUT="$(git -C "$WIKI_DIR" status --porcelain 2>/dev/null || true)"
if [[ -n "$UNCOMMITTED_OUTPUT" ]]; then
  echo "UNCOMMITTED=true"
  echo "UNCOMMITTED_FILES<<__EOF__"
  echo "$UNCOMMITTED_OUTPUT"
  echo "__EOF__"
else
  echo "UNCOMMITTED=false"
  echo "UNCOMMITTED_FILES="
fi

# --- unpushed commits ---
UNPUSHED_OUTPUT="$(git -C "$WIKI_DIR" log @{u}..HEAD --oneline 2>/dev/null || true)"
if [[ -n "$UNPUSHED_OUTPUT" ]]; then
  echo "UNPUSHED=true"
  echo "UNPUSHED_COMMITS<<__EOF__"
  echo "$UNPUSHED_OUTPUT"
  echo "__EOF__"
else
  echo "UNPUSHED=false"
  echo "UNPUSHED_COMMITS="
fi
