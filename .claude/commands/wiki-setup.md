---
name: wiki-setup
description: Clone a GitHub repo and its wiki into the workspace. Sets up wiki-writer.config.json for all other commands.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

Set up a project workspace for wiki editing.

## Input

`$ARGUMENTS` is a GitHub repo slug in `owner/repo` format (e.g., `marklauter/DynamoDbLite`).

If `$ARGUMENTS` is empty, read `wiki-writer.config.json` and confirm the current project. If the config file doesn't exist, ask the user for the repo slug.

## Steps

1. Parse `$ARGUMENTS` to extract `owner` and `repo`.

2. Clone or update the source repo:
   ```bash
   if [ -d "workspace/{repo}" ]; then
     git -C "workspace/{repo}" pull
   else
     mkdir -p workspace
     git clone "https://github.com/{owner}/{repo}.git" "workspace/{repo}"
   fi
   ```

3. Clone or update the wiki repo:
   ```bash
   if [ -d "workspace/{repo}.wiki" ]; then
     git -C "workspace/{repo}.wiki" pull
   else
     git clone "https://github.com/{owner}/{repo}.wiki.git" "workspace/{repo}.wiki"
   fi
   ```
   If the wiki clone fails (repo may not have a wiki yet), note this and continue — the user may need to create the first wiki page on GitHub to initialize it.

4. Check if `workspace/{repo}/CLAUDE.md` exists. If it does, read it to understand the project's architecture, audience, and conventions.

5. Check if `workspace/{repo}.wiki/_Sidebar.md` exists. If it does, read it to understand the existing wiki structure.

6. Ask the user about audience and tone using AskUserQuestion:
   - **Audience**: "Who is the target audience for this wiki?" Suggest a default based on what you learned from the project's CLAUDE.md and README, if available. Let the user confirm or override.
   - **Tone**: "What tone should the wiki use?" Offer options like "reference-style (assume domain familiarity)", "tutorial-style (step-by-step guidance)", or let the user describe their preference.

7. Write `wiki-writer.config.json` at the project root:
   ```json
   {
     "repo": "{owner}/{repo}",
     "sourceDir": "workspace/{repo}",
     "wikiDir": "workspace/{repo}.wiki",
     "audience": "{user's answer}",
     "tone": "{user's answer}"
   }
   ```

8. Confirm the workspace is ready:
   - Source repo: cloned/updated at `workspace/{repo}/`
   - Wiki repo: cloned/updated at `workspace/{repo}.wiki/`
   - Config written to `wiki-writer.config.json`
   - Audience and tone configured
   - Summary of project context (from CLAUDE.md if available)
   - List of existing wiki pages (from _Sidebar.md if available)
