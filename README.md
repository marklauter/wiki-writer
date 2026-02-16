![wiki-writer](https://raw.githubusercontent.com/marklauter/wiki-agent/refs/heads/main/images/agent-logo.png)

# wiki-agent

Claude Code toolset for GitHub wiki management. Works with any GitHub project.

GitHub wikis have no CI, no review workflow, and drift from source code over time. wiki-writer automates wiki creation, editorial review, sync, and issue tracking so your docs stay current with every code change.

## How it works

wiki-writer generates and maintains GitHub wiki pages from your source code. It runs as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) workspace. You open this project, tell it which repo you're working on, and it clones the source and wiki repos into a local `workspace/` directory. All commands then operate against whatever project is currently loaded.

Multiple projects can be loaded at the same time. Run `/up` again to add another project. Nothing is permanent — cloned repos and configs are gitignored. Run `/down` to clean up a workspace when you no longer need it.

### Workspace layout

```
wiki-writer/
├── .claude/              # Commands, skills, and guidance (checked in)
├── workspace/            # Cloned repos and configs (gitignored)
│   ├── {owner}/
│   │   ├── {repo}/       # Source repo
│   │   └── {repo}.wiki/  # Wiki repo
│   └── config/
│       └── {owner}/
│           └── {repo}/
│               └── workspace.config.yml
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated with write access to issues
- Git configured with push access to your GitHub wiki repos
- Target repo must have its wiki enabled (create at least one page on GitHub to initialize it)

## Getting started

1. **Clone wiki-writer:**

   ```bash
   # Replace with your fork or clone URL
   git clone https://github.com/your-org/wiki-writer.git
   cd wiki-writer
   ```

2. **Open it in Claude Code:**

   ```bash
   claude
   ```

3. **Load a project:**

   ```
   /up
   ```

   This interviews you for the source repo clone URL, target audience, and tone, then clones the source repo and its wiki into `workspace/` and writes `workspace/config/{owner}/{repo}/workspace.config.yml`. All other commands use this config. Run `/up` again to load additional projects.

4. **Bootstrap the wiki (if new):**

   ```
   /init-wiki
   ```

5. **Work on the wiki** using the commands below.

6. **Push your changes:**

   ```
   /save
   ```

Optionally, run `/down` to clean up a workspace when you no longer need it.

## Commands

### `/up`

Set up a project workspace. Does not accept arguments — interviews you for all required information. Can be run multiple times to load additional projects.

What it does:

- Verifies GitHub CLI authentication (`gh auth status`)
- Asks for the source repo clone URL (full HTTPS or SSH URL from GitHub), target audience, and tone
- If a workspace already exists for the same repo, stops and tells you to run `/down` first
- Clones the source repo and wiki repo into `workspace/{owner}/`
- Writes `workspace/config/{owner}/{repo}/workspace.config.yml` with:
  - `repo` — GitHub `owner/repo` slug (parsed from the clone URL)
  - `sourceDir` — path to cloned source repo (e.g., `workspace/{owner}/{repo}`)
  - `wikiDir` — path to cloned wiki repo (e.g., `workspace/{owner}/{repo}.wiki`)
  - `audience` — target audience for the wiki
  - `tone` — writing tone (e.g., reference-style, tutorial-style)
- Reads `CLAUDE.md` (project instructions for Claude Code) if the target project has one
- Reads `_Sidebar.md` (the wiki navigation menu) if the wiki already exists

### `/init-wiki`

Bootstrap a brand-new wiki from source code. Only works on wikis with no existing content (beyond the default `Home.md`). Auto-selects the workspace if only one is loaded, or prompts if multiple are loaded. Pass `owner/repo` or `repo` to target a specific workspace.

What it does:

1. **Explore the codebase** — five background agents examine architecture, public API, configuration, features, and usage examples.
2. **Propose a page structure** — synthesizes explorer reports into a proposed page list (filename, title, description, key source files) and asks you to confirm or adjust.
3. **Write all pages** — launches a parallel writer agent for each approved page. Each agent reads the relevant source files and follows the editorial guidance.
4. **Generate sidebar and verify Home** — creates `_Sidebar.md` (wiki navigation menu) and verifies `Home.md`.

### `/down`

Optional cleanup command. Not required between projects.

Takes an optional repo identifier (`owner/repo` or `repo`) to remove a specific workspace. Pass `--all` to remove all workspaces.

What it does:

- Checks for **uncommitted changes** in the wiki repo — warns and asks to confirm
- Checks for **unpushed commits** in the wiki repo — warns and asks to confirm
- Removes the source repo, wiki repo, and config for the selected workspace

### `/refresh-wiki`

Sync wiki pages with recent source code changes. Auto-selects the workspace if only one is loaded, or prompts if multiple are loaded. Pass `owner/repo` or `repo` to target a specific workspace.

What it does:

1. Reads the last 50 commits from the source repo and identifies changed files
2. Maps changed files to wiki pages via the sidebar structure
3. Launches explorer agents to compare each affected wiki page against current source code
4. Launches update agents to edit pages that are out of date

Pass `-plan` to run the exploration without editing — shows which pages are stale and what would change.

### `/proofread-wiki`

Review wiki pages for structure, clarity, accuracy, and style. Auto-selects the workspace if only one is loaded, or prompts if multiple are loaded. Pass `owner/repo` or `repo` to target a specific workspace.

What it does:

Launches parallel reviewer agents that audit pages through four editorial lenses:

| Lens | Scope |
|------|-------|
| Structure | Organization, flow, gaps, redundancies |
| Line | Sentence-level clarity, tightening, transitions |
| Copy | Grammar, punctuation, formatting, terminology |
| Accuracy | Verify claims, examples, and behavior against source code |

Files findings as GitHub issues with the `documentation` label.

### `/resolve-issues`

Apply corrections from open `documentation`-labeled GitHub issues to wiki pages. Auto-selects the workspace if only one is loaded, or prompts if multiple are loaded. Pass `owner/repo` or `repo` to target a specific workspace.

What it does:

- Reads open issues with the `documentation` label
- Applies the recommended corrections to the corresponding wiki pages
- Closes each issue after the fix is applied

You can pass specific issue numbers, a page name, or `-plan` to preview changes without applying them.

### `/save`

Commit and push all wiki changes to GitHub. Auto-selects the workspace if only one is loaded, or prompts if multiple are loaded. Pass `owner/repo` or `repo` to target a specific workspace.

What it does:

- Stages and commits all changes in the wiki repo
- Pushes to the remote wiki on GitHub
- Never touches the source repo
