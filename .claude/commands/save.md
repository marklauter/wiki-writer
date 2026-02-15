---
name: save
description: Commit and push wiki changes to GitHub. Never touches the source repo.
allowed-tools: Bash, Read
---

Commit and push all wiki changes to GitHub.

## Steps

1. Read `workspace.config.yml` to get `wikiDir`. If the config file doesn't exist, tell the user there's nothing to save and stop.

2. Check for changes in the wiki repo:
   ```bash
   git -C "{wikiDir}" status --porcelain
   ```
   If there are no changes (no uncommitted changes and no unpushed commits), tell the user the wiki is already up to date and stop.

3. Stage all changes:
   ```bash
   git -C "{wikiDir}" add -A
   ```

4. Show the user what will be committed:
   ```bash
   git -C "{wikiDir}" diff --cached --stat
   ```

5. Commit with a descriptive message summarizing the changed files:
   ```bash
   git -C "{wikiDir}" commit -m "{message}"
   ```
   Write a short commit message based on the changed files (e.g., "Update Query-and-Scan and Getting-Started pages").

6. Push to origin:
   ```bash
   git -C "{wikiDir}" push
   ```

7. Confirm the push succeeded and summarize what was pushed.

## Constraints

- **Wiki repo only.** Never stage, commit, or push changes in the source repo.
- **Never force push.** Use `git push`, not `git push --force`.
