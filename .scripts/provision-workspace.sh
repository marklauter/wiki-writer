#!/usr/bin/env bash
# Clone repos and write workspace config. Assumes validation has already passed.
#
# Usage:
#   .scripts/provision-workspace.sh --url <url> --owner <owner> --repo <repo> \
#     --audience <text> --tone <text>
#
# Exit codes:
#   0 — success
#   1 — bad arguments
#   2 — workspace already exists (safety check)
#   3 — source clone failed
#   4 — wiki clone failed

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- parse arguments ---
URL="" OWNER="" REPO_NAME="" AUDIENCE="" TONE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)      URL="$2";       shift 2 ;;
    --owner)    OWNER="$2";     shift 2 ;;
    --repo)     REPO_NAME="$2"; shift 2 ;;
    --audience) AUDIENCE="$2";  shift 2 ;;
    --tone)     TONE="$2";     shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$URL" || -z "$OWNER" || -z "$REPO_NAME" || -z "$AUDIENCE" || -z "$TONE" ]]; then
  echo "error: --url, --owner, --repo, --audience, and --tone are all required" >&2
  exit 1
fi

SLUG="$OWNER/$REPO_NAME"
CONFIG_DIR="$PROJECT_DIR/workspace/artifacts/$OWNER/$REPO_NAME"
CONFIG_PATH="$CONFIG_DIR/workspace.config.md"
SOURCE_DIR="workspace/$OWNER/$REPO_NAME"
WIKI_DIR="workspace/$OWNER/$REPO_NAME.wiki"

# --- safety: config must not exist ---
if [[ -f "$CONFIG_PATH" ]]; then
  echo "error: workspace $SLUG already exists at $CONFIG_PATH" >&2
  exit 2
fi

# --- create directories ---
mkdir -p "$PROJECT_DIR/workspace/$OWNER"
mkdir -p "$CONFIG_DIR"

# --- clone source repo ---
if ! git clone "$URL" "$PROJECT_DIR/$SOURCE_DIR" 2>&1; then
  echo "error: failed to clone source repo from $URL" >&2
  # cleanup
  rm -rf "$PROJECT_DIR/$SOURCE_DIR"
  rmdir "$CONFIG_DIR" 2>/dev/null || true
  rmdir "$PROJECT_DIR/workspace/artifacts/$OWNER" 2>/dev/null || true
  rmdir "$PROJECT_DIR/workspace/$OWNER" 2>/dev/null || true
  exit 3
fi

# --- derive wiki URL (same protocol as source URL) ---
if [[ "$URL" == git@* ]]; then
  WIKI_URL="git@github.com:$OWNER/$REPO_NAME.wiki.git"
else
  WIKI_URL="https://github.com/$OWNER/$REPO_NAME.wiki.git"
fi

# --- clone wiki repo ---
if ! git clone "$WIKI_URL" "$PROJECT_DIR/$WIKI_DIR" 2>&1; then
  echo "error: failed to clone wiki repo from $WIKI_URL" >&2
  # cleanup: remove source clone, directories
  rm -rf "$PROJECT_DIR/$SOURCE_DIR"
  rm -rf "$PROJECT_DIR/$WIKI_DIR"
  rmdir "$CONFIG_DIR" 2>/dev/null || true
  rmdir "$PROJECT_DIR/workspace/artifacts/$OWNER" 2>/dev/null || true
  rmdir "$PROJECT_DIR/workspace/$OWNER" 2>/dev/null || true
  exit 4
fi

# --- write config from form template (only after both clones succeed) ---
sed -e "s|{owner}|$OWNER|g" \
    -e "s|{repo}|$REPO_NAME|g" \
    -e "s|{audience}|$AUDIENCE|" \
    -e "s|{tone}|$TONE|" \
    "$PROJECT_DIR/.claude/forms/workspace.config.md" > "$CONFIG_PATH"

# --- summary from form template ---
sed -e "s|{owner}|$OWNER|g" \
    -e "s|{repo}|$REPO_NAME|g" \
    -e "s|{audience}|$AUDIENCE|" \
    -e "s|{tone}|$TONE|" \
    "$PROJECT_DIR/.claude/forms/provision-summary.md"
