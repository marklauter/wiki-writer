#!/usr/bin/env bash
# Clones a source repo and its wiki into the workspace, then writes
# the workspace config. Used by /up after the user interview.
#
# Usage:
#   .scripts/clone-workspace.sh --url <clone-url> --audience <text> --tone <text>
#
# The script:
#   1. Checks gh auth status
#   2. Parses the clone URL to extract owner/repo
#   3. Checks for existing workspace (exits 2 if found)
#   4. Creates directory structure
#   5. Clones source repo
#   6. Derives and clones wiki repo (non-fatal if wiki doesn't exist)
#   7. Writes workspace.config.yml
#
# Exit codes:
#   0 — success
#   1 — auth failure or invalid arguments
#   2 — workspace already exists
#   3 — source clone failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- parse arguments ---
URL="" AUDIENCE="" TONE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)      URL="$2";      shift 2 ;;
    --audience) AUDIENCE="$2"; shift 2 ;;
    --tone)     TONE="$2";     shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$URL" || -z "$AUDIENCE" || -z "$TONE" ]]; then
  echo "error: --url, --audience, and --tone are all required" >&2
  exit 1
fi

# --- check GitHub auth ---
if ! gh auth status >/dev/null 2>&1; then
  echo "error: not authenticated with GitHub. Run 'gh auth login' first." >&2
  exit 1
fi

# --- parse clone URL to extract owner/repo ---
OWNER="" REPO_NAME=""

# HTTPS: https://github.com/owner/repo.git or https://github.com/owner/repo
if [[ "$URL" =~ github\.com[/:]([^/]+)/([^/.]+)(\.git)?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO_NAME="${BASH_REMATCH[2]}"
fi

if [[ -z "$OWNER" || -z "$REPO_NAME" ]]; then
  echo "error: could not parse owner/repo from URL: $URL" >&2
  echo "Expected: https://github.com/owner/repo.git or git@github.com:owner/repo.git" >&2
  exit 1
fi

SLUG="$OWNER/$REPO_NAME"

# --- check for existing workspace ---
CONFIG_PATH="$SCRIPT_DIR/workspace/config/$OWNER/$REPO_NAME/workspace.config.yml"
if [[ -f "$CONFIG_PATH" ]]; then
  echo "error: workspace $SLUG already exists. Run /down $SLUG first." >&2
  exit 2
fi

# --- create directories ---
mkdir -p "$SCRIPT_DIR/workspace/$OWNER"
mkdir -p "$SCRIPT_DIR/workspace/config/$OWNER/$REPO_NAME"

# --- clone source repo ---
SOURCE_DIR="workspace/$OWNER/$REPO_NAME"
if ! git clone "$URL" "$SCRIPT_DIR/$SOURCE_DIR" 2>&1; then
  echo "error: failed to clone source repo from $URL" >&2
  exit 3
fi

# --- derive and clone wiki repo ---
WIKI_DIR="workspace/$OWNER/$REPO_NAME.wiki"
WIKI_CLONED=true

if [[ "$URL" == git@* ]]; then
  WIKI_URL="git@github.com:$OWNER/$REPO_NAME.wiki.git"
else
  WIKI_URL="https://github.com/$OWNER/$REPO_NAME.wiki.git"
fi

if ! git clone "$WIKI_URL" "$SCRIPT_DIR/$WIKI_DIR" 2>&1; then
  WIKI_CLONED=false
  echo "warning: wiki clone failed — the repo may not have a wiki yet." >&2
fi

# --- write config ---
cat > "$CONFIG_PATH" <<EOF
repo: "$SLUG"
sourceDir: "$SOURCE_DIR"
wikiDir: "$WIKI_DIR"
audience: "$AUDIENCE"
tone: "$TONE"
EOF

# --- output summary as JSON ---
cat <<SUMMARY
{
  "owner": "$OWNER",
  "repo": "$REPO_NAME",
  "slug": "$SLUG",
  "sourceDir": "$SOURCE_DIR",
  "wikiDir": "$WIKI_DIR",
  "configPath": "$CONFIG_PATH",
  "wikiCloned": $WIKI_CLONED
}
SUMMARY
