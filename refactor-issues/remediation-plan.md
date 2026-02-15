# Remediation Plan

Sequenced fix plan for all issues in `refactor-issues/fusion.md`.
Ordered to minimize complexity and maximize parallel Opus task execution.

**Principle:** Each wave contains only tasks that are independent of each other, so every task within a wave can run as a parallel Opus agent. Later waves build on earlier ones.

---

## Wave 1 — Foundation Fixes

**Goal:** Fix standalone bugs and structural issues that don't touch swarm command internals.
**Parallelism:** 5 independent tasks, all run concurrently.

### Task 1A: Workspace selection — centralize and simplify

**Fixes:** Fusion §2.1, §2.2

Replace all inline workspace selection steps (in init-wiki, proofread-wiki, refresh-wiki, resolve-issues, save, down) with a single line referencing CLAUDE.md:

> Follow the **Workspace selection** procedure in CLAUDE.md to resolve `repo`, `sourceDir`, `wikiDir`, `audience`, and `tone`.

Verify CLAUDE.md's canonical algorithm has the "no configs → stop" check at step 2 (it does). Remove all divergent inline variants.

**Files:** `.claude/commands/init-wiki.md`, `.claude/commands/proofread-wiki.md`, `.claude/commands/refresh-wiki.md`, `.claude/commands/resolve-issues.md`, `.claude/commands/save.md`, `.claude/commands/down.md`

### Task 1B: `.gitignore` — add generated directories

**Fixes:** Fusion §10.1

Add `.proofread/` and `issues/` to `.gitignore`.

**Files:** `.gitignore`

### Task 1C: `file-issue.sh` — fix label parsing and add config path

**Fixes:** Fusion §6.1, §6.3

1. Fix label extraction: replace `tail -1` with `head -1 | sed 's/^labels:[[:space:]]*//'`
2. Accept optional config path as second argument (after title). Fall back to auto-detect if not provided.
3. Update `proofread-wiki.md` Phase 6 example to pass the config path.

**Files:** `.scripts/file-issue.sh`, `.claude/commands/proofread-wiki.md` (Phase 6 example only)

### Task 1D: `/up` — fix step ordering and atomicity

**Fixes:** Fusion §4.1, §4.2, §4.3, §4.4, §4.5, §4.6

Rewrite `/up` flow:

1. Interview (repo URL, audience, tone) — collect all inputs first.
2. Derive `{owner}` and `{repo}` from URL. Strip `.git` suffix if present.
3. Check if workspace already exists → ask to confirm overwrite or abort.
4. Create directory structure (`workspace/{owner}/`, `workspace/config/{owner}/{repo}/`).
5. Clone source repo to `workspace/{owner}/{repo}`. On failure → clean up dirs and config → stop.
6. Clone wiki repo to `workspace/{owner}/{repo}.wiki`. On failure → warn but continue (wiki may not exist yet).
7. Write config to `workspace/config/{owner}/{repo}/workspace.config.yml` — only after successful clone(s).
8. Read source `CLAUDE.md` if present. Confirm workspace is ready.

**Files:** `.claude/commands/up.md`

### Task 1E: `/down` — add path validation and safety

**Fixes:** Fusion §5.1, §5.2, §5.3, §5.4, §5.5

Add before any `rm -rf`:

1. Resolve paths to absolute.
2. Assert both `sourceDir` and `wikiDir` are within the `workspace/` directory (string prefix check).
3. Assert paths match the expected pattern `workspace/{owner}/{repo}[.wiki]`.
4. If validation fails → refuse to delete and show the suspicious path.

Also:
- Handle `git log @{u}..HEAD` failure when no upstream exists (catch the error, treat as "nothing to push").
- On partial deletion failure, report what was removed and what remains.

**Files:** `.claude/commands/down.md`

---

## Wave 2 — Subagent Architecture Restructuring

**Goal:** Fix the CRITICAL subagent permission issue — the single most impactful change.
**Parallelism:** 4 independent tasks (one per swarm command), all run concurrently.
**Depends on:** Wave 1 (workspace selection is already cleaned up, so Phase 0 is stable).

Each task follows the same pattern: subagents become read-only analyzers that return structured results; the orchestrator applies all mutations.

