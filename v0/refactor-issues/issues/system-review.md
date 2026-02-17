# System Review: Claude Commands

Critical review of all 7 slash commands performed by parallel Opus explorer agents.
Each agent read the command file, CLAUDE.md, guidance files, and cross-command dependencies.

**Date:** 2025-02-15
**Scope:** `.claude/commands/` — up, down, init-wiki, proofread-wiki, refresh-wiki, revise-wiki, save

---

## Cross-Cutting Issues

### CRITICAL: Subagent permission model breaks mutation-based architectures

The single most important finding. `MEMORY.md` documents that Task subagents are denied `Edit`, `Write`, and `Bash` regardless of the user's permission mode. This breaks every command that delegates mutations to subagents:

| Command | What's broken |
|---------|---------------|
| `init-wiki` | Phase 3 writer agents use `Write` to create pages — denied |
| `proofread-wiki` | Phase 3/4 agents write to `.proofread/` via `Bash` — denied |
| `refresh-wiki` | Phase 3 update agents use `Edit` on wiki pages — denied |
| `revise-wiki` | Phase 2 fixer agents use `Edit`; Phase 3 closer agents use `Bash` for `gh` — denied |

**Fix pattern:** Restructure so subagents only analyze and return results. The orchestrator applies all mutations (edits, writes, bash commands) itself.

### HIGH: Workspace selection step ordering deviates from CLAUDE.md in every command

CLAUDE.md puts the "no configs exist -> stop" check at step 2 (early exit). Every command except `/up` and `/down` moves it to step 5 (after argument matching, auto-select, and prompt — all of which operate on an empty list).

**Affected:** init-wiki, proofread-wiki, refresh-wiki, revise-wiki, save.

**Fix:** Either faithfully reproduce CLAUDE.md's step order (no-configs check at step 2), or replace inline steps with a reference: "Follow the Workspace selection procedure in CLAUDE.md."

### MEDIUM: No `git pull` before operating on repos

No command pulls the latest source or wiki changes before operating:

- `/refresh-wiki` analyzes stale source code
- `/revise-wiki` edits stale wiki pages
- `/save` pushes without pull/rebase, failing on diverged remotes

### MEDIUM: `TaskOutput` missing from some `allowed-tools` lists

`init-wiki.md` uses `TaskOutput` in its instructions but doesn't list it in `allowed-tools`.

---

## Per-Command Findings

### `/up` — 1 CRITICAL, 2 HIGH, 4 MEDIUM, 6 LOW

| # | Severity | Finding |
|---|----------|---------|
| 1 | CRITICAL | Step ordering: existence check references interview values before the interview runs (Step 2 depends on Step 3 output) |
| 2 | HIGH | Config file written (Step 4) before directories are created (Step 5) — Write tool will fail |
| 3 | HIGH | Config persists after clone failure — zombie workspace blocks re-run with "Already got that one" |
| 4 | MEDIUM | No partial-state recovery: if previous `/up` failed mid-way, no way to resume without `/down` first |
| 5 | MEDIUM | Relative paths used throughout but working directory assumption is implicit |
| 6 | MEDIUM | If `workspace/{owner}/{repo}` already exists on disk (manual clone, failed cleanup), `git clone` fails |
| 7 | MEDIUM | No idempotency — running `/up` twice for the same repo requires `/down` in between |
| 8 | LOW | No `.git` suffix stripping from clone URLs |
| 9 | LOW | No validation of parsed owner/repo against GitHub |
| 10 | LOW | Wiki clone failure not reflected in config — downstream commands assume `wikiDir` exists |
| 11 | LOW | "One or two AskUserQuestion calls" phrasing is misleading — 3 questions always fit in one call |
| 12 | LOW | No `--depth 1` shallow clone for read-only source repo |
| 13 | LOW | Clone URL passed to shell without input validation (URL pattern check) |

### `/down` — 0 CRITICAL, 3 HIGH, 6 MEDIUM, 7 LOW

