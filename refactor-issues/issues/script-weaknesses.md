# Script Weaknesses

Issues found in `.scripts/` after review. Organized by severity.

---

## HIGH — Will cause real bugs

### SW-1: `resolve-workspace.sh` — eval injection via unescaped single quotes

**File:** `.scripts/resolve-workspace.sh:92-101`

The script outputs eval-able shell variables using single quotes:

```bash
AUDIENCE='$AUDIENCE'
TONE='$TONE'
```

If a user sets audience to `it's for .NET developers`, the `eval` breaks:

```bash
eval "$(bash .scripts/resolve-workspace.sh)"
# expands to: AUDIENCE='it's for .NET developers'
# shell sees: AUDIENCE='it' followed by unquoted garbage
```

The script strips double quotes (`tr -d '"'`) but does not escape single quotes. Since this is the most-called script in the system (every command starts with it), this will surface quickly.

**Fix:** Escape single quotes in values before outputting. Replace the `cat <<EOF` block with a function that escapes `'` → `'\''` for each value:

```bash
escape() { printf '%s' "$1" | sed "s/'/'\\\\''/g"; }
cat <<EOF
AUDIENCE='$(escape "$AUDIENCE")'
TONE='$(escape "$TONE")'
EOF
```

Or switch to a safer transport format — write a temp file and source it, or output `key=value` lines and parse with `read`.

---

## MEDIUM — Correctness and robustness

### SW-2: `wiki-save.sh` — `git add -A` stages everything

**File:** `.scripts/wiki-save.sh:36`

`git add -A` stages all untracked and modified files in the wiki directory, including editor swap files (`.swp`, `~`), OS metadata (`.DS_Store`, `Thumbs.db`), and any temp files left by crashed processes.

The wiki repo may not have a `.gitignore` (GitHub wiki repos don't get one by default).

**Fix options:**
1. Add a `.gitignore` to the wiki repo during `/up` or `/init-wiki` (covering common junk files).
2. Accept an optional `--files` argument for selective staging, falling back to `git add -A` when not provided.
3. Use `git add *.md` or a glob pattern that only stages wiki content files.

Option 1 is simplest and covers the common case.

### SW-3: `check-wiki-safety.sh` — `__EOF__` heredoc delimiter is fragile

**File:** `.scripts/check-wiki-safety.sh:31-32,42-43`

The script uses `__EOF__` as a delimiter in its output:

```
UNCOMMITTED_FILES<<__EOF__
M some-file.md
__EOF__
```

If any git output line is literally `__EOF__`, the consumer's parsing breaks. Unlikely for filenames, but commit messages (in the `UNPUSHED_COMMITS` section) can contain anything.

**Fix:** Switch to a structured output format. Options:
1. JSON output (parseable with `jq` or by the LLM directly).
2. Length-prefixed values: `UNCOMMITTED_FILES_COUNT=3` followed by exactly 3 lines.
3. NUL-delimited output with `git status -z` / `git log -z`.

JSON is the best fit since `clone-workspace.sh` already outputs JSON:

```bash
cat <<JSONEOF
{
  "uncommitted": $HAS_UNCOMMITTED,
  "unpushed": $HAS_UNPUSHED,
  "uncommittedFiles": $(git -C "$WIKI_DIR" status --porcelain -z | ...),
  "unpushedCommits": $(git -C "$WIKI_DIR" log @{u}..HEAD --oneline -z | ...)
}
JSONEOF
```

### SW-4: `clone-workspace.sh` — no `--depth 1` for source repo

**File:** `.scripts/clone-workspace.sh:79`

The script does a full clone of the source repo. For large repos this is slow and wastes disk. The remediation plan (Task 5A) calls for `--depth 1` shallow clones, but since the script is meant to be stable infrastructure, it should support this from the start.

**Fix:** Add `--depth` flag (default: full clone) so the plan can use it without modifying the script later:

```bash
# in argument parsing:
--depth) DEPTH="$2"; shift 2 ;;

# in clone:
DEPTH_FLAG=""
[[ -n "${DEPTH:-}" ]] && DEPTH_FLAG="--depth $DEPTH"
git clone $DEPTH_FLAG "$URL" "$SCRIPT_DIR/$SOURCE_DIR"
```

Note: `list-source-changes.sh` uses `git log` and `git diff HEAD~N..HEAD` which require commit history. If depth=1, those commands won't work against the source repo. This is fine because `list-source-changes.sh` runs after `pull --ff-only` fetches recent history, but the interaction should be documented.

---

## LOW — Design concerns

### SW-5: No `git-pull.sh` script

The most repeated inline git command across the remediation plan is:

```bash
git -C {dir} pull --ff-only    # refresh-wiki, resolve-issues
git -C {dir} pull --rebase     # save
```

These appear in 3 different commands and the plan keeps them inline because "conflict handling needs LLM judgment." But the pull itself is deterministic — only the decision of what to do after a conflict needs judgment.

A `git-pull.sh` script could:
- Accept `--ff-only` or `--rebase` mode
- Return exit code 0=clean, 1=conflict, 2=network error
- On conflict, output the conflicting files for the LLM to display

This would eliminate the last inline git operations and make `Bash(git -C *:*)` unnecessary in `settings.json`.

### SW-6: Plan layering risk — scripts assumed stable across waves

The remediation plan has 5 waves editing the same command files:

```
resolve-issues.md: Wave 1 → Wave 2 → Wave 3 → Wave 4 → Wave 5
```

Wave 1 adds script calls. Wave 2 restructures around agents. Wave 3 adds more script calls. Each wave assumes prior work is preserved, but there's no explicit instruction saying "preserve the `resolve-workspace.sh` call from Task 1A when restructuring in Task 2D."

**Fix:** Add a principle to the plan: "Each wave builds on prior waves. When restructuring a command, preserve all script calls and exit code handling from earlier waves. If a script call needs to move within the command flow, note the change explicitly."

### SW-7: Inconsistent output formats across scripts

Three different output styles:
- `resolve-workspace.sh`: eval-able `KEY='value'` pairs
- `clone-workspace.sh`: JSON object
- `check-wiki-safety.sh`: custom `KEY=value` + heredoc format

This means consumers need three different parsing strategies. The LLM can handle any format, but consistency would reduce prompt complexity and make the scripts easier to compose.

**Fix (future):** Standardize on JSON for all scripts that return structured data. `resolve-workspace.sh` is the hardest to convert (currently designed for `eval`), but could output JSON that the command parses with `jq` or reads directly.

---

## Summary

| ID | Severity | Script | Issue |
|----|----------|--------|-------|
| SW-1 | HIGH | `resolve-workspace.sh` | eval injection via unescaped single quotes |
| SW-2 | MEDIUM | `wiki-save.sh` | `git add -A` stages junk files |
| SW-3 | MEDIUM | `check-wiki-safety.sh` | fragile `__EOF__` delimiter |
| SW-4 | MEDIUM | `clone-workspace.sh` | missing `--depth` flag |
| SW-5 | LOW | (missing) | no `git-pull.sh` script |
| SW-6 | LOW | (plan) | no "preserve prior wave work" principle |
| SW-7 | LOW | (all) | inconsistent output formats |
