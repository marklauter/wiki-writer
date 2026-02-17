---
name: up
description: Clone a GitHub repo and its wiki into the workspace. Sets up workspace.config.yml for all other commands.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

Set up a project workspace for wiki editing. This command does not accept arguments — it interviews the user for all required information. You can run `/up` multiple times to add workspaces for different repos — each gets its own isolated directory and config.

## Steps

1. **Check GitHub authentication:**
   ```bash
   gh auth status
   ```
   If the user is not authenticated, tell them to run `gh auth login` to get authorized and then run `/up` again. Stop — do not proceed.

2. **Check for existing workspace.** After the interview step provides the `{owner}` and `{repo}` values, check if `workspace/config/{owner}/{repo}/workspace.config.yml` already exists. If it does, say "Already got that one, buddy" and stop. If the user wants to start fresh, they can run `/down {owner}/{repo}` first and then `/up` again.

3. **Interview the user** for workspace configuration using AskUserQuestion. Collect the following:

   - **Source repo clone URL** — Ask the user to paste the full HTTPS or SSH clone URL as copied from GitHub (e.g., `https://github.com/owner/repo.git` or `git@github.com:owner/repo.git`). Parse the `owner` and `repo` name from the URL. If the URL doesn't parse cleanly, ask the user to correct it.

   - **Audience** — "Who is the target audience for this wiki?" Offer options like:
     - "Developers integrating the library"
     - "End users of the application"
     - "Contributors to the project"

   - **Tone** — "What tone should the wiki use?" Offer options like:
     - "Reference-style (assume domain familiarity)"
     - "Tutorial-style (step-by-step guidance)"
     - "Conversational (friendly, accessible)"

   Batch these into one or two AskUserQuestion calls (up to 4 questions each).

4. **Write `workspace/config/{owner}/{repo}/workspace.config.yml`** using the confirmed values:
   ```yaml
   repo: "{owner}/{repo}"
   sourceDir: "workspace/{owner}/{repo}"
   wikiDir: "workspace/{owner}/{repo}.wiki"
   audience: "{confirmed audience}"
   tone: "{confirmed tone}"
   ```

5. **Ensure directories exist:**
   ```bash
   mkdir -p workspace/{owner}
   mkdir -p workspace/config/{owner}/{repo}
   ```

6. **Clone the source repo:**
   ```bash
   git clone "{clone_url}" "workspace/{owner}/{repo}"
   ```
   If the clone fails (repo doesn't exist, permission denied, etc.), report the error to the user and stop.

7. **Clone the wiki repo.** Derive the wiki clone URL from the source clone URL using the same protocol:
   - HTTPS source → `https://github.com/{owner}/{repo}.wiki.git`
   - SSH source → `git@github.com:{owner}/{repo}.wiki.git`

   ```bash
   git clone "{wiki_clone_url}" "workspace/{owner}/{repo}.wiki"
   ```
   If the wiki clone fails (the repo may not have a wiki yet), tell the user they may need to create the first wiki page on GitHub to initialize it. Continue — the wiki repo is not required for setup to succeed.

8. **Read project context.** If `workspace/{owner}/{repo}/CLAUDE.md` exists, read it to understand the project's architecture, audience, and conventions. If `workspace/{owner}/{repo}.wiki/_Sidebar.md` exists, read it to understand the existing wiki structure.

9. **Confirm the workspace is ready:**
   - Source repo: cloned at `workspace/{owner}/{repo}/`
   - Wiki repo: cloned at `workspace/{owner}/{repo}.wiki/` (or note if the wiki clone failed)
   - Config written to `workspace/config/{owner}/{repo}/workspace.config.yml`
   - All config values summarized
   - Summary of project context (from CLAUDE.md if available)
   - List of existing wiki pages (from _Sidebar.md if available)