| # | Severity | Finding |
|---|----------|---------|
| 1 | HIGH | `rm -rf` uses relative paths from YAML config — wrong cwd = catastrophic deletion |
| 2 | HIGH | No path validation before `rm -rf` — a corrupted config with `sourceDir: "/"` would be catastrophic |
| 3 | HIGH | Same issue from security angle: no guard that paths are within `workspace/` before deletion |
| 4 | MEDIUM | `git log @{u}..HEAD` fails with fatal error when no upstream tracking branch exists |
| 5 | MEDIUM | No handling for missing/corrupted config files or partially-broken workspaces |
| 6 | MEDIUM | Workspace selection diverges from CLAUDE.md canonical algorithm (inlines its own variant) |
| 7 | MEDIUM | "Abort" semantics unclear in `--all` mode — skip this workspace or stop everything? |
| 8 | MEDIUM | No atomic cleanup — partial removal on failure leaves half-deleted workspace |
| 9 | MEDIUM | Windows file locking: open editors or search indexer will cause `rm -rf` to fail silently |
| 10 | LOW | `{owner}` and `{repo}` placeholders used in rm commands but never explicitly derived |
| 11 | LOW | `--all --force` silently destroys every workspace with zero confirmation |
| 12 | LOW | Empty parent directories (`workspace/config/`, `workspace/`) never cleaned up |
| 13 | LOW | No `--dry-run` flag for previewing what would be removed |
| 14 | LOW | Two separate safety checks (uncommitted + unpushed) create double-prompt friction |
| 15 | LOW | No `git fetch` before unpushed-commit check — tracking ref may be stale |
| 16 | LOW | No network failure handling for git operations |

### `/init-wiki` — 1 CRITICAL, 3 HIGH, 6 MEDIUM, 4 LOW

| # | Severity | Finding |
|---|----------|---------|
| 1 | CRITICAL | `TaskOutput` missing from `allowed-tools` — entire swarm collection is broken |
| 2 | HIGH | Writer subagents use `Write` tool — denied per MEMORY.md permission model |
| 3 | HIGH | Workspace selection step order contradicts CLAUDE.md (no-configs check at step 5 instead of step 2) |
| 4 | HIGH | `subagent_type: Explore` may not be a recognized Task tool subagent type |
| 5 | MEDIUM | `grep -v '^\.'` intended to exclude `.git` but excludes all dotfiles — imprecise |
| 6 | MEDIUM | Phase 2 planning agent blocking/background behavior not explicitly stated |
| 7 | MEDIUM | No guidance for handling large repos or agent token limits in Phase 1 explorers |
| 8 | MEDIUM | Sidebar wiki link format ambiguous — `[[Page Title\|Page-Filename]]` may include `.md` extension, breaking links |
| 9 | MEDIUM | No error handling or retry logic for writer agent failures |
| 10 | MEDIUM | Orchestrator does content authoring (sidebar) despite coordinator-only role pattern |
| 11 | LOW | "kebab-case" terminology is wrong — example `Getting-Started.md` is Title-Case-Hyphenated |
| 12 | LOW | `Edit` tool listed in `allowed-tools` but never used |
| 13 | LOW | Writing principles duplicated inline and in `editorial-guidance.md` — dual source of truth |
| 14 | LOW | No idempotency or recovery from partial failure (wiki-already-has-content check blocks re-run) |

### `/proofread-wiki` — 2 CRITICAL, 5 HIGH, 7 MEDIUM, 8 LOW

