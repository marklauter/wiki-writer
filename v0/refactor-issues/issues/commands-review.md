# Code review findings

## Bugs

### 1. file-issue.sh — label parsing is broken

**File:** `.scripts/file-issue.sh:47-51`

The label extraction logic never extracts `documentation`:

```bash
done < <(grep -A1 '^labels:' "$TEMPLATE" | tail -1 | tr -d '[]' | tr ',' '\n')
```

`grep -A1 '^labels:'` outputs two lines: the `labels: ["documentation"]` line and the next line (`body:`). `tail -1` picks `body:`, not the labels line. Every issue filed by this script gets `--label body:` instead of `--label documentation`.

**Downstream impact:** `proofread-wiki` Phase 5 deduplication queries `gh issue list --label documentation` — it would never find previously filed issues, causing duplicates on every run.

**Fix:** Replace `tail -1` with `head -1 | sed 's/^labels:[[:space:]]*//'`:

```bash
done < <(grep '^labels:' "$TEMPLATE" | head -1 | sed 's/^labels:[[:space:]]*//' | tr -d '[]' | tr ',' '\n')
```

### 2. save.md — misses unpushed commits

**File:** `.claude/commands/save.md:22-24`

Step 2 only checks `git status --porcelain`, which shows uncommitted changes. If a previous `/save` committed but the push failed, running `/save` again reports "already up to date" and stops — the committed changes silently never get pushed.

`down.md` correctly checks both uncommitted and unpushed (`git log @{u}..HEAD --oneline`). `/save` should do the same.

### 3. proofread-wiki.md — Explore agents told to write files

**File:** `.claude/commands/proofread-wiki.md:63-73`

Phase 3 launches `subagent_type: Explore` agents and instructs them to write summaries to files. Explore agents don't have the Write tool. The instructions say "via Bash" as a workaround, but this contradicts the tool usage guidelines that say Bash shouldn't be used for file operations. Consider using `general-purpose` agents here, or have the orchestrator capture return values and write the files itself.

Same issue applies to Phase 4 reviewer agents writing findings files.

## Design issues

### 4. Subagent write permissions — fundamental friction with the swarm pattern

Multiple commands assume Task subagents can Edit/Write files:

- `init-wiki.md` Phase 3 — writer agents use Write
- `refresh-wiki.md` Phase 3 — update agents use Edit
- `resolve-issues.md` Phase 2 — fixer agents use Edit

Subagents do not inherit the user's permission mode. Even in "edit automatically" mode, subagents get denied Edit/Write. This means the core swarm pattern (parallel agents editing wiki files) fails at runtime unless the user manually approves each tool call.

**Mitigations to consider:**

- Have subagents return the edits as text, then apply them from the orchestrator
- Accept the approval prompts as a UX tradeoff
- Document the required permission setup

### 5. proofread-wiki.md — file-issue.sh not covered by permissions

**File:** `.claude/commands/proofread-wiki.md:142-166`

`settings.json` allows `Bash(gh issue create:*)` but the actual filing goes through `bash .scripts/file-issue.sh`. Neither settings file allows `Bash(bash .scripts/*:*)` or `Bash(bash:*)`, so every issue filing requires manual user approval — potentially dozens of approvals per proofread run.

### 6. proofread-wiki.md — no config path passed to file-issue.sh for multi-workspace

**File:** `.claude/commands/proofread-wiki.md:142-166`

The Phase 6 example calls `bash .scripts/file-issue.sh "TITLE" <<'EOF'` with no second argument. With multiple workspaces loaded, the script's auto-detection fails with "error: multiple workspaces found." The config path should be passed as the second argument.

## Missing from .gitignore

### 7. .proofread/ and issues/ not gitignored

Two generated directories are written to the project root but not gitignored:

- `.proofread/` — created by `proofread-wiki` Phase 3 (`mkdir -p .proofread/{repo}`)
- `issues/` — created by `proofread-wiki` Phase 6 failure fallback (`issues/{sourceDir}/...`)

Both would be tracked by git if they're ever created.

## Inconsistencies

### 8. resolve-issues.md — says `docs`-labeled, system uses `documentation`

**File:** `.claude/commands/resolve-issues.md:8`

Line 8: "open `docs`-labeled GitHub issues." The actual label used everywhere is `documentation` (issue template, proofread-wiki's `gh issue list --label documentation`). The Phase 1 `gh` command on line 35 correctly uses `--label documentation`, so this is a description-only mismatch.

### 9. resolve-issues.md — points agents to wrong guidance source

**File:** `.claude/commands/resolve-issues.md:57,79`

Tells fixer agents to "read `CLAUDE.md` for writing principles." `CLAUDE.md` contains workspace layout and config format — not writing principles. The actual writing principles are in `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md`, which other commands (init-wiki, refresh-wiki) correctly reference.

### 10. up.md — step 2 depends on step 3's output

**File:** `.claude/commands/up.md:17-21`

Step 2 says "After the interview step provides the `{owner}` and `{repo}` values, check if workspace exists." But step 3 is the interview. The dependency is acknowledged in the text but the numbering implies sequential execution. Should either reorder or fold the check into step 3.

## Robustness

### 11. refresh-wiki.md — HEAD~50 fails on small repos

**File:** `.claude/commands/refresh-wiki.md:33`

`git diff --name-only HEAD~50..HEAD` errors if the repo has fewer than 50 commits. Should derive the range from `git log --oneline -50`'s actual output, or handle the error.

## Summary

| # | Severity | Item |
|---|----------|------|
| 1 | Bug | Label parsing broken in file-issue.sh |
| 2 | Bug | save.md misses unpushed commits |
| 3 | Bug | Explore agents told to write files without Write tool |
| 4 | Design | Subagent write permissions break swarm pattern |
| 5 | Design | file-issue.sh not in allowed permissions |
| 6 | Design | No config path for multi-workspace issue filing |
| 7 | Gitignore | .proofread/ and issues/ not ignored |
| 8 | Inconsistency | Wrong label name in resolve-issues description |
| 9 | Inconsistency | Wrong guidance reference in resolve-issues |
| 10 | Inconsistency | Step ordering in up.md |
| 11 | Robustness | HEAD~50 fails on repos with <50 commits |
