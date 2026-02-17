#!/usr/bin/env bash
# Fetches open documentation issues from GitHub. Used by /proofread-wiki
# (deduplication) and /revise-wiki (fetching issues to fix).
#
# Usage:
#   .scripts/fetch-docs-issues.sh [config-path] [--limit N] [--fields FIELDS]
#
# Arguments:
#   config-path  — path to workspace.config.yml (auto-detected if omitted)
#   --limit N    — max issues to fetch (default: 200)
#   --fields F   — JSON fields to include (default: number,title,body,labels)
#
# Output: raw JSON from gh issue list
#
# Exit codes:
#   0 — success (JSON on stdout)
#   1 — config error or gh failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- defaults ---
LIMIT=200
FIELDS="number,title,body,labels"
CONFIG=""

# --- parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)  LIMIT="$2";  shift 2 ;;
    --fields) FIELDS="$2"; shift 2 ;;
    *)
      if [[ -z "$CONFIG" && -f "$1" ]]; then
        CONFIG="$1"
      fi
      shift
      ;;
  esac
done

# --- resolve config ---
if [[ -z "$CONFIG" ]]; then
  configs=("$SCRIPT_DIR"/workspace/config/*/*/workspace.config.yml)
  if [[ ${#configs[@]} -eq 0 || ! -f "${configs[0]}" ]]; then
    echo "error: no workspace config found. Run /up first." >&2
    exit 1
  fi
  if [[ ${#configs[@]} -gt 1 ]]; then
    echo "error: multiple workspaces found. Pass config path as first argument." >&2
    exit 1
  fi
  CONFIG="${configs[0]}"
fi

REPO="$(grep '^repo:' "$CONFIG" | sed 's/^repo:[[:space:]]*//' | tr -d '"')"
if [[ -z "$REPO" ]]; then
  echo "error: repo not set in config" >&2
  exit 1
fi

# --- fetch issues ---
gh issue list \
  --repo "$REPO" \
  --label documentation \
  --state open \
  --json "$FIELDS" \
  --limit "$LIMIT"
