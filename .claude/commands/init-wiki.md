---
name: init-wiki
description: Explore source code and populate a brand-new wiki with pages.
model: sonnet
allowed-tools: Bash, Read, Grep, Glob, Task, Write, Edit, TodoWrite, AskUserQuestion
---

Bootstrap a wiki from scratch. Launch an explorer agent swarm to understand the source code, plan a wiki structure with the user, then populate the wiki directory with well-written pages.

Audience, tone, writing principles: `CLAUDE.md`.

## Phase 0: Select workspace, load config, and validate

1. Follow the **Workspace selection** procedure in `CLAUDE.md`:
   1. List config files matching `workspace/config/*/*/workspace.config.yml`.
   2. If `$ARGUMENTS` contains a token matching a workspace (`owner/repo` or just `repo`), select it and remove the token from `$ARGUMENTS`.
   3. If exactly one workspace exists and no token matched, auto-select it.
   4. If multiple workspaces exist and no token matched, prompt the user to pick one.
   5. If no workspaces exist, tell the user to run `/up` first and stop.
   6. Read the selected config file to get `repo`, `sourceDir`, `wikiDir`, `audience`, and `tone`.

2. Check that `{wikiDir}` exists:
   ```bash
   ls "{wikiDir}"
   ```
   If the directory doesn't exist, tell the user to run `/up` first and stop.

3. Check that the wiki is brand new. List all files in `{wikiDir}` (excluding `.git`):
   ```bash
   ls "{wikiDir}" | grep -v '^\.'
   ```
   Allowed states:
   - **Empty** (no files) — proceed.
   - **Only `Home.md`** — proceed (will overwrite it).
   - **Any other files** — abort with: "Wiki already has content. `/init-wiki` is for brand-new wikis only. Use `/refresh-wiki` to update existing pages."

4. Read guidance files:
   - `.claude/guidance/editorial-guidance.md`
   - `.claude/guidance/wiki-instructions.md`

5. If `{sourceDir}/CLAUDE.md` exists, read it for project architecture and conventions.

## Phase 1: Explorer swarm (background agents)

Launch 5 background Explore agents (`subagent_type: Explore`, `model: opus`, `run_in_background: true`) to examine distinct facets of the source code. Each agent receives the `sourceDir` path.

### Agent 1: Architecture

> Explore the project at `{sourceDir}`. Map the overall architecture: project structure, entry points, layers, key abstractions, and dependency flow. Return a structured report with:
> - Project type (library, CLI, web app, etc.)
> - Major components and their responsibilities
> - How components interact
> - Key design patterns used

### Agent 2: Public API

> Explore the project at `{sourceDir}`. Identify the full public API surface: public classes, methods, interfaces, endpoints, parameters, and return types. Group them by feature area. Return a structured report with:
> - Grouped API surface with signatures
> - Brief description of each public member
> - Which source files define each API

### Agent 3: Configuration and setup

> Explore the project at `{sourceDir}`. Identify everything a new user needs to get started: installation, configuration, prerequisites, dependencies, environment setup. Check README, config files, package manifests, and initialization code. Return a structured report with:
> - Prerequisites and dependencies
> - Installation steps
> - Configuration options and their defaults
> - Environment requirements

### Agent 4: Features and behavior

> Explore the project at `{sourceDir}`. Identify the core capabilities, workflows, behaviors, edge cases, and limitations. Focus on what the project *does*, not how it's built. Return a structured report with:
> - Feature list with behavioral descriptions
> - Key workflows and their steps
> - Important edge cases and limitations
> - Error handling behavior

### Agent 5: Examples and usage

> Explore the project at `{sourceDir}`. Find concrete usage examples: test files, sample code, READMEs, doc comments, example directories. Return a structured report with:
> - Common usage patterns with code snippets
> - Test cases that illustrate behavior
> - Any official examples or samples

Launch all 5 agents in parallel. Collect results from each using `TaskOutput` (blocking).

## Phase 2: Plan wiki structure (opus agent)

Launch a Task agent (`subagent_type: general-purpose`, `model: opus`) to synthesize the explorer reports into a wiki plan. Pass it all 5 explorer reports and the following instructions:

