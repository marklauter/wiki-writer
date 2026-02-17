# Remediation Plan v2

Sequenced fix plan for all issues in `refactor-issues/fusion.md`.
Incorporates DDD-inspired domain architecture: explicit markdown protocols at every agent boundary, domain knowledge in guidance files organized by concern, and custom agents (`.claude/agents/`) with well-defined roles.

**Principles:**

- Each wave contains only tasks independent of each other → parallel Opus agents.
- Agents own their domain: writers write, explorers explore, reviewers review. Orchestrators only coordinate.
- Every agent boundary has an explicit markdown protocol defining input and output.
- Domain knowledge lives in guidance files, not inline in commands.
- Writing principles have a single source of truth (`editorial/`), not duplicated inline.

---

## Script Inventory (pre-existing)

The following deterministic scripts already exist under `.scripts/`. They extract bash-level operations that were previously inlined in commands. Wave 1 and Wave 3 tasks reference these scripts instead of describing inline bash.

| Script | Purpose | Inputs | Key exit codes |
|--------|---------|--------|----------------|
| `resolve-workspace.sh` | Workspace selection — single source of truth | `[owner/repo \| repo]` | 0=resolved, 1=none found, 2=multiple (prompt user), 3=no match |
| `clone-workspace.sh` | Clone source+wiki repos, write config | `--url`, `--audience`, `--tone` | 0=success, 1=auth/args, 2=exists, 3=clone failed |
| `check-wiki-safety.sh` | Detect uncommitted/unpushed wiki changes | `<wiki-dir>` | 0=check done (read stdout for `UNCOMMITTED`/`UNPUSHED` booleans) |
| `remove-workspace.sh` | Delete repos, config, empty parent dirs | `<config-path>` | 0=removed, 1=config not found |
| `wiki-save.sh` | Stage, commit, push wiki changes | `<wiki-dir> <commit-message>` | 0=pushed, 1=no changes, 2=commit failed, 3=push failed |
| `list-source-changes.sh` | Git log + diff for recent source changes | `<source-dir> [commit-count]` | 0=success, 1=not a git repo |
| `fetch-docs-issues.sh` | Fetch open `documentation`-labeled issues | `[config-path] [--limit N] [--fields F]` | 0=JSON on stdout, 1=config/gh error |
| `close-issue.sh` | Close issue with comment, or comment-only | `<issue#> [--comment TEXT] [--skip TEXT]` | 0=success, 1=error |
| `file-issue.sh` | File a GitHub issue from template fields | `<title> [config-path]` (reads stdin) | 0=created, 1=error |

**Calling convention:** All commands invoke scripts via `bash .scripts/<name>.sh <args>`. Scripts auto-detect workspace config when not explicitly passed. `resolve-workspace.sh` outputs eval-able variables: `eval "$(bash .scripts/resolve-workspace.sh $ARGUMENTS)"`.

---

## Wave 0 — Domain Architecture

**Goal:** Create the protocol files, operations guidance, and folder structure that all subsequent waves reference. No command files are modified in this wave.
**Parallelism:** 3 independent tasks, all run concurrently.

### Task 0A: Create protocol files

Create `.claude/guidance/protocols/` with 7 protocol files. Each follows a consistent structure: Purpose, Producer, Consumer, Required fields, Output format, Validation rules.

**Protocols:**

1. **`source-analysis.md`** — Explorer output when analyzing source code.
   - Producers: `wiki-explorer` (init-wiki Phase 1, proofread-wiki Phase 3, refresh-wiki Phase 1)
   - Consumers: init-wiki planner, proofread-wiki reviewers
   - Required fields: `area_name`, `file_paths[]`, `key_types[]`, `public_api_summary`, `architectural_notes`

2. **`page-plan.md`** — Wiki page plan for new content.
   - Producer: init-wiki Phase 2 planner
   - Consumer: init-wiki Phase 3 writers
   - Required fields: `page_title`, `filename`, `purpose`, `sections[]`, `source_files[]`, `audience_notes`

3. **`page-content.md`** — Structure guide for new wiki pages.
   - Used by: `wiki-writer` (init-wiki Phase 3)
   - Defines: required page structure (title, opening sentence, sections, code examples). Writer follows this when creating pages via `Write` and returns a confirmation (filename, title, summary).
   - Required confirmation fields: `filename`, `title`, `summary`

4. **`review-finding.md`** — Proofreading finding.
   - Producer: `wiki-reviewer` (proofread-wiki Phase 4)
   - Consumer: orchestrator → `issue-body.md` → GitHub issue
   - Required fields: `page`, `location`, `severity`, `category`, `finding`, `recommendation`, `source_evidence`

5. **`drift-assessment.md`** — Source change impact on wiki.
   - Producer: `wiki-explorer` (refresh-wiki Phase 2)
   - Consumer: refresh-wiki Phase 3 editor agents
   - Required fields: `wiki_page`, `source_files[]`, `changes[]`, `impact_description`, `correct_content`

