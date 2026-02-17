# Unified Issue Registry

Merged from two independent reviews performed after the multi-workspace refactor.

| Tag | Source | Approach |
|-----|--------|----------|
| **CR** | `commands-review.md` | Each command reviewed in isolation (11 issues) |
| **SR** | `system-review.md` | Systems-engineering perspective across all 7 commands (~109 issues) |

Duplicates are consolidated under a single entry with both sources cited.
Issues are grouped by concept, not by command.

---

## 1. Subagent Permission Model

**Severity: CRITICAL — affects every swarm command**

Task subagents are denied `Edit`, `Write`, and `Bash` regardless of the user's permission mode. This breaks the core architectural pattern (parallel agents mutating files) in four commands.

### 1.1 Writer/editor subagents cannot mutate files

Every command that delegates file mutations to subagents is broken at runtime.

| Command | What breaks | Sources |
|---------|------------|---------|
| `init-wiki` | Phase 3 writer agents use `Write` to create pages | CR#4, SR init-wiki#2 |
| `proofread-wiki` | Phase 3/4 agents write to `.proofread/` via Bash | CR#3, SR proofread-wiki#1,#2 |
| `refresh-wiki` | Phase 3 update agents use `Edit` on wiki pages | CR#4, SR refresh-wiki#1 |
| `revise-wiki` | Phase 2 fixer agents use `Edit`; Phase 3 closer agents use `Bash` for `gh` | CR#4, SR revise-wiki#1,#2,#3 |

**Fix:** Restructure all swarm commands so subagents only analyze and return results. The orchestrator applies all mutations itself.

### 1.2 `proofread-wiki` uses wrong subagent type for file-writing phases

Phase 3 launches `subagent_type: Explore` agents and instructs them to write files. Explore agents lack the `Write` tool entirely. The command says "via Bash" as a workaround, which contradicts tool-usage guidelines.

**Sources:** CR#3, SR proofread-wiki#1

### 1.3 `revise-wiki` Phase 3 `subagent_type: Bash` agents also denied

Close/comment operations use Bash agents to run `gh issue close` and `gh issue comment` — denied by the permission model.

**Sources:** SR revise-wiki#3

---

## 2. Workspace Selection Consistency

**Severity: HIGH — affects 5 commands**

### 2.1 Step ordering deviates from CLAUDE.md in every non-up/down command

CLAUDE.md puts the "no configs exist → stop" check at step 2 (early exit). Every command except `/up` and `/down` moves it to step 5 — after argument matching, auto-select, and prompt, all of which operate on an empty list.

**Affected:** init-wiki, proofread-wiki, refresh-wiki, revise-wiki, save
**Sources:** SR cross-cutting#2, SR init-wiki#3, SR refresh-wiki#5, SR save#4, SR down#6

**Fix:** Replace inline workspace selection steps with a single reference: "Follow the Workspace selection procedure in CLAUDE.md." This eliminates all divergence.

### 2.2 `/down` inlines its own variant of selection logic

`/down` has a custom workspace selection flow that diverges from the canonical algorithm.

**Sources:** SR down#6

---

## 3. Git Workflow Gaps

**Severity: HIGH — affects 4 commands**

### 3.1 No `git pull` before operating on repos

No command pulls the latest source or wiki changes before operating.

| Command | Consequence |
|---------|------------|
| `refresh-wiki` | Analyzes stale source code |
| `revise-wiki` | Edits stale wiki pages |
| `save` | Pushes without pull/rebase, fails on diverged remotes |

**Sources:** SR cross-cutting#3, SR refresh-wiki#2, SR revise-wiki#4, SR save#3

### 3.2 `/save` misses unpushed commits

`git status --porcelain` only shows uncommitted changes. If a previous `/save` committed but the push failed, the next run reports "already up to date" — committed changes silently never get pushed. `/down` correctly checks both uncommitted and unpushed.

**Sources:** CR#2, SR save#1

### 3.3 `/save` has no push failure handling

No handling for auth failure, network error, or non-fast-forward rejection.

**Sources:** SR save#2