| # | Severity | Finding |
|---|----------|---------|
| 1 | CRITICAL | Phase 3/4 subagents write files via `Bash` — denied per MEMORY.md |
| 2 | CRITICAL | Entire file I/O architecture (subagents write to `.proofread/`) is broken |
| 3 | HIGH | `file-issue.sh` never receives config path as second argument — fails in multi-workspace setups |
| 4 | HIGH | Phase 5 dedup agent runs `gh issue list` via Bash subagent — denied |
| 5 | HIGH | Phase 3 has no failure/retry handling (unlike Phase 4 which does) |
| 6 | HIGH | Fallback file path uses `{sourceDir}` (e.g., `workspace/acme/Repo`) instead of `{repo}` slug |
| 7 | HIGH | Template `recommendation` field is `required: true` but command says "omit when not applicable" |
| 8 | MEDIUM | No rate-limit handling for `gh issue create` (secondary limit ~80 req/min) |
| 9 | MEDIUM | No upper bound on issue count — 20 pages x 5 findings = 100 issues could flood the tracker |
| 10 | MEDIUM | `_Sidebar.md` might not exist — no handling for missing sidebar |
| 11 | MEDIUM | Template field instruction says "match field ids" but example uses label values (mismatch) |
| 12 | MEDIUM | `--pass` flag values don't explicitly map to template dropdown option text |
| 13 | MEDIUM | Phase 1 sidebar issue bypasses Phase 5 dedup — could create duplicate issues |
| 14 | MEDIUM | Phase 5 dedup agent is a single point of failure with no retry logic |
| 15 | LOW | `--pass` parsing: no spec for `--pass=structural` vs `--pass structural`, case sensitivity |
| 16 | LOW | No cleanup of `.proofread/` cache from previous runs — stale findings picked up |
| 17 | LOW | Phase 1 sidebar issue filed "using Phase 6 process" before Phase 6 exists — circular dependency |
| 18 | LOW | Background vs blocking agent terminology is ambiguous in Phase 5 |
| 19 | LOW | "Two at a time" parallelism batching pattern is unusual and underspecified |
| 20 | LOW | No timeout guidance for Task agents |
| 21 | LOW | `.proofread/` directory not in `.gitignore` — creates git noise |
| 22 | LOW | Issue title injection risk (low — generated by Claude, not raw user input) |

### `/refresh-wiki` — 1 CRITICAL, 3 HIGH, 7 MEDIUM, 8 LOW

| # | Severity | Finding |
|---|----------|---------|
| 1 | CRITICAL | Phase 3 update agents use `Edit` — denied per MEMORY.md |
| 2 | HIGH | No `git pull` before analyzing — source and wiki repos may be arbitrarily stale |
| 3 | HIGH | Source-to-wiki mapping relies on vague heuristics — core logic underspecified |
| 4 | HIGH | Phase 1 mapping is the weakest link in an otherwise sound design |
| 5 | MEDIUM | Workspace selection step ordering differs from CLAUDE.md |
| 6 | MEDIUM | `HEAD~50` fails with fatal error on repos with fewer than 50 commits |
| 7 | MEDIUM | No handling for missing `_Sidebar.md` — discovers zero pages, reports false "up to date" |
| 8 | MEDIUM | No deduplication of wiki pages across tuples — concurrent edit race condition possible |
| 9 | MEDIUM | No validation of explorer agent output format — garbage in, garbage out |
| 10 | MEDIUM | Explorer agent read depth ambiguous — no guidance on transitive dependencies |
| 11 | MEDIUM | "Correct content" field ambiguous — replacement prose vs. description of facts |
| 12 | MEDIUM | No retry logic for failed agents (unlike proofread-wiki which specifies retry-once) |
| 13 | LOW | No signal when source changes imply a new wiki page is needed |
| 14 | LOW | Deleted source files passed to explorers who can't read them |
| 15 | LOW | No way to scope refresh to specific pages or directories |
| 16 | LOW | Explorer agents use `model: sonnet` while all other commands use `model: opus` for exploration |
| 17 | LOW | Orchestrator doesn't read guidance files itself — can't validate agent output |
| 18 | LOW | No batching or parallelism limits for large projects |
| 19 | LOW | 50-commit lookback is hardcoded and not configurable |
| 20 | LOW | Source repo READONLY enforced only by natural language, not structurally |
| 21 | LOW | Phase 3 re-reads source files, undermining explorer's "Correct content" field |
| 22 | LOW | No incremental refresh tracking — re-examines same commits on next run |

### `/revise-wiki` — 2 CRITICAL, 4 HIGH, 7 MEDIUM, 8 LOW

