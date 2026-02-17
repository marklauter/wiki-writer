#!/usr/bin/env bash
# PreToolUse hook: blocks Write and Edit operations on source repository clones.
#
# Source clones live at workspace/{owner}/{repo}/ (no .wiki suffix).
# Wiki clones live at workspace/{owner}/{repo}.wiki/ — these are allowed.
#
# Hook input: JSON on stdin with tool_name and tool_input.file_path
# Hook output:
#   exit 0 — allow (no output needed)
#   exit 2 — block (reason on stdout as JSON)
#
# Fail-open: if anything goes wrong (bad input, parse failure), allow the
# operation. The hook should only block when it is certain the target is a
# source repo clone.

# Fail-open on any unexpected error
trap 'exit 0' ERR

INPUT="$(cat)" || exit 0

# Extract file_path from JSON input (no jq dependency)
FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path" *: *"\([^"]*\)".*/\1/p') || true

# If no file_path found, allow (not a file operation we care about)
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Normalize: convert backslashes to forward slashes (Windows paths)
FILE_PATH="${FILE_PATH//\\//}"

# Extract the workspace-relative path by finding "workspace/" in the path.
# This avoids path format mismatches between Windows (D:/...) and Unix (/d/...).
if [[ "$FILE_PATH" == */workspace/* ]]; then
  REL_PATH="workspace/${FILE_PATH##*/workspace/}"
elif [[ "$FILE_PATH" == workspace/* ]]; then
  REL_PATH="$FILE_PATH"
else
  # Path is not under workspace/ at all — allow
  exit 0
fi

# Allow workspace/artifacts/ (config, reports, cache)
if [[ "$REL_PATH" == workspace/artifacts/* ]]; then
  exit 0
fi

# Extract the repo directory component: workspace/{owner}/{repo}/...
# Strip "workspace/" prefix
AFTER_WS="${REL_PATH#workspace/}"

# Need at least owner/repo/something
OWNER_PART="${AFTER_WS%%/*}"
REST="${AFTER_WS#"$OWNER_PART"/}"
REPO_PART="${REST%%/*}"

if [[ -z "$OWNER_PART" || -z "$REPO_PART" ]]; then
  exit 0
fi

# If repo part ends with .wiki — this is a wiki clone, allow
if [[ "$REPO_PART" == *.wiki ]]; then
  exit 0
fi

# This is a source repo path — block
echo '{"decision":"block","reason":"Source repository clones are readonly. This file is in a source clone (workspace/'"$OWNER_PART"'/'"$REPO_PART"'/). Only wiki clones (*.wiki/) can be modified."}'
exit 2