### 3.4 No merge conflict handling

If `pull --rebase` is added to `/save`, there is no guidance for merge conflicts.

**Sources:** SR save#5

### 3.5 `revise-wiki` closes issues before edits are pushed

Issues are marked closed on GitHub while the wiki edits remain local. If `/save` is never run (or fails), GitHub shows issues as resolved but the wiki is unchanged.

**Sources:** SR revise-wiki#6

---

## 4. `/up` — Ordering & Atomicity

**Severity: HIGH**

### 4.1 Step 2 depends on Step 3's output

Existence check references interview values (owner/repo) before the interview runs.

**Sources:** CR#10, SR up#1

### 4.2 Config written before directories exist

Step 4 writes the config file before Step 5 creates the directory structure. `Write` tool fails.

**Sources:** SR up#2

### 4.3 Config persists after clone failure

If `git clone` fails, the config file remains. The zombie config blocks re-runs ("Already got that one") and requires manual `/down`.

**Sources:** SR up#3

### 4.4 No partial-state recovery

If a previous `/up` failed mid-way, no way to resume without `/down` first.

**Sources:** SR up#4, SR up#7

### 4.5 Relative paths — working directory assumption is implicit

All paths are relative but the required working directory is never stated.

**Sources:** SR up#5

### 4.6 Pre-existing directory blocks `git clone`

If `workspace/{owner}/{repo}` already exists (manual clone, failed cleanup), `git clone` fails with no recovery path.

**Sources:** SR up#6

### 4.7 Minor `/up` issues

| Issue | Source |
|-------|--------|
| No `.git` suffix stripping from clone URLs | SR up#8 |
| No validation of parsed owner/repo against GitHub | SR up#9 |
| Wiki clone failure not reflected in config | SR up#10 |
| "One or two AskUserQuestion calls" phrasing misleading | SR up#11 |
| No `--depth 1` shallow clone for read-only source repo | SR up#12 |
| Clone URL passed to shell without input validation | SR up#13 |

---

## 5. `/down` — Safety & Path Validation

**Severity: HIGH**

### 5.1 `rm -rf` on unvalidated relative paths

Paths from YAML config are passed directly to `rm -rf`. A corrupted config with `sourceDir: "/"` would be catastrophic. No guard ensures paths are within `workspace/`.

**Sources:** SR down#1, SR down#2, SR down#3

### 5.2 `git log @{u}..HEAD` fails without upstream tracking

Fatal error when no upstream tracking branch exists.

**Sources:** SR down#4

### 5.3 No handling for broken workspaces

Missing or corrupted config files, partially-deleted workspaces — no recovery path.

**Sources:** SR down#5

### 5.4 Partial removal on failure leaves half-deleted workspace

No atomic cleanup — if deletion fails partway, the workspace is in an inconsistent state.

**Sources:** SR down#8

### 5.5 Windows file locking

Open editors or search indexers will cause `rm -rf` to fail silently on Windows.

**Sources:** SR down#9

### 5.6 Minor `/down` issues

| Issue | Source |
|-------|--------|
| "Abort" semantics unclear in `--all` mode | SR down#7 |
| `--all --force` silently destroys everything with zero confirmation | SR down#11 |
| Empty parent directories never cleaned up | SR down#12 |
| No `--dry-run` flag | SR down#13 |
| Double-prompt friction from two separate safety checks | SR down#14 |
| No `git fetch` before unpushed-commit check | SR down#15 |
| No network failure handling for git operations | SR down#16 |

---

## 6. Issue Filing Pipeline

**Severity: BUG (label parsing) / HIGH (design)**

### 6.1 `file-issue.sh` label parsing is broken

`grep -A1 '^labels:'` + `tail -1` picks the *next* line (`body:`), not the labels line. Every issue gets `--label body:` instead of `--label documentation`.

**Downstream:** `proofread-wiki` Phase 5 dedup queries `gh issue list --label documentation` — never finds existing issues, causing duplicates every run.

**Sources:** CR#1

### 6.2 `file-issue.sh` not covered by permission allowlist