### Task 2A: `init-wiki` — orchestrator writes pages

**Fixes:** Fusion §1.1 (init-wiki), §9.9, §9.10

Restructure:
- Phase 1 (explore): unchanged — already read-only.
- Phase 2 (plan): unchanged — already read-only.
- Phase 3 (write): Writer agents return page content as their result (title + markdown body). The orchestrator collects results via `TaskOutput` and uses `Write` to create each file.
- Orchestrator writes `_Sidebar.md` and `Home.md`.

Also fix:
- Add `TaskOutput` to `allowed-tools`.
- Remove unused `Edit` from `allowed-tools`.

**Files:** `.claude/commands/init-wiki.md`

### Task 2B: `proofread-wiki` — orchestrator writes findings and files issues

**Fixes:** Fusion §1.1 (proofread-wiki), §1.2, §6.2

Restructure:
- Phase 3 (source exploration): Explorer agents return summaries as their result text. Orchestrator writes to `.proofread/{repo}/source/`.
- Phase 4 (review): Reviewer agents return findings as structured text. Orchestrator writes to `.proofread/{repo}/findings/`.
- Phase 5 (dedup): Orchestrator runs `gh issue list --label documentation` directly (not via subagent). Filters findings.
- Phase 6 (file issues): Orchestrator calls `bash .scripts/file-issue.sh` directly — covered by existing permissions or add `Bash(bash .scripts/*:*)` to settings.

Also fix:
- Add `bash .scripts/file-issue.sh` to allowed Bash patterns in settings, OR replace `file-issue.sh` calls with direct `gh issue create` (which is already allowed).

**Files:** `.claude/commands/proofread-wiki.md`, `.claude/settings.json` (if adding permission)

### Task 2C: `refresh-wiki` — orchestrator applies edits

**Fixes:** Fusion §1.1 (refresh-wiki)

Restructure:
- Phase 2 (explore): Explorer agents return structured findings (wiki page, location, what changed, correct content). Orchestrator collects via `TaskOutput`.
- Phase 3 (update): Orchestrator reads each affected wiki page, applies the edits using `Edit`, and reads the editorial guidance itself.

Remove the Phase 3 subagent layer entirely — the orchestrator has enough context from the explorer results to apply edits directly.

**Files:** `.claude/commands/refresh-wiki.md`

### Task 2D: `resolve-issues` — orchestrator applies edits and closes issues

**Fixes:** Fusion §1.1 (resolve-issues), §1.3

Restructure:
- Phase 2 (fix): Fixer agents return proposed edits as structured text (file, old content, new content, rationale). Orchestrator applies each edit using `Edit`.
- Phase 3 (close): Orchestrator runs `gh issue close` and `gh issue comment` directly — no Bash subagents needed.

**Files:** `.claude/commands/resolve-issues.md`

---

## Wave 3 — Git Workflow

**Goal:** Add proper git pull/push handling.
**Parallelism:** 3 independent tasks.
**Depends on:** Wave 2 (command structure is now stable).

### Task 3A: `refresh-wiki` — pull before analysis

**Fixes:** Fusion §3.1 (refresh-wiki), §9.1

Add to Phase 0 (after workspace selection):
1. `git -C {sourceDir} pull --ff-only` (source repo — get latest).
2. `git -C {wikiDir} pull --ff-only` (wiki repo — get latest before editing).

Also fix HEAD~50:
- Use `git -C {sourceDir} log --oneline -50 --format=%H | tail -1` to get the actual oldest commit hash, then diff against that. If the repo has fewer than 50 commits, diff against the root.

**Files:** `.claude/commands/refresh-wiki.md`

### Task 3B: `resolve-issues` — pull before editing, don't close before push

**Fixes:** Fusion §3.1 (resolve-issues), §3.5

Add to Phase 0:
1. `git -C {wikiDir} pull --ff-only`

Change Phase 3:
- Don't close issues immediately. Instead, collect the list of issues to close.
- At the end, instruct the user to run `/save` and then close the issues (or auto-close after confirming push succeeded).

**Files:** `.claude/commands/resolve-issues.md`

### Task 3C: `/save` — detect unpushed, pull before push, handle failures

**Fixes:** Fusion §3.2, §3.3, §3.4

