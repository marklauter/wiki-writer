#!/usr/bin/env bash
# Shared workspace selection protocol. Every UC except UC-05 uses this.
#
# Usage: eval "$(.scripts/resolve-workspace.sh [owner/repo | repo])"
#
# On success, sets these variables:
#   CONFIG_PATH, REPO, SOURCE_DIR, WIKI_DIR, AUDIENCE, TONE, OWNER, REPO_NAME
#
# Exit codes:
#   0 — resolved (variables printed to stdout)
#   1 — no workspaces found
#   2 — multiple workspaces, no match (caller should prompt user)
#   3 — identifier given but no match found

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MATCH="${1:-}"

# --- find all workspace configs ---
configs=()
while IFS= read -r -d '' f; do
  configs+=("$f")
done < <(find "$PROJECT_DIR/workspace/config" -mindepth 3 -maxdepth 3 \
  -name "workspace.config.md" -print0 2>/dev/null || true)

if [[ ${#configs[@]} -eq 0 ]]; then
  echo "error: no workspace config found. Run /up first." >&2
  exit 1
fi

# --- match against argument ---
selected=""

if [[ -n "$MATCH" ]]; then
  for cfg in "${configs[@]}"; do
    dir="$(dirname "$cfg")"
    repo_name="$(basename "$dir")"
    owner="$(basename "$(dirname "$dir")")"
    slug="$owner/$repo_name"

    if [[ "$slug" == "$MATCH" || "$repo_name" == "$MATCH" ]]; then
      selected="$cfg"
      break
    fi
  done

  if [[ -z "$selected" ]]; then
    echo "error: no workspace matches '$MATCH'. Available:" >&2
    for cfg in "${configs[@]}"; do
      dir="$(dirname "$cfg")"
      repo_name="$(basename "$dir")"
      owner="$(basename "$(dirname "$dir")")"
      echo "  $owner/$repo_name" >&2
    done
    exit 3
  fi
elif [[ ${#configs[@]} -eq 1 ]]; then
  selected="${configs[0]}"
else
  echo "error: multiple workspaces found. Specify one:" >&2
  for cfg in "${configs[@]}"; do
    dir="$(dirname "$cfg")"
    repo_name="$(basename "$dir")"
    owner="$(basename "$(dirname "$dir")")"
    echo "  $owner/$repo_name" >&2
  done
  exit 2
fi

# --- parse config (key: value format) ---
parse_field() {
  grep "^$1:" "$selected" | sed "s/^$1:[[:space:]]*//"
}

REPO="$(parse_field repo)"
SOURCE_DIR="$(parse_field sourceDir)"
WIKI_DIR="$(parse_field wikiDir)"
AUDIENCE="$(parse_field audience)"
TONE="$(parse_field tone)"

dir="$(dirname "$selected")"
REPO_NAME="$(basename "$dir")"
OWNER="$(basename "$(dirname "$dir")")"

# --- output eval-able variables ---
cat <<EOF
CONFIG_PATH='$selected'
REPO='$REPO'
SOURCE_DIR='$SOURCE_DIR'
WIKI_DIR='$WIKI_DIR'
AUDIENCE='$AUDIENCE'
TONE='$TONE'
OWNER='$OWNER'
REPO_NAME='$REPO_NAME'
EOF