`settings.json` allows `Bash(gh issue create:*)` but the actual filing goes through `bash .scripts/file-issue.sh`. No settings entry covers this, so every issue filing requires manual approval — potentially dozens per proofread run.

**Sources:** CR#5

### 6.3 No config path passed in multi-workspace setups

Phase 6 calls `bash .scripts/file-issue.sh "TITLE" <<'EOF'` with no config path argument. With multiple workspaces, the script's auto-detection fails.

**Sources:** CR#6, SR proofread-wiki#3

### 6.4 Template `recommendation` field conflict

Template marks `recommendation` as `required: true` but command instructions say "omit when not applicable."

**Sources:** SR proofread-wiki#7

### 6.5 Fallback file path uses `{sourceDir}` instead of `{repo}` slug

Failure fallback writes to `issues/{sourceDir}/...` (e.g., `issues/workspace/acme/Repo/...`) instead of a clean slug.

**Sources:** SR proofread-wiki#6

### 6.6 No rate-limit handling for `gh issue create`

GitHub's secondary rate limit (~80 req/min) could trigger on large proofread runs.

**Sources:** SR proofread-wiki#8

### 6.7 No upper bound on issue count

20 pages × 5 findings = 100 issues could flood the tracker.

**Sources:** SR proofread-wiki#9

### 6.8 Phase 1 sidebar issue bypasses Phase 5 dedup

Sidebar structural issues filed in Phase 1 skip the Phase 5 deduplication check.

**Sources:** SR proofread-wiki#13

---

## 7. Error Handling & Retry Logic

**Severity: MEDIUM**

### 7.1 No retry logic in most commands

`proofread-wiki` Phase 4 specifies retry-once, but no other phase or command has retry logic for failed subagents.

| Command | Missing retry |
|---------|--------------|
| `init-wiki` | Phase 3 writer agents |
| `proofread-wiki` | Phase 3 explorers, Phase 5 dedup |
| `refresh-wiki` | Phase 2 explorers, Phase 3 update agents |
| `revise-wiki` | Phase 2 fixers, Phase 3 closers |

**Sources:** SR init-wiki#9, SR proofread-wiki#5,#14, SR refresh-wiki#12, SR revise-wiki#12,#13

### 7.2 No handling for zero-result scenarios

- `revise-wiki`: No handling for zero open issues — should exit early.
- `refresh-wiki`: Missing `_Sidebar.md` → discovers zero pages, reports false "up to date."

**Sources:** SR revise-wiki#7, SR refresh-wiki#7

### 7.3 No validation of subagent output format

Explorer/analyzer agents can return malformed results. No schema validation before downstream consumption.

**Sources:** SR refresh-wiki#9

---

## 8. Guidance & Documentation References

**Severity: MEDIUM**

### 8.1 `revise-wiki` points agents to wrong guidance source

Tells fixer agents to "read `CLAUDE.md` for writing principles." CLAUDE.md contains workspace layout — the actual writing principles are in `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md`.

**Sources:** CR#9, SR revise-wiki#10

### 8.2 `revise-wiki` overrides user's configured tone

Hardcoded "reference-style not tutorial" tone overrides the user's `tone` field from workspace config.

**Sources:** SR revise-wiki#5

### 8.3 `revise-wiki` description says `docs` label, system uses `documentation`

Line 8 says "open `docs`-labeled GitHub issues" but everywhere else uses `documentation`. The actual `gh` command on line 35 is correct.

**Sources:** CR#8

### 8.4 `revise-wiki` leftover rename artifact

"fix-docs" name appears in Constraints section — should be "revise-wiki."

**Sources:** SR revise-wiki#18

### 8.5 `init-wiki` duplicates writing principles inline

Writing principles stated both inline and in `editorial-guidance.md` — dual source of truth.

**Sources:** SR init-wiki#13

### 8.6 `init-wiki` "kebab-case" terminology is wrong

Example `Getting-Started.md` is Title-Case-Hyphenated, not kebab-case.

**Sources:** SR init-wiki#11

---

## 9. Per-Command Edge Cases

**Severity: MEDIUM**

