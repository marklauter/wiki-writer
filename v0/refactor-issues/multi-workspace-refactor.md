# Plan: Multi-workspace support

## Context

Currently wiki-writer supports a single project at a time — `/up` tears down any existing workspace before cloning a new one, and a single `workspace.config.yml` at the project root holds the active config. This forces a `/down` → `/up` cycle to switch projects.

This change restructures the workspace to support multiple projects simultaneously. Each project gets its own namespace folder and config file. `/up` can be run repeatedly to add projects. `/down` becomes optional cleanup rather than a required step.

## New layout

```
workspace/
├── {owner}/
│   ├── {repo}/              # Source repo clone
│   └── {repo}.wiki/         # Wiki repo clone
├── config/
│   └── {owner}/
│       └── {repo}/
│           └── workspace.config.yml
```

Example with two projects loaded:

```
workspace/
├── acme/
│   ├── widgets/
│   └── widgets.wiki/
├── acme/
│   ├── gadgets/
│   └── gadgets.wiki/
├── config/
│   └── acme/
│       ├── widgets/
│       │   └── workspace.config.yml
│       └── gadgets/
│           └── workspace.config.yml
```

## Workspace selection logic (shared across all commands)

Every command except `/up` needs to select a workspace:

1. List config files matching `workspace/config/*/*/workspace.config.yml`
2. If `$ARGUMENTS` contains a token matching a workspace (`owner/repo` or just `repo`), select it and remove the token from arguments
3. If exactly one workspace exists and no token matched, auto-select it
4. If multiple workspaces exist and no token matched, prompt the user to pick
5. If no workspaces exist, tell the user to run `/up` first and stop
6. Read the selected config file to get `repo`, `sourceDir`, `wikiDir`, `audience`, `tone`

This logic is documented in CLAUDE.md under the Workspace section so all commands can reference it.

## Files to modify

### 1. `CLAUDE.md`
- Update workspace section to describe multi-workspace layout
- Update config path from `workspace.config.yml` to `workspace/config/{owner}/{repo}/workspace.config.yml`
- Update example paths (e.g., `workspace/acme/MyProject`)
- Add the workspace selection logic description so commands can reference it
- Remove "If the config file doesn't exist, ask the user to run `/up` first" (selection logic handles this)

### 2. `README.md`
- Update workspace layout diagram
- Update getting started flow: remove `/down` between projects, note `/up` can be run multiple times
- Update `/up` description: no longer tears down existing workspace
- Update `/down` description: optional cleanup, takes repo name or `--all`
- Update `/save` description: may need to specify which workspace
- Remove references to single `workspace.config.yml`

### 3. `.gitignore`
- Replace `workspace.config.yml` with `workspace/config/` (configs now live inside workspace/)

### 4. `.claude/commands/up.md`
- Remove step 2 (tear down existing workspace via `/down --force`)
- Update step 4: write config to `workspace/config/{owner}/{repo}/workspace.config.yml`
- Update step 5: create `workspace/{owner}/` and `workspace/config/{owner}/{repo}/` directories
- Update step 6: clone source to `workspace/{owner}/{repo}`
- Update step 7: clone wiki to `workspace/{owner}/{repo}.wiki`
- Add check: if workspace already exists for this repo, ask user to confirm overwrite
- Update step 8-9: paths updated accordingly

### 5. `.claude/commands/down.md`
- Rewrite for selective/all teardown
- `$ARGUMENTS` now accepts: repo identifier, `--all`, `--force`
- No argument → list workspaces, prompt user to pick (auto-select if one)
- Repo identifier → remove that specific workspace
- `--all` → remove all workspaces
- Safety checks (uncommitted/unpushed) still apply unless `--force`
- Remove specific workspace: delete `workspace/{owner}/{repo}/`, `workspace/{owner}/{repo}.wiki/`, `workspace/config/{owner}/{repo}/workspace.config.yml`
- Clean up empty parent directories (`workspace/{owner}/`, `workspace/config/{owner}/`)

### 6. `.claude/commands/init-wiki.md`
- Phase 0: replace `Read workspace.config.yml` with workspace selection logic reference

### 7. `.claude/commands/refresh-wiki.md`
- Phase 0: replace `Read workspace.config.yml` with workspace selection logic reference

### 8. `.claude/commands/proofread-wiki.md`
- Phase 0: replace `Read workspace.config.yml` with workspace selection logic reference

### 9. `.claude/commands/revise-wiki.md`
- Phase 0: replace `Read workspace.config.yml` with workspace selection logic reference

### 10. `.claude/commands/save.md`
- Step 1: replace `Read workspace.config.yml` with workspace selection logic reference

### 11. `.scripts/file-issue.sh`
- Accept config path as an optional second argument (after title): `bash .scripts/file-issue.sh "TITLE" "workspace/config/owner/repo/workspace.config.yml" <<'EOF'`
- Fall back to auto-detecting single config if not provided
- Update the `CONFIG` path resolution logic

### 12. `.claude/guidance/wiki-instructions.md`
- No change needed — already references `workspace.config.yml` generically; the config format is the same, just the file path changes. The CLAUDE.md workspace section covers the new path.

## What stays the same

- Config file format (repo, sourceDir, wikiDir, audience, tone) — unchanged
- `.proofread/{repo}/` cache paths — already namespaced by owner/repo, no change needed
- Guidance files (`.claude/guidance/`) — shared across all workspaces, no change
- Issue template (`.github/ISSUE_TEMPLATE/`) — shared, no change
- All command logic after Phase 0 / config loading — unchanged

## Implementation

Use a parallel opus Task agent for each file to be modified.

## Verification

After implementation, verify:

1. Run `/up` twice with different repos — both should coexist in `workspace/`
2. Run `/save` with one workspace loaded — should auto-select
3. Run `/save` with multiple workspaces — should prompt for selection
4. Run `/down reponame` — should remove only that workspace
5. Run `/down --all` — should remove everything
6. Run `/init-wiki`, `/refresh-wiki`, `/proofread-wiki`, `/revise-wiki` — should work with workspace selection
7. Confirm `.proofread/{repo}/` cache still works correctly across multiple workspaces
8. Confirm `file-issue.sh` correctly resolves config when passed as argument
