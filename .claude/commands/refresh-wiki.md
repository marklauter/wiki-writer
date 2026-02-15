---
name: refresh-wiki
description: Sync wiki pages with source code changes. Uses parallel background agents to minimize main context usage.
model: sonnet
allowed-tools: Bash, Read, Grep, Glob, Task, TodoWrite, TaskOutput
---

Sync wiki documentation with recent source code changes using a two-phase agent swarm. You coordinate — the agents do the research and editing.

Writing principles: `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md`.

## Phase 0: Select workspace and load config

Follow the **Workspace selection** procedure in `CLAUDE.md`:

1. List config files matching `workspace/config/*/*/workspace.config.yml`.
2. If `$ARGUMENTS` contains a token matching a workspace (`owner/repo` or just `repo`), select it and remove the token from `$ARGUMENTS`.
3. If exactly one workspace exists and no token matched, auto-select it.
4. If multiple workspaces exist and no token matched, prompt the user to pick one.
5. If no workspaces exist, tell the user to run `/up` first and stop.
6. Read the selected config file to get `repo`, `sourceDir`, `wikiDir`, `audience`, and `tone`.

## Inputs

- `$ARGUMENTS`: optional flags.
  - `-plan` — run Phases 1-2 (identify changes, explore), display the plan, but don't edit any files. Stop after Phase 2.
  - (no arguments) — full sync: identify, explore, update, summarize.

## Phase 1: Identify changes

1. Read `{wikiDir}/_Sidebar.md` to discover all wiki pages. Build a map of page names to their topic areas based on sidebar organization.
2. Run `git -C {sourceDir} log --oneline -50` to see recent commits.
3. Run `git -C {sourceDir} diff --name-only HEAD~50..HEAD` to get all files changed across those commits.
4. Group changed files by directory/module. For each group, match to the wiki page(s) whose topic area covers that part of the codebase. Use the sidebar structure and page names to guide the mapping — a change to `src/auth/` likely maps to an auth-related wiki page.
5. Discard groups that only touch non-behavioral files (CI configs, `.gitignore`, `README.md`, test fixtures) unless a wiki page specifically documents those topics.

Build a list of `(wiki-page, changed-source-files)` tuples. If a wiki page can't be mapped to any changed files, exclude it — it doesn't need a refresh.

If no tuples remain, report that the wiki appears up to date and stop.

## Phase 2: Explorer swarm (background agents)

For each `(wiki-page, changed-source-files)` tuple, launch a **background** Task agent (`subagent_type: Explore`, `model: sonnet`) that:

1. Reads the changed source files for that page's feature area.
2. Reads the corresponding wiki page in `{wikiDir}/`.
3. Compares them and produces a structured verdict in this exact format:

```
# {wiki page filename}

## Verdict: UP_TO_DATE | STALE

## Changed source files
- {path1}
- {path2}

## Diagnosis
{Only if STALE. Describe specifically what the wiki gets wrong or omits relative to the current source code. Reference specific sections of the wiki page and specific source file locations.}

## Correct content
{Only if STALE. Describe what the wiki should say instead, based on the source code. Be specific enough that an editor can make the change without re-reading the source.}
```

### Agent prompt

Include in each agent's prompt: the wiki page path, the list of changed source files to read, the `{sourceDir}/` base path, the verdict format above, and instructions to read the source files before the wiki page so the agent knows what's current before evaluating the docs.

Launch all explorer agents **in parallel** using `run_in_background: true`. Collect results with `TaskOutput` (blocking).

### Dry run (`-plan`)

If `-plan` was specified, display the results and stop. Use this output format:

```
## Refresh plan

### Pages to check
| Wiki page | Changed source files |
|-----------|---------------------|
| {page} | {file1}, {file2} |

### Explorer verdicts
| Wiki page | Verdict | Diagnosis (if stale) |
|-----------|---------|---------------------|
| {page} | UP_TO_DATE or STALE | {brief summary} |

### Proposed updates
{For each STALE page: the page name, what's wrong, and what the correct content should be.}
```

Stop here. Do not proceed to Phase 3.

## Phase 3: Update swarm (parallel agents)

For each page the explorers marked `STALE`, launch a Task agent (`subagent_type: general-purpose`, `model: opus`) to update that wiki page.

### Agent prompt

Pass to each update agent:

- The wiki page path to edit
- The explorer's full diagnosis and correct content description
- The changed source file paths to read for verification
- The `{sourceDir}/` base path
- The `audience` and `tone` values from the workspace config
- Instruction to read `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md` for writing principles before editing
- Instruction to read `{sourceDir}/CLAUDE.md` if it exists for project-specific conventions
- Instruction to read the wiki page before editing — use the Edit tool, not Write, to make targeted changes
- Instruction to preserve the page's existing structure unless the diagnosis specifically calls for reorganization
- Instruction to respect the configured `audience` and `tone` when writing
- Instruction to read the source files cited in the diagnosis to verify accuracy before editing

Launch all update agents **in parallel** using `run_in_background: true`. Collect results with `TaskOutput` (blocking).

## Phase 4: Summary

After all update agents complete, output:

| Wiki page | Status | What changed |
|-----------|--------|-------------|
| {page} | `UP_TO_DATE` | — |
| {page} | `UPDATED` | {brief description of what was changed} |

## Constraints

- **Edit wiki files only.** Never modify source code files.
- **Targeted edits.** Use the Edit tool for surgical changes. Don't rewrite entire pages unless the diagnosis specifically requires it.
- **Preserve voice.** Match the existing page's tone and style. Don't introduce a different writing voice.
- **Verify before editing.** Update agents must read the source files cited in the diagnosis before editing the wiki. If the source code agrees with the wiki (not the diagnosis), skip the update.
- **No new pages.** This command syncs existing pages. It does not create new wiki pages.
