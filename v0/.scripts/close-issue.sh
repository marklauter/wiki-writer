#!/usr/bin/env bash
# Closes a GitHub issue with a comment, or adds a comment without closing.
# Used by /resolve-issues after applying fixes.
#
# Usage:
#   .scripts/close-issue.sh <issue-number> [--comment TEXT] [--skip TEXT] [config-path]
#
# Modes:
#   --comment TEXT  — close the issue and add TEXT as a comment
#   --skip TEXT     — add TEXT as a comment but do NOT close the issue
#
# If neither --comment nor --skip is given, closes with a default message.
#
# Exit codes:
#   0 — success
#   1 — error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- parse arguments ---
ISSUE="" COMMENT="" SKIP="" CONFIG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --comment) COMMENT="$2"; shift 2 ;;
    --skip)    SKIP="$2";    shift 2 ;;
    *)
      if [[ -z "$ISSUE" && "$1" =~ ^[0-9]+$ ]]; then
        ISSUE="$1"
      elif [[ -f "$1" ]]; then
        CONFIG="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$ISSUE" ]]; then
  echo "error: issue number required" >&2
  exit 1
fi

# --- resolve config ---
if [[ -z "$CONFIG" ]]; then
  configs=("$SCRIPT_DIR"/workspace/config/*/*/workspace.config.yml)
  if [[ ${#configs[@]} -eq 0 || ! -f "${configs[0]}" ]]; then
    echo "error: no workspace config found." >&2
    exit 1
  fi
  if [[ ${#configs[@]} -gt 1 ]]; then
    echo "error: multiple workspaces found. Pass config path." >&2
    exit 1
  fi
  CONFIG="${configs[0]}"
fi

REPO="$(grep '^repo:' "$CONFIG" | sed 's/^repo:[[:space:]]*//' | tr -d '"')"
if [[ -z "$REPO" ]]; then
  echo "error: repo not set in config" >&2
  exit 1
fi

# --- skip mode: comment only, don't close ---
if [[ -n "$SKIP" ]]; then
  gh issue comment "$ISSUE" --repo "$REPO" --body "$SKIP"
  echo "Commented on issue #$ISSUE (not closed)"
  exit 0
fi

# --- close mode ---
CLOSE_COMMENT="${COMMENT:-Fixed by resolve-issues command.}"
gh issue close "$ISSUE" --repo "$REPO" --comment "$CLOSE_COMMENT"
echo "Closed issue #$ISSUE"