| # | Severity | Finding |
|---|----------|---------|
| 1 | CRITICAL | Phase 2 fixer agents use `Edit` — denied per MEMORY.md |
| 2 | CRITICAL | Entire architecture contradicts known platform limitations |
| 3 | HIGH | Phase 3 `subagent_type: Bash` agents also denied — close/comment operations fail |
| 4 | HIGH | No `git pull` before editing — edits based on stale wiki content |
| 5 | HIGH | Hardcoded "reference-style not tutorial" tone overrides user's configured `tone` field |
| 6 | HIGH | Issues closed before edits are pushed — false-positive closed state on GitHub |
| 7 | MEDIUM | No handling for zero open issues — should exit early with message |
| 8 | MEDIUM | No handling for issues referencing deleted or renamed wiki pages |
| 9 | MEDIUM | Issue body parsing format (`### Label` blocks) never specified — fragile implicit assumption |
| 10 | MEDIUM | Fixer agents not instructed to read editorial guidance files (unlike refresh-wiki agents) |
| 11 | MEDIUM | Source file paths from issues not prefixed with `{sourceDir}/` — may not resolve |
| 12 | MEDIUM | No retry or error handling for failed fixer agents |
| 13 | MEDIUM | No handling for `gh issue close` / `gh issue comment` failures |
| 14 | MEDIUM | Shell injection risk in `--body` argument constructed from issue-derived text |
| 15 | LOW | No reminder to run `/save` after edits are applied |
| 16 | LOW | `--limit 100` silently truncates large issue sets |
| 17 | LOW | No instruction to read `{sourceDir}/CLAUDE.md` for project conventions |
| 18 | LOW | "fix-docs" name in Constraints should be "revise-wiki" (leftover from rename) |
| 19 | LOW | Ambiguous whether `-plan` can combine with issue-number filters |
| 20 | LOW | Haiku model for close/comment agents may struggle with complex skip reasons |
| 21 | LOW | Source file reads not sandboxed to `{sourceDir}/` — could read outside source tree |
| 22 | LOW | No deduplication of effort across runs |

### `/save` — 0 CRITICAL, 3 HIGH, 5 MEDIUM, 6 LOW

| # | Severity | Finding |
|---|----------|---------|
| 1 | HIGH | `git status --porcelain` doesn't detect unpushed commits — false "up to date" report |
| 2 | HIGH | No push failure handling (auth failure, network error, non-fast-forward) |
| 3 | HIGH | No `pull --rebase` before push — fails silently on diverged remote |
| 4 | MEDIUM | Workspace selection step ordering deviates from CLAUDE.md |
| 5 | MEDIUM | No merge conflict handling if pull/rebase is added |
| 6 | MEDIUM | Ambiguous commit message instruction — no guidance on length, style, or cutoff for many files |
| 7 | MEDIUM | "Nothing to save" error message diverges from convention ("run `/up` first") |
| 8 | MEDIUM | No guard against source repo operations beyond natural language instruction |
| 9 | LOW | No confirmation step between showing diff and committing/pushing |
| 10 | LOW | No handling for missing wiki directory or non-git `{wikiDir}` |
| 11 | LOW | Step 7 "confirm push succeeded" doesn't specify how (exit code? git log?) |
| 12 | LOW | `git add -A` stages everything including potential temp files or artifacts |
| 13 | LOW | No handling for detached HEAD or unusual git states |
| 14 | LOW | No credential/secret check before staging |

---

## Aggregate Severity Counts

| Severity | Count |
|----------|-------|
| CRITICAL | 7 |
| HIGH | 22 |
| MEDIUM | ~35 |
| LOW | ~45 |

---

## Top 5 Recommended Fixes (by impact)

### 1. Restructure subagent architecture across all swarm commands

Use subagents for read-only analysis only. The orchestrator applies all mutations (edits, writes, bash commands) itself. This resolves all 7 CRITICAL findings and several HIGH findings across `init-wiki`, `proofread-wiki`, `refresh-wiki`, and `revise-wiki`.

### 2. Add `git pull` steps

Pull source repo before analysis (`refresh-wiki`). Pull wiki repo before editing (`revise-wiki`, `refresh-wiki`). Pull with rebase before push (`save`). Add merge conflict handling.

### 3. Fix workspace selection ordering

Either faithfully reproduce CLAUDE.md's step order (no-configs check at step 2), or replace inline steps with a simple reference: "Follow the Workspace selection procedure in CLAUDE.md." Affects 5 commands.

### 4. Add path validation in `/down`

Assert that `sourceDir` and `wikiDir` resolve to absolute paths within `workspace/` before `rm -rf`. Reject any path that doesn't match the expected pattern. Use absolute paths for all destructive operations.

### 5. Fix `/up` step ordering and atomicity

Move directory creation before config write. Move config write after successful clones. Move existence check to after URL parsing but before remaining interview questions. Add cleanup on clone failure.
