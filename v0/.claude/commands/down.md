---
name: down
description: Remove a workspace or all workspaces. Optional cleanup — not required between projects.
allowed-tools: Bash, Read, AskUserQuestion
---

Remove one or all project workspaces. This is optional cleanup — you don't need to run `/down` before loading another project with `/up`.

## Input

`$ARGUMENTS` may contain:
- A repo identifier (`owner/repo` or just `repo`) — remove that specific workspace
- `--all` — remove all workspaces
- `--force` — skip safety checks (uncommitted/unpushed wiki changes)
- (no arguments) — list workspaces and prompt the user to pick one (auto-select if only one exists)

## Steps

1. **List workspaces.** Find all config files matching `workspace/config/*/*/workspace.config.yml`. If none exist, tell the user there are no workspaces to remove and stop.

2. **Select workspace(s) to remove:**
   - If `--all` is set, select all workspaces.
   - If a repo identifier is in `$ARGUMENTS`, match it against the available workspaces (`owner/repo` or just `repo`). If no match, list the available workspaces and stop.
   - If no identifier and exactly one workspace exists, auto-select it.
   - If no identifier and multiple workspaces exist, prompt the user to pick one using AskUserQuestion.

3. **For each selected workspace**, read its `workspace.config.yml` to get `sourceDir` and `wikiDir`, then:

   a. Unless `--force` is set, check for **uncommitted changes** in the wiki repo:
      ```bash
      git -C "{wikiDir}" status --porcelain
      ```
      If there are uncommitted changes, warn the user and list them. Ask whether to proceed (changes will be lost) or abort.

   b. Unless `--force` is set, check for **unpushed commits** in the wiki repo:
      ```bash
      git -C "{wikiDir}" log @{u}..HEAD --oneline
      ```
      If there are unpushed commits, warn the user and list them. Ask whether to proceed (commits will be lost) or abort.

   c. Remove the source repo, wiki repo, and config:
      ```bash
      rm -rf "{sourceDir}" "{wikiDir}"
      rm -f "workspace/config/{owner}/{repo}/workspace.config.yml"
      ```

   d. Clean up empty parent directories:
      ```bash
      rmdir "workspace/config/{owner}/{repo}" 2>/dev/null
      rmdir "workspace/config/{owner}" 2>/dev/null
      rmdir "workspace/{owner}" 2>/dev/null
      ```

4. **Confirm** what was removed. List the workspace(s) that were torn down.
