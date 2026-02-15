# wiki-writer

Claude Code toolset for GitHub wiki management: creation, editorial review, sync, and issue tracking. Works with any GitHub project.

GitHub wikis have no CI, no review workflow, and drift from source code over time. wiki-writer automates wiki creation, editorial review, and sync so your docs stay current with every code change.

## How it works

wiki-writer generates and maintains GitHub wiki pages from your source code. It runs as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) workspace — you open this project, tell it which repo you're working on, and it clones the source and wiki repos into a local `workspace/` directory. All commands then operate against whatever project is currently loaded.

Nothing is permanent — cloned repos and config are gitignored. Switch projects any time by running `/up` with a different repo.

### Workspace layout

```
wiki-writer/
├── .claude/              # Commands, skills, and guidance (checked in)
├── workspace/            # Cloned repos (gitignored)
│   ├── MyProject/        # Source repo
│   └── MyProject.wiki/   # Wiki repo
└── workspace.config.yml   # Current project config (gitignored)
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
   /up owner/repo
   ```

   This clones the source repo and its wiki into `workspace/`, asks you about target audience and tone, and writes `workspace.config.yml`. All other commands use this config.

4. **Bootstrap the wiki (if new):**

   ```
   /init-wiki
   ```

5. **Work on the wiki** using the commands below.

6. **Push your changes:**

   ```
   /save
   ```

7. **Tear down when done:**

   ```
   /down
   ```

   This checks for uncommitted or unpushed wiki changes before cleaning up.

## Commands

### `/up owner/repo`

Set up a project workspace. Clones (or pulls) the source repo and wiki repo into `workspace/`, then asks for your audience and tone preferences. Writes `workspace.config.yml` with:

- `repo` — GitHub `owner/repo` slug
- `sourceDir` — path to cloned source repo
- `wikiDir` — path to cloned wiki repo
- `audience` — target audience for the wiki
- `tone` — writing tone (e.g., reference-style, tutorial-style)

If the target project has a `CLAUDE.md` (project instructions for Claude Code), it reads that for project context. If the wiki already exists, it reads `_Sidebar.md` (the wiki navigation menu) to understand the current structure.

Run `/up` without arguments to confirm which project is currently loaded. To switch projects, run `/up` with a different repo — it tears down the current workspace first (checking for unsaved wiki changes), then sets up the new one.

### `/init-wiki`

Bootstrap a brand-new wiki from source code. Launches parallel explorer agents to understand the codebase, proposes a wiki structure for your approval, then spins up writer agents to populate every page. Only works on wikis with no existing content (beyond the default `Home.md`).

What it does:

1. **Explore the codebase** — five background agents examine architecture, public API, configuration, features, and usage examples.
2. **Propose a page structure** — synthesizes explorer reports into a proposed page list (filename, title, description, key source files) and asks you to confirm or adjust.
3. **Write all pages** — launches a parallel writer agent for each approved page. Each agent reads the relevant source files and follows the editorial guidance.
4. **Generate sidebar and verify Home** — creates `_Sidebar.md` (wiki navigation menu) and verifies `Home.md`.

### `/down`

Tear down the current workspace.

What it does:

- Checks for **uncommitted changes** in the wiki repo — warns and asks to confirm
- Checks for **unpushed commits** in the wiki repo — warns and asks to confirm
- Removes the cloned repos, config file, and (if empty) the `workspace/` directory

### `/refresh-wiki`

Sync wiki pages with recent source code changes.

What it does:

1. Reads the last 50 commits from the source repo
2. Identifies behavioral changes that affect documentation
3. Edits the corresponding wiki pages to match current behavior

### `/proofread-wiki`

Editorial review of wiki pages. Launches parallel reviewer agents that audit pages across four passes:

| Pass | Scope |
|------|-------|
| `structural` | Organization, flow, gaps, redundancies |
| `line` | Sentence-level clarity and tightening |
| `copy` | Grammar, punctuation, formatting, terminology |
| `accuracy` | Verify claims and examples against source code |

Files findings as GitHub issues with the `documentation` label. You can target specific pages or passes, or review everything at once.

### `/resolve-issues`

Applies corrections from open `documentation`-labeled GitHub issues to wiki pages and closes them. You can pass specific issue numbers, a page name, or `-plan` to preview changes without applying them.

### `/save`

Commit and push all wiki changes to GitHub.

What it does:

- Stages and commits all changes in the wiki repo
- Pushes to the remote wiki on GitHub
- Never touches the source repo

