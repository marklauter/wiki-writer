#!/usr/bin/env bash
# Removes a workspace: source repo, wiki repo, config, and empty parent dirs.
# Does NOT perform safety checks — call check-wiki-safety.sh first.
#
# Usage:
#   .scripts/remove-workspace.sh <config-path>
#
# Exit codes:
#   0 — removed successfully
#   1 — config not found or parse error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:?error: config path required as first argument}"

if [[ ! -f "$CONFIG" ]]; then
  echo "error: config not found at $CONFIG" >&2
  exit 1
fi

# --- parse config ---
SOURCE_DIR="$(grep '^sourceDir:' "$CONFIG" | sed 's/^sourceDir:[[:space:]]*//' | tr -d '"')"
WIKI_DIR="$(grep '^wikiDir:' "$CONFIG" | sed 's/^wikiDir:[[:space:]]*//' | tr -d '"')"

# extract owner/repo from config path
CONFIG_DIR="$(dirname "$CONFIG")"
REPO_NAME="$(basename "$CONFIG_DIR")"
OWNER="$(basename "$(dirname "$CONFIG_DIR")")"

# --- remove repos and config ---
[[ -n "$SOURCE_DIR" && -d "$SCRIPT_DIR/$SOURCE_DIR" ]] && rm -rf "$SCRIPT_DIR/$SOURCE_DIR"
[[ -n "$WIKI_DIR" && -d "$SCRIPT_DIR/$WIKI_DIR" ]]     && rm -rf "$SCRIPT_DIR/$WIKI_DIR"
rm -f "$CONFIG"

# --- clean up empty parent directories ---
rmdir "$SCRIPT_DIR/workspace/config/$OWNER/$REPO_NAME" 2>/dev/null || true
rmdir "$SCRIPT_DIR/workspace/config/$OWNER" 2>/dev/null || true
rmdir "$SCRIPT_DIR/workspace/$OWNER" 2>/dev/null || true

echo "removed: $OWNER/$REPO_NAME"
