---
name: down
description: Tear down the current workspace — remove cloned repos and config.
allowed-tools: Bash, Read
---

Tear down the current project workspace.

## Steps

1. Read `wiki-writer.config.json` to get `sourceDir` and `wikiDir`. If the config file doesn't exist, tell the user there's nothing to tear down and stop.

2. Check for uncommitted changes in the wiki repo:
   ```bash
   git -C "{wikiDir}" status --porcelain
   ```
   If there are uncommitted changes, warn the user and list them. Ask whether to proceed (changes will be lost) or abort.

3. Check for unpushed commits in the wiki repo:
   ```bash
   git -C "{wikiDir}" log @{u}..HEAD --oneline
   ```
   If there are unpushed commits, warn the user and list them. Ask whether to proceed (commits will be lost) or abort.

4. Remove the cloned repos:
   ```bash
   rm -rf "{sourceDir}" "{wikiDir}"
   ```

5. Remove the config file:
   ```bash
   rm wiki-writer.config.json
   ```

6. Confirm teardown is complete. If the `workspace/` directory is now empty, remove it too.