Rewrite `/save` flow:
1. Workspace selection (already a CLAUDE.md reference from Wave 1).
2. Check for uncommitted changes (`git status --porcelain`).
3. Check for unpushed commits (`git log @{u}..HEAD --oneline 2>/dev/null`).
4. If neither → "Nothing to save."
5. If uncommitted → show diff, generate commit message, stage and commit.
6. `git -C {wikiDir} pull --rebase` — if merge conflict, show the conflict and stop.
7. `git -C {wikiDir} push` — check exit code, report success or failure with actionable message.

**Files:** `.claude/commands/save.md`

---

## Wave 4 — Command Hardening

**Goal:** Fix remaining MEDIUM issues — guidance refs, error handling, edge cases.
**Parallelism:** 4 independent tasks (one per swarm command).
**Depends on:** Waves 2–3 (command structure and git workflow are stable).

### Task 4A: `resolve-issues` — guidance, tone, and edge cases

**Fixes:** Fusion §8.1, §8.2, §8.3, §8.4, §9.5, §9.6, §9.7, §9.8

1. Change fixer agent prompt: read `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md` (not CLAUDE.md).
2. Remove hardcoded "reference-style" tone — use `{tone}` from workspace config.
3. Fix description: `docs` → `documentation`.
4. Fix constraint name: `fix-docs` → `resolve-issues`.
5. Add early exit when zero issues found.
6. Document expected issue body format (or make parsing resilient).
7. Prefix source file paths with `{sourceDir}/`.
8. Sanitize issue body text before passing to `--body` shell argument.

**Files:** `.claude/commands/resolve-issues.md`

### Task 4B: `refresh-wiki` — mapping, dedup, and edge cases

**Fixes:** Fusion §9.2, §9.3, §9.4

1. Improve source-to-wiki mapping heuristic: after identifying changed source files, read `_Sidebar.md` to get the wiki page list, then use the orchestrator (not a heuristic) to match source files to wiki pages by reading each page's content for source references.
2. Deduplicate wiki pages across explorer tuples — ensure each wiki page appears in at most one tuple.
3. Filter out deleted source files before passing to explorers (check `git show HEAD:{file}` to confirm existence).

**Files:** `.claude/commands/refresh-wiki.md`

### Task 4C: `proofread-wiki` — edge cases and robustness

**Fixes:** Fusion §6.4, §6.7, §6.8, §9.14, §9.15, §9.16, §9.17, §9.18

1. Fix template `recommendation` field: make optional or remove `required: true`.
2. Add issue count cap (configurable, default 20) to prevent tracker flooding.
3. Route Phase 1 sidebar issues through Phase 5 dedup.
4. Specify `--pass` flag parsing: case-insensitive, accept both `--pass structural` and `--pass=structural`.
5. Clear `.proofread/{repo}/` at start of each run to avoid stale findings.
6. Fix Phase 1 circular reference — remove "using Phase 6 process" or move sidebar review to after Phase 6 is defined.
7. Add check for `_Sidebar.md` existence.
8. Align template field instructions with example.

**Files:** `.claude/commands/proofread-wiki.md`, `.github/ISSUE_TEMPLATE/` (if template needs update)

### Task 4D: `init-wiki` — edge cases and cleanup

**Fixes:** Fusion §8.5, §8.6, §9.11, §9.12, §9.13, §10.13 (subagent_type)

1. Remove inline writing principles — reference `editorial-guidance.md` instead.
2. Fix terminology: "kebab-case" → "Title-Case-Hyphenated" (or just show the example without naming the convention).
3. Fix `grep -v '^\.'` → `grep -v '^\.\(git\)$'` or use a more precise exclusion.
4. Clarify sidebar link format: no `.md` extension in `[[links]]`.
5. Move sidebar authoring into a dedicated writer agent (or keep in orchestrator but document the exception).
6. Verify `subagent_type: Explore` is valid; if not, switch to `general-purpose` for read-only exploration.

**Files:** `.claude/commands/init-wiki.md`

---

## Wave 5 — Polish

**Goal:** LOW-severity items. Optional but worth doing for robustness.
**Parallelism:** 3 independent tasks.
**Depends on:** Wave 4.

### Task 5A: `/up` and `/down` minor fixes

