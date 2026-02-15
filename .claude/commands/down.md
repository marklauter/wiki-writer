---
name: down
description: Tear down the current workspace — remove cloned repos and config.
allowed-tools: Bash, Read, AskUserQuestion
---

Tear down the current project workspace.

## Input

`$ARGUMENTS` may contain `--force` to skip safety checks (uncommitted/unpushed wiki changes). When `/down` is called from `/up`, pass `--force` to avoid redundant confirmations.

## Steps

1. Read `workspace.config.yml` to get `sourceDir` and `wikiDir`. If the config file doesn't exist, tell the user there's nothing to tear down and stop.

2. Unless `--force` is set, check for uncommitted changes in the wiki repo:
   ```bash
   git -C "{wikiDir}" status --porcelain
   ```
   If there are uncommitted changes, warn the user and list them. Ask whether to proceed (changes will be lost) or abort.

3. Unless `--force` is set, check for unpushed commits in the wiki repo:
   ```bash
   git -C "{wikiDir}" log @{u}..HEAD --oneline
   ```
   If there are unpushed commits, warn the user and list them. Ask whether to proceed (commits will be lost) or abort.

4. Remove the cloned repos and config file:
   ```bash
   rm -rf "{sourceDir}" "{wikiDir}" workspace.config.yml
   ```

5. Confirm teardown is complete.
