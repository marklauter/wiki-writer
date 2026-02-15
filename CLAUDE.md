# CLAUDE.md

Claude toolset for GitHub wiki management: creation, editorial review, sync, and issue tracking. Works with any GitHub project.

## Workspace

This repo is a reusable workspace. Target projects are cloned into `workspace/` on demand via `/wiki-setup owner/repo`. The config file `wiki-writer.config.json` stores the current target project:

- `repo` — GitHub `owner/repo` slug (used for `gh` commands)
- `sourceDir` — path to the cloned source repo (e.g., `workspace/MyProject`)
- `wikiDir` — path to the cloned wiki repo (e.g., `workspace/MyProject.wiki`)

All commands read this config to resolve paths. If the config file doesn't exist, ask the user to run `/wiki-setup owner/repo` first.

## Guidance

- Read before editing or creating wiki pages: `.claude/guidance/editorial-guidance.md`
- Read before editing or creating wiki pages: `.claude/guidance/wiki-instructions.md`

## Source code context

If the target project has a `CLAUDE.md` at `{sourceDir}/CLAUDE.md`, read it for architecture, style, and conventions.