**Fixes:** Fusion §4.7, §5.6

`/up`:
- Validate parsed owner/repo against GitHub (`gh repo view`) before cloning.
- Use `--depth 1` for source repo clone.
- Handle wiki clone failure gracefully (wiki may not exist yet).

`/down`:
- Consolidate two safety checks (uncommitted + unpushed) into one prompt.
- Add `git fetch` before unpushed check.
- Clean up empty parent directories after deletion.

**Files:** `.claude/commands/up.md`, `.claude/commands/down.md`

### Task 5B: `resolve-issues` and `save` minor fixes

**Fixes:** Fusion §10.3, §10.4, §10.5, §10.11, §10.12, §9.19, §9.20

`resolve-issues`:
- Add "run `/save` to push changes" reminder at end.
- Increase or remove `--limit 100`.
- Add instruction to read `{sourceDir}/CLAUDE.md`.

`save`:
- Add commit message guidance (imperative mood, ≤72 chars first line, summarize if many files).
- Replace `git add -A` with explicit file list from `git status` (exclude temp files).

**Files:** `.claude/commands/resolve-issues.md`, `.claude/commands/save.md`

### Task 5C: `refresh-wiki` and `proofread-wiki` minor fixes

**Fixes:** Fusion §10.6, §10.7, §10.8, §10.9, §10.14

`refresh-wiki`:
- Make commit lookback configurable via `$ARGUMENTS` (default 50).
- Use consistent model for explorer agents (opus or document the sonnet choice).
- When source changes suggest a new page is needed, note it in the output.

`proofread-wiki`:
- Specify parallelism pattern more precisely (e.g., "batch N agents at a time").
- Add timeout guidance for Task agents.

**Files:** `.claude/commands/refresh-wiki.md`, `.claude/commands/proofread-wiki.md`

---

## Execution Summary

```
Wave 1 ─── 5 parallel Opus tasks ─── Foundation fixes
  │
Wave 2 ─── 4 parallel Opus tasks ─── Subagent architecture (CRITICAL)
  │
Wave 3 ─── 3 parallel Opus tasks ─── Git workflow
  │
Wave 4 ─── 4 parallel Opus tasks ─── Command hardening
  │
Wave 5 ─── 3 parallel Opus tasks ─── Polish (optional)
```

| Wave | Tasks | Parallel Agents | Severity Coverage |
|------|-------|-----------------|-------------------|
| 1 | 1A–1E | 5 | HIGH (workspace, up, down), BUG (file-issue), LOW (gitignore) |
| 2 | 2A–2D | 4 | All 7 CRITICAL findings |
| 3 | 3A–3C | 3 | HIGH (git workflow) |
| 4 | 4A–4D | 4 | MEDIUM (guidance, edge cases, error handling) |
| 5 | 5A–5C | 3 | LOW (polish) |
| **Total** | **19 tasks** | **max 5 concurrent** | **All issues covered** |

### File Conflict Matrix

Each file is touched by at most one task per wave — no merge conflicts possible within a wave.

| File | Wave 1 | Wave 2 | Wave 3 | Wave 4 | Wave 5 |
|------|--------|--------|--------|--------|--------|
| `init-wiki.md` | 1A | 2A | — | 4D | — |
| `proofread-wiki.md` | 1A, 1C | 2B | — | 4C | 5C |
| `refresh-wiki.md` | 1A | 2C | 3A | 4B | 5C |
| `resolve-issues.md` | 1A | 2D | 3B | 4A | 5B |
| `save.md` | 1A | — | 3C | — | 5B |
| `up.md` | — | — | — | — | 5A |
| `down.md` | 1A, 1E | — | — | — | 5A |
| `file-issue.sh` | 1C | — | — | — | — |
| `.gitignore` | 1B | — | — | — | — |
| `CLAUDE.md` | — | — | — | — | — |
| `settings.json` | — | 2B | — | — | — |

**Note on Wave 1 conflicts:** Tasks 1A and 1C both touch `proofread-wiki.md`, and 1A and 1E both touch `down.md`. However, 1A only modifies the Phase 0 workspace selection block, while 1C modifies the Phase 6 example and 1E modifies the deletion logic — no overlapping lines. Run them in parallel but verify no conflicts after.
