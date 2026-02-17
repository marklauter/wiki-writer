# CLAUDE.md

Claude toolset for GitHub wiki management: creation, editorial review, sync, and issue tracking. Works with any GitHub project.

## Workspace

This repo is a reusable workspace that supports multiple target projects simultaneously. Each project gets its own config, source clone, and wiki clone under `workspace/`.

### Layout

```
workspace/
  config/{owner}/{repo}/workspace.config.md   # per-project config
  {owner}/{repo}/                               # cloned source repo (READONLY)
  {owner}/{repo}.wiki/                          # cloned wiki repo
```

Example for `acme/WidgetLib`:

```
workspace/
  config/acme/WidgetLib/workspace.config.md
  acme/WidgetLib/
  acme/WidgetLib.wiki/
```

### Workspace selection

All commands must resolve a workspace before doing anything else. Follow these steps in order:

1. List config files matching `workspace/config/*/*/workspace.config.md`.
2. If no config files exist, tell the user to run `/up` first and **stop**.
3. If `$ARGUMENTS` contains a token that matches a workspace (either `owner/repo` or just `repo`), select that workspace and remove the token from the arguments before continuing.
4. If exactly one workspace exists and no token matched, auto-select it.
5. If multiple workspaces exist and no token matched, list them and prompt the user to choose.
6. Read the selected config to get `repo`, `sourceDir`, `wikiDir`, `audience`, and `tone`.

### Source repo policy

The source repo is **READONLY**. Never stage, commit, or push changes to it. It is cloned only as reference for writing wiki content.

## Forms

`.claude/forms/` contains the canonical shape definitions for structured artifacts — config files, domain events, reports, issue bodies. Commands and agents reference specific forms as needed.

## Guidance

- Read before editing or creating wiki pages: `.claude/guidance/editorial-guidance.md`
- Read before editing or creating wiki pages: `.claude/guidance/wiki-instructions.md`

## Source code context

If the target project has a `CLAUDE.md` at `{sourceDir}/CLAUDE.md`, read it for architecture, style, and conventions.
