---
name: up
description: Clone a GitHub repo and its wiki into the workspace. Sets up workspace.config.yml for all other commands.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

Set up a project workspace for wiki editing.

## Input

`$ARGUMENTS` is a GitHub repo slug in `owner/repo` format (e.g., `marklauter/DynamoDbLite`).

If `$ARGUMENTS` is empty, read `workspace.config.yml` and confirm the current project. If the config file doesn't exist, ask the user for the repo slug.

## Steps

1. If `workspace.config.yml` exists, run the `/down` teardown flow first (see `down.md`). This checks for uncommitted and unpushed wiki changes before removing anything. If the user aborts teardown, stop — do not proceed with setup.

2. Parse `$ARGUMENTS` to extract `owner` and `repo`.

3. Clone or update the source repo:
   ```bash
   if [ -d "workspace/{repo}" ]; then
     git -C "workspace/{repo}" pull
   else
     mkdir -p workspace
     git clone "https://github.com/{owner}/{repo}.git" "workspace/{repo}"
   fi
   ```

4. Clone or update the wiki repo:
   ```bash
   if [ -d "workspace/{repo}.wiki" ]; then
     git -C "workspace/{repo}.wiki" pull
   else
     git clone "https://github.com/{owner}/{repo}.wiki.git" "workspace/{repo}.wiki"
   fi
   ```
   If the wiki clone fails (repo may not have a wiki yet), note this and continue — the user may need to create the first wiki page on GitHub to initialize it.

5. Check if `workspace/{repo}/CLAUDE.md` exists. If it does, read it to understand the project's architecture, audience, and conventions.

6. Check if `workspace/{repo}.wiki/_Sidebar.md` exists. If it does, read it to understand the existing wiki structure.

7. Prompt the user to confirm or customize **all** workspace config values using AskUserQuestion. Present sensible defaults based on the repo slug and any context gathered from CLAUDE.md/README. The user can accept defaults or override any value.

   - **Repo slug**: Default `{owner}/{repo}`. Let the user confirm.
   - **Source directory**: Default `workspace/{repo}`. Let the user override if they prefer a different path.
   - **Wiki directory**: Default `workspace/{repo}.wiki`. Let the user override if they prefer a different path.
   - **Audience**: "Who is the target audience for this wiki?" Suggest a default based on what you learned from the project's CLAUDE.md and README, if available. Let the user confirm or override.
   - **Tone**: "What tone should the wiki use?" Offer options like "reference-style (assume domain familiarity)", "tutorial-style (step-by-step guidance)", or let the user describe their preference.

   You may batch these into one or two AskUserQuestion calls (up to 4 questions each) to keep the flow concise.

8. Write `workspace.config.yml` at the project root using the user's confirmed values:
   ```yaml
   repo: "{confirmed repo slug}"
   sourceDir: "{confirmed sourceDir}"
   wikiDir: "{confirmed wikiDir}"
   audience: "{confirmed audience}"
   tone: "{confirmed tone}"
   ```

9. Confirm the workspace is ready:
   - Source repo: cloned/updated at `{sourceDir}/`
   - Wiki repo: cloned/updated at `{wikiDir}/`
   - Config written to `workspace.config.yml`
   - All config values summarized
   - Summary of project context (from CLAUDE.md if available)
   - List of existing wiki pages (from _Sidebar.md if available)