### 9.1 `refresh-wiki` — `HEAD~50` fails on small repos

`git diff --name-only HEAD~50..HEAD` errors if the repo has fewer than 50 commits.

**Sources:** CR#11, SR refresh-wiki#6

### 9.2 `refresh-wiki` — source-to-wiki mapping underspecified

The core Phase 1 mapping logic (which source files affect which wiki pages) relies on vague heuristics. This is the weakest link in the design.

**Sources:** SR refresh-wiki#3, SR refresh-wiki#4

### 9.3 `refresh-wiki` — no dedup of wiki pages across tuples

Multiple explorer agents could receive the same wiki page, causing concurrent edit race conditions at the orchestrator.

**Sources:** SR refresh-wiki#8

### 9.4 `refresh-wiki` — deleted source files passed to explorers

Explorers can't read deleted files but are told to analyze them.

**Sources:** SR refresh-wiki#14

### 9.5 `revise-wiki` — issues referencing deleted/renamed wiki pages

No handling when an issue references a page that no longer exists.

**Sources:** SR revise-wiki#8

### 9.6 `revise-wiki` — issue body parsing format assumed but never specified

Fixer agents parse `### Label` blocks from issue bodies, but the format is an implicit assumption.

**Sources:** SR revise-wiki#9

### 9.7 `revise-wiki` — source file paths not prefixed with `{sourceDir}/`

Source file paths from issues may not resolve because they lack the workspace path prefix.

**Sources:** SR revise-wiki#11

### 9.8 `revise-wiki` — shell injection risk in `--body` argument

Comment body constructed from issue-derived text passed to Bash without sanitization.

**Sources:** SR revise-wiki#14

### 9.9 `init-wiki` — `TaskOutput` missing from `allowed-tools`

Command uses `TaskOutput` in its instructions but doesn't list it in `allowed-tools`.

**Sources:** SR cross-cutting (TaskOutput), SR init-wiki#1

### 9.10 `init-wiki` — `Edit` listed in `allowed-tools` but never used

Unnecessary tool in the allow list.

**Sources:** SR init-wiki#12

### 9.11 `init-wiki` — `grep -v '^\.'` too broad

Intended to exclude `.git` but excludes all dotfiles.

**Sources:** SR init-wiki#5

### 9.12 `init-wiki` — sidebar wiki link format ambiguous

`[[Page Title|Page-Filename]]` may include `.md` extension, breaking links.

**Sources:** SR init-wiki#8

### 9.13 `init-wiki` — orchestrator does content authoring (sidebar)

Violates the coordinator-only role pattern — orchestrator writes the sidebar itself.

**Sources:** SR init-wiki#10

### 9.14 `proofread-wiki` — `--pass` flag parsing underspecified

No spec for `--pass=structural` vs `--pass structural`, case sensitivity.

**Sources:** SR proofread-wiki#15

### 9.15 `proofread-wiki` — no cleanup of stale `.proofread/` cache

Previous run's findings are picked up by the next run.

**Sources:** SR proofread-wiki#16

### 9.16 `proofread-wiki` — Phase 1 sidebar issue filed "using Phase 6 process" before Phase 6 exists

Circular reference in the instructions.

**Sources:** SR proofread-wiki#17

### 9.17 `proofread-wiki` — missing `_Sidebar.md` handling

No check for whether the sidebar exists before trying to review it.

**Sources:** SR proofread-wiki#10

### 9.18 `proofread-wiki` — template field mismatch

Instructions say "match field ids" but example uses label values.

**Sources:** SR proofread-wiki#11, SR proofread-wiki#12

### 9.19 `save` — ambiguous commit message guidance

No guidance on length, style, or cutoff for many-file changes.

**Sources:** SR save#6

### 9.20 `save` — `git add -A` stages temp files/artifacts

Stages everything including potential temporary files.

**Sources:** SR save#12

---

## 10. Housekeeping

**Severity: LOW**

### 10.1 `.proofread/` and `issues/` not in `.gitignore`

Both generated directories would be tracked if created.

**Sources:** CR#7, SR proofread-wiki#21