6. **`edit-instruction.md`** — Change report format. Shared across contexts.
   - Producers: `wiki-writer` (refresh-wiki, revise-wiki edit mode)
   - Consumer: orchestrator (for logging, error checking, and downstream decisions like issue closing)
   - Writer applies edits directly via `Edit`, then returns a report of what changed.
   - Required report fields: `file`, `old_string`, `new_string`, `rationale`

7. **`issue-body.md`** — Published Language between proofread-wiki and revise-wiki.
   - Producer: proofread-wiki (filing via `file-issue.sh`)
   - Consumer: revise-wiki (parsing)
   - Defines: issue title format, body sections (`Page`, `Location`, `Category`, `Finding`, `Recommendation`, `Source evidence`)

**Files:** `.claude/guidance/protocols/` (7 new files)

### Task 0B: Create operations guidance

Create `.claude/guidance/operations/git-workflow.md`:

- When to pull: `--ff-only` before analysis, `--rebase` before push.
- Conflict handling: show conflict and stop, tell user how to resolve.
- Push failure handling: check exit code, report auth / network / non-fast-forward with actionable message.
- Upstream tracking check: `git log @{u}..HEAD` with error handling when no upstream exists.
- Source repo is always read-only — never stage, commit, or push to it.

**Files:** `.claude/guidance/operations/git-workflow.md`

### Task 0C: Reorganize guidance and update agents

1. Move existing guidance into domain subfolders:
   - `guidance/editorial-guidance.md` → `guidance/editorial/editorial-guidance.md`
   - `guidance/wiki-instructions.md` → `guidance/editorial/wiki-instructions.md`

2. Update `CLAUDE.md` references to point to new paths.

