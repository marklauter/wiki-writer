![wiki-agent](https://raw.githubusercontent.com/marklauter/wiki-agent/refs/heads/main/images/agent-logo.png)

# wiki-agent

Claude Code agentic toolset for GitHub wiki management. Works with any GitHub project.

GitHub wikis have no CI, no review workflow, and drift from source code over time. wiki-agent automates wiki creation, editorial review, drift detection, and wiki revision so documentation stays current.

## How it works

Wiki-agent generates and maintains GitHub wiki pages from your source code. It runs as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) workspace. You open this project, tell it which repo you're working on, and it clones the source and wiki repos into a local `workspace/` directory. All commands operate against whatever project is currently loaded.

Wiki-agent never commits or pushes to git. Every command writes to local files only — you review changes with `git diff`, commit when you're satisfied, and push when you're ready. Nothing reaches GitHub until you decide it should. Source repositories are cloned as readonly references and are never modified.

Multiple projects can be loaded at the same time. Run `/up` again to add another project. Nothing is permanent — cloned repos and configs are gitignored. Run `/down` to clean up a workspace when you no longer need it.

### Workspace layout

```
wiki-agent/
├── .claude/              # Commands, guidance, and forms (checked in)
├── .scripts/             # Shell scripts for deterministic operations (checked in)
├── workspace/            # Cloned repos and artifacts (gitignored)
│   ├── {owner}/
│   │   ├── {repo}/       # Source repo (readonly)
│   │   └── {repo}.wiki/  # Wiki repo (mutable)
│   └── artifacts/
│       └── {owner}/
│           └── {repo}/
│               ├── workspace.config.md
│               └── reports/
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated with write access to issues
- Git configured with push access to your GitHub wiki repos
- Target repo must have its wiki enabled (create at least one page on GitHub to initialize it)

## Getting started

1. **Clone wiki-agent:**

   ```bash
   git clone https://github.com/marklauter/wiki-agent.git
   cd wiki-agent
   ```

2. **Open it in Claude Code:**

   ```bash
   claude
   ```

3. **Load a project:**

   ```
   /up
   ```

   Interviews you for the source repo clone URL, target audience, and tone. Clones the source and wiki repos into `workspace/` and writes a workspace config. All other commands use this config.

4. **Bootstrap the wiki (if new):**

   ```
   /init-wiki
   ```

5. **Work on the wiki** using the commands below.

6. **Publish your changes** by committing and pushing in the wiki repo with your own git tools.

## Commands

### `/up`

Provision a project workspace. Interviews you for all required information — does not accept arguments.

- Verifies GitHub CLI authentication
- Asks for the source repo clone URL, target audience, and tone
- Validates that both the source repo and wiki repo exist on GitHub
- If the wiki doesn't exist yet, provides instructions for creating it through the GitHub web UI and waits
- Clones both repos and writes `workspace/artifacts/{owner}/{repo}/workspace.config.md`
- If a workspace already exists for the same repo, stops and tells you to run `/down` first

### `/init-wiki`

Populate a brand-new wiki from source code. Only works on wikis with no existing content pages. Uses the workspace selection protocol (auto-selects if one workspace loaded, prompts if multiple).

1. **Explore the codebase** — researchers examine the source code across multiple facets (architecture, public API, configuration, features, usage).
2. **Propose a page structure** — a developmental editor synthesizes research into a proposed wiki plan and presents it for your approval. No pages are written until you're satisfied with the plan.
3. **Write all pages** — parallel creators write each approved page from source code.
4. **Generate sidebar** — creates `_Sidebar.md` and verifies `Home.md`.

Content has not been independently verified for accuracy at this point. Run `/proofread-wiki` next.

### `/proofread-wiki`

Review wiki pages for quality. Uses the workspace selection protocol. Never edits wiki files — review only.

Dispatches parallel proofreaders that audit pages through four editorial lenses:

| Lens | Scope |
|------|-------|
| Structure | Organization, flow, gaps, redundancies across the whole wiki |
| Line | Sentence-level clarity, tightening, transitions |
| Copy | Grammar, punctuation, formatting, terminology consistency |
| Accuracy | Verify claims, examples, and behavior against source code |

Findings are deduplicated against existing open issues, then filed as individual GitHub issues with the `documentation` label. Run `/revise-wiki` to apply corrections.

### `/revise-wiki`

Apply corrections from open `documentation`-labeled GitHub issues. Uses the workspace selection protocol.

- Reads all open issues labeled `documentation`
- Dispatches correctors to apply recommended fixes to wiki pages
- Closes each issue after the fix is applied
- Adds `needs-clarification` to ambiguous issues and skips them
- Issues lacking structured page/finding/recommendation fields are skipped silently

Targeted edits only — never creates new pages or rewrites existing ones.

### `/refresh-wiki`

Sync wiki pages with current source code. Uses the workspace selection protocol.

1. Dispatches fact-checkers across all content pages. Every factual claim is verified against source code and external references (URLs, linked docs, specifications).
2. Dispatches correctors to fix pages where drift is detected.
3. Writes a sync report to `workspace/artifacts/{owner}/{repo}/reports/`.

Recent source changes are used as priority context but do not limit scope — all claims on all pages are checked. Corrections are applied directly. Review changes with `git diff` and revert if needed.

### `/down`

Remove a project workspace. Uses the workspace selection protocol.

- Checks for uncommitted changes and unpushed commits in the wiki repo
- If unsaved work exists, requires you to type the repo name to confirm deletion
- Removes the source clone, wiki clone, config, reports, and any cached artifacts
