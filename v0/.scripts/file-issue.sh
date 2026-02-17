#!/usr/bin/env bash
# Files a GitHub issue. Reads repo from workspace.config.yml, labels from
# .github/ISSUE_TEMPLATE/wiki-docs.yml. Title as first arg, body via stdin.
#
# Usage:
#   .scripts/file-issue.sh "Title here" [config-path] <<'EOF'
#   ### Page
#   Query-and-Scan.md
#   ...
#   EOF

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${2:-}" ]]; then
  CONFIG="$2"
else
  # Auto-detect single workspace config
  configs=("$SCRIPT_DIR"/workspace/config/*/*/workspace.config.yml)
  if [[ ${#configs[@]} -eq 0 || ! -f "${configs[0]}" ]]; then
    echo "error: no workspace config found. Run /up first." >&2
    exit 1
  fi
  if [[ ${#configs[@]} -gt 1 ]]; then
    echo "error: multiple workspaces found. Pass config path as second argument." >&2
    exit 1
  fi
  CONFIG="${configs[0]}"
fi
TEMPLATE="$SCRIPT_DIR/.github/ISSUE_TEMPLATE/wiki-docs.yml"

# --- config ---
if [[ ! -f "$CONFIG" ]]; then
  echo "error: workspace config not found at $CONFIG" >&2
  exit 1
fi

REPO=$(grep '^repo:' "$CONFIG" | sed 's/^repo:[[:space:]]*//' | tr -d '"')
if [[ -z "$REPO" ]]; then
  echo "error: repo not set in workspace.config.yml" >&2
  exit 1
fi

# --- labels from template ---
LABELS=()
if [[ -f "$TEMPLATE" ]]; then
  while IFS= read -r label; do
    label=$(echo "$label" | tr -d '"' | xargs)
    [[ -n "$label" ]] && LABELS+=("$label")
  done < <(grep -A1 '^labels:' "$TEMPLATE" | tail -1 | tr -d '[]' | tr ',' '\n')
fi

# --- title ---
TITLE="${1:?error: title required as first argument}"

# --- body from stdin ---
BODY_FILE=$(mktemp)
cat > "$BODY_FILE"

cleanup() { rm -f "$BODY_FILE"; }
trap cleanup EXIT

# --- extra labels from env ---
if [[ -n "${EXTRA_LABELS:-}" ]]; then
  IFS=',' read -ra extras <<< "$EXTRA_LABELS"
  LABELS+=("${extras[@]}")
fi

# --- build label flags ---
LABEL_FLAGS=()
for label in "${LABELS[@]}"; do
  LABEL_FLAGS+=(--label "$label")
done

# --- create issue (retry once on failure) ---
create_issue() {
  gh issue create --repo "$REPO" \
    --title "$TITLE" \
    --body-file "$BODY_FILE" \
    "${LABEL_FLAGS[@]}"
}

if ! OUTPUT=$(create_issue 2>&1); then
  echo "First attempt failed: $OUTPUT" >&2
  echo "Retrying..." >&2
  if ! OUTPUT=$(create_issue 2>&1); then
    echo "error: issue creation failed after retry: $OUTPUT" >&2
    exit 1
  fi
fi

echo "$OUTPUT"
