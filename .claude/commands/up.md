---
name: up
description: Provision a workspace for a GitHub project.
allowed-tools: Bash, AskUserQuestion
---

Provision a new project workspace for wiki management. This command interviews the user for all required information — it does not accept arguments.

You can run `/up` multiple times to add workspaces for different projects. Each gets its own isolated directory and config.

## Orchestration

Follow these steps in order. Do not skip steps. Do not improvise shell commands — use the scripts provided.

### 1. Check GitHub authentication

```bash
gh auth status
```

If the user is not authenticated, tell them to run `gh auth login` and **stop**. Do not proceed.

### 2. Collect the clone URL

Ask the user to paste the HTTPS or SSH clone URL for the source repository. This is free text — do not use AskUserQuestion (there are no sensible predefined options for a URL).

Example prompt: "Paste the clone URL for the source repository (HTTPS or SSH, as copied from GitHub)."

### 3. Parse the URL

```bash
.scripts/parse-clone-url.sh "<url>"
```

Eval the output to get `OWNER` and `REPO_NAME`. If the script exits with code 1, tell the user the URL could not be parsed, show the accepted formats from the error message, and ask them to try again. Loop until valid.

### 4. Check for existing workspace

```bash
test -f workspace/artifacts/$OWNER/$REPO_NAME/workspace.config.md
```

If the file exists, tell the user: "A workspace for **$OWNER/$REPO_NAME** already exists. Run `/down` first if you want to start fresh." Then **stop**.

### 5. Ask for audience and tone

Use `AskUserQuestion` with two questions:

**Audience** — "Who is the target audience for this wiki?"
- "Developers integrating the library"
- "End users of the application"
- "Contributors to the project"

**Tone** — "What writing tone should the wiki use?"
- "Reference-style (assumes domain familiarity)"
- "Tutorial-style (step-by-step guidance)"
- "Conversational (friendly, accessible)"

### 6. Validate the source repository

```bash
.scripts/validate-github-repo.sh "$OWNER/$REPO_NAME"
```

If exit code 1: report that the repository was not found or the user lacks access. **Stop.** The user should verify the URL and their permissions, then retry `/up`.

### 7. Validate the wiki repository

```bash
.scripts/validate-github-wiki.sh "$OWNER/$REPO_NAME"
```

If exit code 0: proceed to step 8.

If exit code 1: enter the **wiki wait-and-retry loop**:
1. Tell the user the wiki doesn't exist yet. Explain that GitHub wikis must be initialized through the web UI.
2. Provide instructions:
   - Go to `https://github.com/$OWNER/$REPO_NAME`
   - Click the **Wiki** tab
   - Click **Create the first page**
   - Save the Home page (default content is fine)
3. Use `AskUserQuestion`: "Have you created the wiki on GitHub?"
   - "Yes, I created it"
   - "I need help"
4. If "Yes": re-run `.scripts/validate-github-wiki.sh "$OWNER/$REPO_NAME"`. If it still fails, explain and ask again.
5. If "I need help": provide more detailed instructions and ask again.
6. Loop until the wiki validates.

### 8. Provision the workspace

```bash
.scripts/provision-workspace.sh --url "<url>" --owner "$OWNER" --repo "$REPO_NAME" --audience "<audience>" --tone "<tone>"
```

If the script fails, it cleans up partial state. Report the error to the user and **stop**.

### 9. Present the summary

Show the user the script's output. The script produces a formatted summary from `.claude/forms/provision-summary.md`.

## What this command does NOT do

- **No project content absorption.** Reading CLAUDE.md or _Sidebar.md is an editorial concern (UC-01, UC-02, UC-04), not a workspace lifecycle concern.
- **No chaining.** This command never invokes `/init-wiki` or any other command. It provisions and stops.