> You are a documentation architect. Given the explorer reports below, design a wiki structure for this project.
>
> For each page, define:
> - **Filename** — kebab-case with `.md` extension (e.g., `Getting-Started.md`)
> - **Title** — sentence-case heading for the page
> - **Description** — one sentence on what the page covers
> - **Key source files** — which source files the writer agent should read to produce accurate content
>
> Always include:
> - `Home.md` — project overview, what it does, why it exists, quick links to other pages
> - `_Sidebar.md` — navigation (written last, after all pages exist)
>
> Typical pages to consider (include only what the project warrants — don't create pages for features that don't exist):
> - Getting started — installation, setup, first use
> - Core concepts / architecture — key abstractions and how they fit together
> - API reference pages — one per major feature area, grouped logically
> - Configuration — options, defaults, environment variables
> - Examples — common patterns and recipes
> - Advanced topics — edge cases, performance, extensibility
> - Compatibility / parity — if the project has a compatibility matrix
>
> Target audience: `{audience}`
> Tone: `{tone}`
>
> Return a structured list of `(filename, title, description, key-source-files)` tuples. Order pages by reader priority — start with getting started, then core concepts, then reference pages.

After the agent returns the proposed structure, present it to the user via `AskUserQuestion`. Show the full list of planned pages with filenames and descriptions. Let the user confirm, request additions, or request removals. Adjust the plan based on their feedback.

## Phase 3: Writer swarm (parallel agents)

For each approved wiki page (except `_Sidebar.md`), launch a **background** Task agent (`subagent_type: general-purpose`, `model: opus`, `run_in_background: true`).

### What to tell each writer agent

Pass to each agent:

- The wiki page path to write: `{wikiDir}/{filename}`
- The page title and description from Phase 2
- The key source file paths to read for accurate content
- The `audience` and `tone` from workspace config
- Instruction to read `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md` before writing
- Instruction to read the relevant source files thoroughly before writing — accuracy matters more than speed
- Instruction to use the `Write` tool to create the page
- Instruction to follow these writing principles:
  - Second person ("you") — direct, conversational, professional
  - Present tense — "the method returns" not "the method will return"
  - Short sentences, short paragraphs — scannable over readable
  - Sentence-case headings — not Title Case
  - Numbered steps for tasks, bullets for options
  - Lead with what the reader needs, not background
  - Self-contained pages — include enough context for readers who arrive from search
  - Usage and behavior first, internals second
  - Code examples that compile and match the current API
  - Reference-style by default — adjust to `{tone}` from config if different

Each agent returns a brief summary of what was written and the final heading structure of the page.

Launch all writer agents **in parallel**. Collect results from each using `TaskOutput` (blocking).

## Phase 4: Sidebar and Home

After all writer agents complete:

1. **Write `_Sidebar.md`**: Create the navigation sidebar with links to all pages. Use the wiki link format `[[Page Title|Page-Filename]]`. Group pages logically with section headers if there are more than 5 pages.

2. **Verify `Home.md`**: Read `{wikiDir}/Home.md` and confirm it was written by the writer swarm. If it's still the default GitHub placeholder, overwrite it with a proper landing page that:
   - States what the project is and what it does
   - Links to Getting Started (or equivalent first-steps page)
   - Provides a brief overview of what the wiki covers
   - Links to key sections

## Phase 5: Summary

Output:

1. **Pages created** — table with columns: Filename, Title, Description.
2. **Wiki structure** — the `_Sidebar.md` content.
3. **Next steps** — suggest:
   - Review the pages for accuracy
   - Run `/proofread-wiki` for editorial review
   - Run `/save` to commit and push to GitHub

## Constraints

- **New wikis only.** Abort if the wiki already has content beyond `Home.md`.
- **Never modify source code.** Only write to `{wikiDir}`.
- **Accuracy over speed.** Writer agents must read source code before writing. Don't document from memory or assumptions.
- **Don't over-scope.** Only create pages for features that actually exist. Don't create placeholder pages for hypothetical content.
- **Respect config.** Honor `audience` and `tone` from workspace config in all pages.