### 10.2 No `--depth 1` shallow clone for read-only source repos

Source repos are read-only reference — full clone wastes time and disk.

**Sources:** SR up#12

### 10.3 No reminder to run `/save` after `revise-wiki` edits

User could forget to push the changes.

**Sources:** SR revise-wiki#15

### 10.4 `--limit 100` silently truncates large issue sets in `revise-wiki`

**Sources:** SR revise-wiki#16

### 10.5 No instruction to read `{sourceDir}/CLAUDE.md` for project conventions in `revise-wiki`

**Sources:** SR revise-wiki#17

### 10.6 `refresh-wiki` — no signal when source changes imply a new wiki page is needed

**Sources:** SR refresh-wiki#13

### 10.7 `refresh-wiki` — explorer agents use `model: sonnet` while all other commands use `model: opus`

Inconsistent model selection.

**Sources:** SR refresh-wiki#16

### 10.8 `refresh-wiki` — 50-commit lookback hardcoded and not configurable

**Sources:** SR refresh-wiki#19

### 10.9 `refresh-wiki` — no incremental refresh tracking

Re-examines same commits on next run.

**Sources:** SR refresh-wiki#22

### 10.10 Source repo READONLY enforced only by natural language

No structural guard against accidental source repo mutation.

**Sources:** SR refresh-wiki#20, SR save#8

### 10.11 Various save command minor issues

| Issue | Source |
|-------|--------|
| No confirmation step between diff and commit/push | SR save#9 |
| No handling for missing wiki dir or non-git `{wikiDir}` | SR save#10 |
| "Confirm push succeeded" doesn't specify how | SR save#11 |
| No handling for detached HEAD | SR save#13 |
| No credential/secret check before staging | SR save#14 |
| "Nothing to save" error diverges from convention | SR save#7 |

### 10.12 Various revise-wiki minor issues

| Issue | Source |
|-------|--------|
| Ambiguous whether `-plan` combines with issue-number filters | SR revise-wiki#19 |
| Haiku model for close/comment agents may struggle | SR revise-wiki#20 |
| Source file reads not sandboxed to `{sourceDir}/` | SR revise-wiki#21 |
| No dedup of effort across runs | SR revise-wiki#22 |

### 10.13 Various init-wiki minor issues

| Issue | Source |
|-------|--------|
| Phase 2 planning agent blocking/background not specified | SR init-wiki#6 |
| No guidance for large repos or token limits in Phase 1 | SR init-wiki#7 |
| No idempotency or partial-failure recovery | SR init-wiki#14 |
| `subagent_type: Explore` may not be recognized | SR init-wiki#4 |

### 10.14 Various proofread-wiki minor issues

| Issue | Source |
|-------|--------|
| Background vs blocking agent terminology ambiguous (Phase 5) | SR proofread-wiki#18 |
| "Two at a time" parallelism pattern underspecified | SR proofread-wiki#19 |
| No timeout guidance for Task agents | SR proofread-wiki#20 |
| Issue title injection risk (low — generated by Claude) | SR proofread-wiki#22 |

---

## Summary

| # | Concept | Severity | Issue Count | Commands Affected |
|---|---------|----------|-------------|-------------------|
| 1 | Subagent permission model | CRITICAL | 3 | init-wiki, proofread-wiki, refresh-wiki, revise-wiki |
| 2 | Workspace selection | HIGH | 2 | all except /up |
| 3 | Git workflow gaps | HIGH | 5 | refresh-wiki, revise-wiki, save |
| 4 | `/up` ordering & atomicity | HIGH | 7+ | up |
| 5 | `/down` safety & validation | HIGH | 6+ | down |
| 6 | Issue filing pipeline | BUG/HIGH | 8 | proofread-wiki, file-issue.sh |
| 7 | Error handling & retry | MEDIUM | 3 | all swarm commands |
| 8 | Guidance & docs references | MEDIUM | 6 | revise-wiki, init-wiki |
| 9 | Per-command edge cases | MEDIUM | 20 | various |
| 10 | Housekeeping | LOW | 14+ | various |