3. Update `.claude/agents/` to reference protocols and guidance:

   **`wiki-explorer.md`:**
   - Add: "Return structured reports following `.claude/guidance/protocols/source-analysis.md` or `.claude/guidance/protocols/drift-assessment.md` as specified by your task prompt."
   - No other changes — agent is already correctly scoped.

   **`wiki-writer.md`:**
   - Remove inline writing principles (lines 12–21).
   - Add: "Read `.claude/guidance/editorial/editorial-guidance.md` and `.claude/guidance/editorial/wiki-instructions.md` for writing principles."
   - Add: "For new pages, use `Write` to create the file, following `.claude/guidance/protocols/page-content.md` for structure. For edits to existing pages, use `Edit` to apply changes directly. In both cases, return a confirmation report per `.claude/guidance/protocols/edit-instruction.md`."
   - The writer owns the mutation — it reads source, drafts content, and writes/edits the file itself.

   **`wiki-reviewer.md`:**
   - Add: "Return findings following `.claude/guidance/protocols/review-finding.md`."
   - Keep existing review checklist (it's agent-specific context, not duplicated guidance).

**Files:** `.claude/guidance/editorial/` (2 moved files), `.claude/agents/` (3 updated files), `CLAUDE.md`

---

## Wave 1 — Foundation Fixes

**Goal:** Fix standalone bugs and structural issues that don't touch swarm command internals.
**Parallelism:** Two sequential batches (shared file conflicts — see execution summary).
**Depends on:** Wave 0 (guidance paths are stable, so reference updates are correct).

### Task 1A: Workspace selection — replace inline steps with script call

**Fixes:** Fusion §2.1, §2.2

Replace all inline workspace selection steps (in init-wiki, proofread-wiki, refresh-wiki, revise-wiki, save, down) with a call to `resolve-workspace.sh`:

```bash
eval "$(bash .scripts/resolve-workspace.sh $ARGUMENTS)"
```

Each command handles exit codes:
- Exit 1 → tell user to run `/up` first, **stop**.
- Exit 2 → list workspaces (already printed to stderr by script), prompt user to choose, re-run with selection.
- Exit 3 → report no match, **stop**.
- Exit 0 → variables `REPO`, `SOURCE_DIR`, `WIKI_DIR`, `AUDIENCE`, `TONE`, `OWNER`, `REPO_NAME` are set.

Remove all divergent inline workspace selection logic. The script implements the canonical algorithm from CLAUDE.md (including the "no configs → stop" check).

**Files:** `.claude/commands/init-wiki.md`, `.claude/commands/proofread-wiki.md`, `.claude/commands/refresh-wiki.md`, `.claude/commands/revise-wiki.md`, `.claude/commands/save.md`, `.claude/commands/down.md`

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

### Task 1D: `/up` — replace inline cloning with `clone-workspace.sh`

**Fixes:** Fusion §4.1, §4.2, §4.3, §4.4, §4.5, §4.6

Rewrite `/up` to a two-step flow — LLM interview + deterministic script:

1. **Interview** (LLM): Collect repo URL, audience, and tone from user. This is the only step requiring judgment.
2. **Clone + configure** (script): Call `clone-workspace.sh`:
   ```bash
   bash .scripts/clone-workspace.sh --url "$URL" --audience "$AUDIENCE" --tone "$TONE"
   ```
   Handle exit codes:
   - Exit 1 → auth failure or bad URL, show error, **stop**.
   - Exit 2 → workspace already exists, ask user to run `/down` first or confirm overwrite.
   - Exit 3 → source clone failed, show error, **stop**.
   - Exit 0 → parse JSON output for `sourceDir`, `wikiDir`, `wikiCloned`.
3. **Post-setup** (LLM): If `wikiCloned` is false, note that the wiki repo doesn't exist yet. Read `{sourceDir}/CLAUDE.md` if present. Confirm workspace is ready.

The script handles URL parsing, `.git` suffix stripping, directory creation, both clones, and config writing atomically (config is written only after successful source clone).

**Files:** `.claude/commands/up.md`

### Task 1E: `settings.json` — audit and fill permission gaps

**Fixes:** Fusion §6.2 (partially), plus gaps found in review

Now that most bash operations are in `.scripts/`, the primary permission needed is the blanket script runner. Audit every Bash invocation across all commands and ensure `settings.json` covers them:

**Script invocations** (covers all 9 scripts):
- `Bash(bash .scripts/*:*)` — all commands invoke scripts this way

**Remaining inline git/gh commands** (not yet in scripts):
- `Bash(git -C *:*)` — pull --ff-only / pull --rebase (used by refresh-wiki, revise-wiki, save)
- `Bash(git clone:*)` — only if commands ever clone outside `clone-workspace.sh`
- `Bash(gh auth status:*)` — used by `/up` pre-check
- `Bash(gh repo view:*)` — used by `/up` validation (Wave 5)

**Previously identified gaps still needed:**
- `Bash(mkdir:*)`, `Bash(rm:*)`, `Bash(rmdir:*)` — used by scripts, but scripts are invoked via `bash .scripts/*` so these run inside the script process (no separate permission needed unless commands call them directly)

Verify that the existing `Bash(bash .scripts/*:*)` pattern is sufficient by tracing every Bash call in every command after Wave 2 rewrites. Add individual permissions only for inline git/gh calls that remain.

**Files:** `.claude/settings.json`

### Task 1F: `/down` — wire up safety check and removal scripts

**Fixes:** Fusion §5.1, §5.2, §5.3, §5.4, §5.5

Rewrite `/down` to use `check-wiki-safety.sh` + `remove-workspace.sh`:

1. **Resolve workspace** (script): `eval "$(bash .scripts/resolve-workspace.sh $ARGUMENTS)"` (from Task 1A).
2. **Safety check** (script): `bash .scripts/check-wiki-safety.sh "$WIKI_DIR"`.
   - If `UNCOMMITTED=true` or `UNPUSHED=true` → show details, prompt user to confirm or abort.
   - The script already handles missing upstream gracefully (`git log @{u}..HEAD` failure → `UNPUSHED=false`).
3. **Path validation** (LLM, inline): Before calling remove, assert `SOURCE_DIR` and `WIKI_DIR` start with `workspace/` and match `workspace/{owner}/{repo}[.wiki]`. If not → refuse and show the suspicious path.
4. **Remove** (script): `bash .scripts/remove-workspace.sh "$CONFIG_PATH"`.
   - The script handles repo deletion, config removal, and empty parent directory cleanup.

**Remaining inline logic:** Path validation (step 3) stays in the command because it's a safety gate that should be visible in the prompt, not hidden in a script.

**Files:** `.claude/commands/down.md`

---

## Wave 2 — Subagent Architecture Restructuring

**Goal:** Fix the CRITICAL subagent permission issue and connect commands to the protocol/agent layer.
**Parallelism:** 4 independent tasks (one per swarm command), all run concurrently.
**Depends on:** Wave 0 (protocols exist) + Wave 1 (workspace selection and settings are stable).

Each task follows the same pattern:

- Commands reference **custom agents** (`.claude/agents/wiki-explorer`, `wiki-writer`, `wiki-reviewer`) instead of inline `subagent_type` declarations.
- **Agents own their domain.** Writers read source, read guidance, and apply edits directly using their own `Write`/`Edit` tools. Explorers read and analyze. Reviewers read and assess. Each agent's frontmatter grants exactly the tools it needs.
- **Orchestrators only coordinate** — dispatch agents, collect confirmations, handle errors, sequence phases. They never call `Edit` or `Write` on wiki content themselves.

Custom agents (`.claude/agents/`) declare explicit `tools:` grants in their frontmatter. `wiki-writer` has `Write, Edit`; `wiki-explorer` and `wiki-reviewer` have `disallowedTools: Write, Edit`. This is the structural enforcement of the read/write boundary.

### Task 2A: `init-wiki` — use wiki-explorer and wiki-writer agents

**Fixes:** Fusion §1.1 (init-wiki), §9.9, §9.10, §9.13

Restructure to reference custom agents and protocols:

- Phase 1 (explore): Launch `wiki-explorer` agents. Each returns a **Source Analysis** (protocol: `source-analysis.md`).
- Phase 2 (plan): Launch a `wiki-explorer` agent (or `general-purpose`). Returns a **Page Plan** per page (protocol: `page-plan.md`).
- Phase 3 (write): Launch `wiki-writer` agents, each given a page plan + source file paths. Each writer creates its page directly via `Write` (following `page-content.md` structure) and returns a confirmation. Orchestrator collects confirmations via `TaskOutput`.
- Sidebar: Launch a `wiki-writer` agent for `_Sidebar.md` + `Home.md` (removes the "orchestrator does content authoring" issue).

Also fix:
- Add `TaskOutput` to `allowed-tools`.
- Remove `Edit` and `Write` from `allowed-tools` (orchestrator doesn't need them — writers handle mutations).

**Files:** `.claude/commands/init-wiki.md`

### Task 2B: `proofread-wiki` — use wiki-explorer and wiki-reviewer agents

**Fixes:** Fusion §1.1 (proofread-wiki), §1.2, §6.2

Restructure to reference custom agents and protocols:

- Phase 3 (source exploration): Launch `wiki-explorer` agents. Each returns a **Source Analysis** (protocol: `source-analysis.md`). Orchestrator writes to `.proofread/{repo}/source/`.
- Phase 4 (review): Launch `wiki-reviewer` agents. Each returns **Review Findings** (protocol: `review-finding.md`). Orchestrator writes to `.proofread/{repo}/findings/`.
- Phase 5 (dedup): Orchestrator calls `bash .scripts/fetch-docs-issues.sh` to get existing open issues. Filters findings against them to avoid duplicates.
- Phase 6 (file issues): Orchestrator calls `bash .scripts/file-issue.sh` directly (covered by `Bash(bash .scripts/*:*)` added in Task 1E). Issue body conforms to `issue-body.md` protocol.

**Files:** `.claude/commands/proofread-wiki.md`

### Task 2C: `refresh-wiki` — use wiki-explorer and wiki-writer agents

**Fixes:** Fusion §1.1 (refresh-wiki)

Restructure to reference custom agents and protocols:

- Phase 2 (explore): Launch `wiki-explorer` agents. Each returns a **Drift Assessment** (protocol: `drift-assessment.md`). Orchestrator collects via `TaskOutput`.
- Phase 3 (update): Launch `wiki-writer` agents (edit mode), each given one wiki page + the drift assessment + editorial guidance references. Each writer reads the page, applies edits directly via `Edit`, and returns a **Change Report** (protocol: `edit-instruction.md`). Orchestrator collects confirmations via `TaskOutput`.

Also fix:
- Add `TaskOutput` to `allowed-tools` in the frontmatter.
- Remove `Edit` from `allowed-tools` if present (orchestrator doesn't edit — writers do).

**Files:** `.claude/commands/refresh-wiki.md`

### Task 2D: `revise-wiki` — use wiki-writer agents, orchestrator closes issues

**Fixes:** Fusion §1.1 (revise-wiki), §1.3

Restructure to reference custom agents and protocols:

- Phase 1 (fetch): Orchestrator calls `bash .scripts/fetch-docs-issues.sh` to get open documentation issues as JSON.
- Phase 2 (fix): Launch `wiki-writer` agents (edit mode). Each given an issue (parsed per `issue-body.md` protocol) + the wiki page path + source file paths + editorial guidance references. Each writer reads the page, applies edits directly via `Edit`, and returns a **Change Report** (protocol: `edit-instruction.md`). Orchestrator collects confirmations via `TaskOutput`.
- Phase 3 (close): Orchestrator calls `bash .scripts/close-issue.sh <issue#> --comment "<summary>"` for each fixed issue (or `--skip "<reason>"` for skipped ones). Uses the change reports from Phase 2 to construct the closing comment.

**Files:** `.claude/commands/revise-wiki.md`

---

## Wave 3 — Git Workflow

**Goal:** Add proper git pull/push handling. Commands reference `operations/git-workflow.md` for patterns.
**Parallelism:** 3 independent tasks.
**Depends on:** Wave 2 (tasks 3A and 3B share files with Wave 2 tasks).

### Task 3A: `refresh-wiki` — pull before analysis, use `list-source-changes.sh`

**Fixes:** Fusion §3.1 (refresh-wiki), §9.1

Add to Phase 0 (after workspace selection), referencing `operations/git-workflow.md`:
1. `git -C {sourceDir} pull --ff-only` (source repo — get latest).
2. `git -C {wikiDir} pull --ff-only` (wiki repo — get latest before editing).

Replace inline git log/diff with script call:
```bash
bash .scripts/list-source-changes.sh "$SOURCE_DIR" 50
```
The script already handles the HEAD~N edge case — if the repo has fewer than N commits, it diffs against the root commit. Its output (`=== COMMITS ===` / `=== CHANGED FILES ===` sections) feeds directly into the explorer agent prompts.

**Remaining inline git:** Only the two `pull --ff-only` commands stay inline (the script doesn't handle pulls — that's a workflow concern, not a data-gathering operation).

**Files:** `.claude/commands/refresh-wiki.md`

### Task 3B: `revise-wiki` — pull before editing, push-then-close via scripts

**Fixes:** Fusion §3.1 (revise-wiki), §3.5

Add to Phase 0, referencing `operations/git-workflow.md`:
1. `git -C {wikiDir} pull --ff-only`

Replace the current Phase 3 (close issues immediately) with a push-then-close flow using scripts:

1. **Fetch issues** (script): `bash .scripts/fetch-docs-issues.sh "$CONFIG_PATH"` — returns JSON array of open issues.
2. **Fix** (agents): wiki-writer agents apply edits (from Wave 2).
3. **Save** (script): Generate commit message (LLM), then:
   ```bash
   bash .scripts/wiki-save.sh "$WIKI_DIR" "$COMMIT_MESSAGE"
   ```
   - Exit 1 → no changes, skip closing.
   - Exit 2/3 → commit or push failed, tell user to resolve manually, do NOT close any issues.
4. **Close** (script, only after push succeeds): For each fixed issue:
   ```bash
   bash .scripts/close-issue.sh <issue#> --comment "<summary of changes>"
   ```
   For skipped issues:
   ```bash
   bash .scripts/close-issue.sh <issue#> --skip "Skipped: <reason>"
   ```

This guarantees issues are only closed after edits are live. The LLM's only role in the push-close flow is generating the commit message and per-issue summaries.

**Files:** `.claude/commands/revise-wiki.md`

### Task 3C: `/save` — use safety check + wiki-save scripts

**Fixes:** Fusion §3.2, §3.3, §3.4

Rewrite `/save` flow using scripts, referencing `operations/git-workflow.md`:

1. **Resolve workspace** (script): `eval "$(bash .scripts/resolve-workspace.sh $ARGUMENTS)"` (from Task 1A).
2. **Check status** (script): `bash .scripts/check-wiki-safety.sh "$WIKI_DIR"`.
   - If `UNCOMMITTED=false` and `UNPUSHED=false` → "Nothing to save." **Stop.**
   - If `UNCOMMITTED=true` → show the uncommitted files list from script output.
   - If `UNPUSHED=true` → note the unpushed commits.
3. **Generate commit message** (LLM): Show `git -C {wikiDir} diff` to the LLM. Generate a concise commit message. This is the only step requiring judgment.
4. **Pull, commit, push** (script):
   - First: `git -C {wikiDir} pull --rebase` — if merge conflict, show the conflict and **stop**.
   - Then: `bash .scripts/wiki-save.sh "$WIKI_DIR" "$COMMIT_MESSAGE"`.
   - Exit 0 → report success.
   - Exit 1 → no changes (race condition — changes were resolved by pull). Report "Nothing to save."
   - Exit 2 → commit failed, show error.
   - Exit 3 → push failed, show error with actionable message (check auth, check remote).

**Remaining inline git:** `git -C {wikiDir} pull --rebase` stays inline because it must happen between status check and save, and conflict handling requires LLM judgment. `git -C {wikiDir} diff` stays inline because the LLM reads its output to generate the commit message.

**Files:** `.claude/commands/save.md`

---

## Wave 4 — Command Hardening

**Goal:** Fix remaining MEDIUM issues — error handling, edge cases, retry logic. Protocol references are already in place from Wave 2; this wave tightens how commands use them.
**Parallelism:** 4 independent tasks (one per swarm command).
**Depends on:** Waves 2–3 (command structure and git workflow are stable).

### Task 4A: `revise-wiki` — guidance, tone, edge cases, and retry

**Fixes:** Fusion §8.1, §8.2, §8.3, §8.4, §9.5, §9.6, §9.7, §9.8, §7.1 (revise-wiki)

1. Fixer agent prompt references `editorial/editorial-guidance.md` and `editorial/wiki-instructions.md` (not CLAUDE.md).
2. Remove hardcoded "reference-style" tone — pass `{tone}` from workspace config to agent prompt.
3. Fix description: `docs` → `documentation`.
4. Fix constraint name: `fix-docs` → `revise-wiki`.
5. Add early exit when zero issues found.
6. Issue body parsing now uses `issue-body.md` protocol (from Wave 2) — validate required sections present.
7. Prefix source file paths with `{sourceDir}/`.
8. Sanitize issue body text before passing to `close-issue.sh --comment` argument (quote properly or use a temp file if text contains shell metacharacters).
9. Add retry-once for failed fixer agents (§7.1).

**Files:** `.claude/commands/revise-wiki.md`

### Task 4B: `refresh-wiki` — mapping, dedup, edge cases, and retry

**Fixes:** Fusion §9.2, §9.3, §9.4, §7.1 (refresh-wiki), §7.3

1. Replace the vague source-to-wiki mapping with an explicit two-step process:
   a. Orchestrator reads `_Sidebar.md` to build the wiki page list.
   b. For each changed source file, orchestrator reads the first 20 lines of each wiki page looking for references to that source file (imports, class names, file paths). Build the mapping from concrete textual matches, not heuristics.
2. Deduplicate wiki pages across explorer tuples — ensure each wiki page appears in at most one tuple.
3. Filter out deleted source files before passing to explorers (check `git show HEAD:{file}` to confirm existence).
4. Add retry-once for failed explorer agents (consistent with proofread-wiki Phase 4).
5. Validate explorer output against `drift-assessment.md` protocol: require `wiki_page`, `source_files`, `correct_content` fields. Log and skip malformed results.

**Files:** `.claude/commands/refresh-wiki.md`

### Task 4C: `proofread-wiki` — edge cases and robustness

**Fixes:** Fusion §6.4, §6.5, §6.6, §6.7, §6.8, §7.1 (proofread-wiki), §9.14, §9.15, §9.16, §9.17, §9.18

1. Fix template `recommendation` field: make optional or remove `required: true`.
2. Add issue count cap (configurable, default 20) to prevent tracker flooding.
3. Route Phase 1 sidebar issues through Phase 5 dedup.
4. Specify `--pass` flag parsing: case-insensitive, accept both `--pass structural` and `--pass=structural`.
5. Clear `.proofread/{repo}/` at start of each run to avoid stale findings.
6. Fix Phase 1 circular reference — remove "using Phase 6 process" or move sidebar review to after Phase 6 is defined.
7. Add check for `_Sidebar.md` existence.
8. Align template field instructions with example.
9. Fix fallback file path: use `issues/{repo}/` instead of `issues/{sourceDir}/` (§6.5).
10. Add rate-limit awareness: if filing >20 issues, insert 1-second delays between `gh issue create` calls (§6.6).
11. Add retry-once for failed Phase 3 explorer agents (§7.1).

**Files:** `.claude/commands/proofread-wiki.md`, `.github/ISSUE_TEMPLATE/` (if template needs update)

### Task 4D: `init-wiki` — edge cases and cleanup

**Fixes:** Fusion §8.5, §8.6, §9.11, §9.12, §7.1 (init-wiki), §10.13 (subagent_type)

1. Inline writing principles already removed in Wave 0 (Task 0C updated `wiki-writer`). Verify no remnants in command file.
2. Fix terminology: "kebab-case" → "Title-Case-Hyphenated" (or just show the example without naming the convention).
3. Leave `grep -v '^\.'` as-is — excluding all dotfiles is likely intentional (dotfiles are config/metadata, not wiki-worthy content). Add a comment explaining the intent.
4. Clarify sidebar link format: no `.md` extension in `[[links]]`.
5. Verify agents use correct `subagent_type` or custom agent name for `wiki-explorer`.
6. Add retry-once for failed writer agents (§7.1).

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
- The two safety checks are already consolidated in `check-wiki-safety.sh` (single script call, single prompt). Verify the command uses a single prompt for both.
- Add `git fetch` before the safety check (so `check-wiki-safety.sh` sees up-to-date upstream state).
- Empty parent directory cleanup is already handled by `remove-workspace.sh`.

**Files:** `.claude/commands/up.md`, `.claude/commands/down.md`

### Task 5B: `revise-wiki` and `save` minor fixes

**Fixes:** Fusion §10.4, §10.5, §10.11, §10.12, §9.19, §9.20

`revise-wiki`:
- The `--limit 100` issue is resolved — `fetch-docs-issues.sh` defaults to 200. If a custom limit is needed, pass `--limit N` to the script.
- Add instruction to read `{sourceDir}/CLAUDE.md`.

`save`:
- Add commit message guidance (imperative mood, ≤72 chars first line, summarize if many files).
- The `git add -A` concern is resolved — `wiki-save.sh` handles staging. If selective staging is needed, update the script or add a `--files` flag.

**Files:** `.claude/commands/revise-wiki.md`, `.claude/commands/save.md`

### Task 5C: `refresh-wiki` and `proofread-wiki` minor fixes

**Fixes:** Fusion §10.6, §10.7, §10.8, §10.9, §10.14

`refresh-wiki`:
- Make commit lookback configurable via `$ARGUMENTS` — pass as second arg to `list-source-changes.sh` (default 50).
- Use consistent model for explorer agents (opus or document the sonnet choice).
- When source changes suggest a new page is needed, note it in the output.

`proofread-wiki`:
- Specify parallelism pattern more precisely (e.g., "batch N agents at a time").
- Add timeout guidance for Task agents.

**Files:** `.claude/commands/refresh-wiki.md`, `.claude/commands/proofread-wiki.md`

---

## Execution Summary

```
Wave 0 ─── 3 parallel Opus tasks ─── Domain architecture (protocols, guidance, agents)
  │
Wave 1 ─┬─ Batch 1 (3 parallel): 1A, 1B, 1D
         └─ Batch 2 (3 parallel): 1C, 1E, 1F
  │
Wave 2 ─── 4 parallel Opus tasks ─── Subagent architecture (CRITICAL)
  │
Wave 3 ─── 3 parallel Opus tasks ─── Git workflow
  │
Wave 4 ─── 4 parallel Opus tasks ─── Command hardening
  │
Wave 5 ─── 3 parallel Opus tasks ─── Polish (optional)
```

| Wave | Tasks | Parallel Agents | What's delivered |
|------|-------|-----------------|------------------|
| 0 | 0A–0C | 3 | 7 protocol files, operations guidance, reorganized editorial guidance, updated agents |
| 1 | 1A–1F | 3 + 3 (two batches) | Bug fixes, workspace selection, /up, /down, settings, .gitignore |
| 2 | 2A–2D | 4 | All 7 CRITICAL findings — commands wired to agents + protocols |
| 3 | 3A–3C | 3 | Git workflow (pull/push/conflict handling) |
| 4 | 4A–4D | 4 | Edge cases, error handling, retry logic, protocol validation |
| 5 | 5A–5C | 3 | Polish |
| **Total** | **23 tasks** | **max 4 concurrent** | |

### Domain architecture map

After Wave 2, the system looks like this:

```
Commands (orchestrators)              Agents                      Protocols
─────────────────────────            ──────                      ─────────
init-wiki ──────────────→ wiki-explorer ──→ source-analysis.md
                          wiki-writer  ──→ page-plan.md
                          wiki-writer  ──→ page-content.md

proofread-wiki ─────────→ wiki-explorer ──→ source-analysis.md
                          wiki-reviewer ──→ review-finding.md
                          file-issue.sh ──→ issue-body.md
                          fetch-docs-issues.sh (dedup)

refresh-wiki ───────────→ wiki-explorer ──→ drift-assessment.md
                          wiki-writer  ──→ edit-instruction.md
                          list-source-changes.sh (data gathering)

revise-wiki ────────────→ wiki-writer  ──→ edit-instruction.md
                          (issue input)←── issue-body.md
                          fetch-docs-issues.sh → wiki-save.sh → close-issue.sh

save ───────────────────→ check-wiki-safety.sh → wiki-save.sh
up ─────────────────────→ clone-workspace.sh
down ───────────────────→ check-wiki-safety.sh → remove-workspace.sh
```

All commands start with `resolve-workspace.sh` for workspace selection (omitted from diagram for clarity).

Shared guidance referenced by all agents:
- `editorial/editorial-guidance.md` — writing quality, tone, style
- `editorial/wiki-instructions.md` — wiki conventions, links, sidebar format
- `operations/git-workflow.md` — referenced by commands, not agents

### Known gaps

The following fusion items are intentionally deferred:

- §10.10 — Source repo READONLY enforced only by natural language. Structural enforcement would require a read-only mount or filesystem permissions, which is out of scope for prompt-level fixes. (Note: `wiki-explorer` already has `disallowedTools: Write, Edit` which provides structural enforcement for the explorer agent.)
- §7.3 — Full schema validation of subagent output. Task 4B adds field-presence checks for `refresh-wiki`; full validation across all commands is deferred — the protocol files themselves serve as the spec, and agents trained on them should conform.

### File Conflict Matrix

Each file is touched by at most one task per wave. Wave 1 uses two sequential batches to avoid conflicts on shared files.

| File | Wave 0 | Wave 1 | Wave 2 | Wave 3 | Wave 4 | Wave 5 |
|------|--------|--------|--------|--------|--------|--------|
| `protocols/*.md` | 0A | — | — | — | — | — |
| `operations/git-workflow.md` | 0B | — | — | — | — | — |
| `editorial/*.md` | 0C | — | — | — | — | — |
| `wiki-explorer.md` (agent) | 0C | — | — | — | — | — |
| `wiki-writer.md` (agent) | 0C | — | — | — | — | — |
| `wiki-reviewer.md` (agent) | 0C | — | — | — | — | — |
| `CLAUDE.md` | 0C | — | — | — | — | — |
| `init-wiki.md` | — | 1A | 2A | — | 4D | — |
| `proofread-wiki.md` | — | 1A→1C | 2B | — | 4C | 5C |
| `refresh-wiki.md` | — | 1A | 2C | 3A | 4B | 5C |
| `revise-wiki.md` | — | 1A | 2D | 3B | 4A | 5B |
| `save.md` | — | 1A | — | 3C | — | 5B |
| `up.md` | — | 1D | — | — | — | 5A |
| `down.md` | — | 1A→1F | — | — | — | 5A |
| `file-issue.sh` | — | 1C | — | — | — | — |
| `.gitignore` | — | 1B | — | — | — | — |
| `settings.json` | — | 1E | — | — | — | — |

Arrow notation (e.g., `1A→1C`) means these tasks run sequentially within the wave, not in parallel.

---

## Verification

After each wave, verify the changes before proceeding to the next.

### After Wave 0

- [ ] 7 protocol files exist in `.claude/guidance/protocols/`, each with Purpose, Producer, Consumer, Required fields, Output format sections.
- [ ] `operations/git-workflow.md` exists with pull, push, conflict, and upstream check patterns.
- [ ] `editorial/editorial-guidance.md` and `editorial/wiki-instructions.md` exist (moved from `guidance/`).
- [ ] Old paths (`guidance/editorial-guidance.md`, `guidance/wiki-instructions.md`) no longer exist.
- [ ] `CLAUDE.md` references updated to `editorial/` paths.
- [ ] `wiki-explorer.md`: references `source-analysis.md` and `drift-assessment.md` protocols.
- [ ] `wiki-writer.md`: inline writing principles removed, references `editorial/` guidance and `page-content.md` / `edit-instruction.md` protocols.
- [ ] `wiki-reviewer.md`: references `review-finding.md` protocol.

### After Wave 1

- [ ] All 6 command files call `bash .scripts/resolve-workspace.sh $ARGUMENTS` with exit code handling (1=no workspace, 2=prompt, 3=no match).
- [ ] `.gitignore` includes `.proofread/` and `issues/`.
- [ ] `file-issue.sh`: run `grep -A1 '^labels:' .github/ISSUE_TEMPLATE/wiki-docs.yml | head -1` and confirm it extracts `["documentation"]`.
- [ ] `up.md`: interview → `clone-workspace.sh` call → read source CLAUDE.md. No inline git clone, mkdir, or config writing.
- [ ] `down.md`: `check-wiki-safety.sh` → path validation → `remove-workspace.sh`. No inline `rm -rf` or `git log @{u}..HEAD`.
- [ ] `settings.json`: confirm `Bash(bash .scripts/*:*)` covers all script invocations. Confirm `Bash(git -C *:*)` covers remaining inline git commands.

### After Wave 2

- [ ] All four swarm commands reference custom agents (`wiki-explorer`, `wiki-writer`, `wiki-reviewer`) instead of inline `subagent_type` declarations.
- [ ] All four swarm commands specify which protocol each agent should follow in its task prompt.
- [ ] `wiki-writer` agents are instructed to apply edits directly (Write for new pages, Edit for existing). Orchestrator does NOT call Edit/Write on wiki content.
- [ ] Orchestrator collects confirmations/change reports via `TaskOutput`. No editorial judgment at orchestrator level.
- [ ] `init-wiki.md` frontmatter: `TaskOutput` present; `Edit` and `Write` removed from `allowed-tools`.
- [ ] `refresh-wiki.md` frontmatter: `TaskOutput` present; `Edit` removed from `allowed-tools`.

### After Wave 3

- [ ] `refresh-wiki.md`: `git pull --ff-only` in Phase 0, then `bash .scripts/list-source-changes.sh` (no inline `git log`/`git diff --name-only`).
- [ ] `revise-wiki.md`: `fetch-docs-issues.sh` for fetching → agents fix → `wiki-save.sh` for push → `close-issue.sh` for each issue. Confirm issues are NOT closed before push succeeds.
- [ ] `save.md`: `check-wiki-safety.sh` for status → LLM generates commit message → `pull --rebase` → `wiki-save.sh`. No inline `git status --porcelain` or `git log @{u}..HEAD`.
- [ ] All three commands reference `operations/git-workflow.md`.

### After Wave 4

- [ ] `revise-wiki.md`: fixer agents reference `editorial/` guidance, not `CLAUDE.md`. `{tone}` is used, not hardcoded.
- [ ] `refresh-wiki.md`: source-to-wiki mapping reads `_Sidebar.md` and scans page content. Explorer output validated against `drift-assessment.md` protocol.
- [ ] `proofread-wiki.md`: `.proofread/` cleared at start, issue cap exists, `_Sidebar.md` existence check present.
- [ ] `init-wiki.md`: no inline writing principles remain.

### After Wave 5

- [ ] `up.md`: `--depth 1` on source clone, `gh repo view` validation.
- [ ] `down.md`: single safety prompt, empty parent dir cleanup.
- [ ] Smoke test: run `/up` with a test repo, then `/init-wiki`, then `/save`, then `/down` — full lifecycle.
