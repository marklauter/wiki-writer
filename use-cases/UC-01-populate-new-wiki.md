# UC-01 -- Populate New Wiki

## Goal

A project's empty wiki is populated with a complete, well-structured set of documentation pages that accurately reflect the source code. The wiki is ready for human review -- every page serves the configured audience in the configured tone, and no page exists for a feature that does not exist in the source. The user can immediately run `/proofread-wiki` (UC-02) to verify quality, or `/save` to publish.

## Context

- **Bounded context:** Wiki Creation
- **Primary actor:** User
- **Supporting actors:** Orchestrator (`/init-wiki` command), Explorer agents (wiki-explorer), Planning agent (general-purpose), Writer agents (wiki-writer)
- **Trigger:** The user has provisioned a workspace (UC-05) and wants to create wiki documentation for a project that does not yet have any.

## Agent responsibilities

Each agent has a single drive. Separation exists because no single drive can protect all the concerns at play.

- **Orchestrator** -- Drive: coordination. Resolves the workspace, validates the wiki is new, distributes context to agents, dispatches explorers and writers, collects results, writes _Sidebar.md, and presents the summary. The orchestrator makes no editorial judgments -- it delegates comprehension to explorers, synthesis to the planner, and production to writers.

- **Explorer agents** -- Drive: comprehension. Each examines the source code from a distinct angle and produces a structured report. Explorers are read-only -- they never modify files. Each instance's drive is to understand its assigned facet thoroughly, citing specific files and line numbers.

- **Planning agent** -- Drive: synthesis. Receives all exploration reports and produces a coherent wiki structure -- sections containing pages, each with a filename, title, description, and key source files. The planner's drive is to turn raw understanding into a structure that serves the audience. It does not write content; it organizes.

- **Writer agents** -- Drive: production. Each receives a page assignment with source file references, audience, tone, and editorial guidance, then reads the source files and writes one wiki page. The writer's drive is to produce well-structured, readable content. This drive is insufficient to guarantee accuracy on its own -- which is exactly why UC-02 (Review Wiki Quality) exists as a separate use case with a critique drive. Within UC-01, the writer reads source code before writing (invariant), but the production drive means it optimizes for coverage and clarity, not for catching its own mistakes.

## Invariants

See also: [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) for cross-cutting invariants (GitHub CLI, source readonly, config as identity, scripts own deterministic behavior, etc.)

- **New wikis only.** The wiki directory must contain no content pages. Structural files (Home.md, _Sidebar.md, _Footer.md) do not count as content. If content pages exist, `/init-wiki` refuses to operate. The system does not delete existing content -- the user owns destructive actions.
- **Source code is the single source of truth.** Every claim in a wiki page must be grounded in the actual source code. No page may be authored from the agent's training data alone. Writers must read the relevant source files before writing.
- **No placeholder pages.** Pages are only created for capabilities that actually exist in the source code. No speculative content, no pages for hypothetical features, no stubs.
- **Audience and tone are honored throughout.** Every page respects the `audience` and `tone` values from the workspace config. These are immutable (set during UC-05, changed only by `/down` then `/up`).
- **Wiki structure requires user approval.** The planning agent proposes a wiki structure. The user refines it through iterative conversation until satisfied. No pages are written until the user approves the plan. An agent that writes pages without user approval has violated this invariant.
- **Repo freshness is the user's responsibility.** The system does not pull or verify that the source clone is up to date. The user is responsible for ensuring the workspace reflects the state they want documented.

## Success outcome

- The wiki directory contains a complete set of documentation pages covering the source project -- Home.md, _Sidebar.md, and all topic pages from the approved plan.
- Every page accurately reflects the source code, written for the configured audience and tone.
- _Sidebar.md provides navigation organized by section, linking to all pages.
- The user sees a summary of what was created: pages organized by section, the wiki structure, and suggested next steps.

## Failure outcome

- If failure occurs before writing begins (workspace resolution, validation, exploration, planning), no wiki pages are written. The wiki directory remains in its original state.
- If failure occurs during writing (one or more writer agents fail), successfully written pages remain on disk. The user is told which pages were written and which failed. The wiki is in a partial state.
- In all cases, the user is told what failed and what to do about it.

## Scenario

1. **User** -- Initiates wiki population by running `/init-wiki`.
2. **Orchestrator** -- Resolves the workspace and loads config (repo identity, source dir, wiki dir, audience, tone).
3. **Orchestrator** -- Confirms the wiki is brand new -- no content pages exist in the wiki directory. Structural files (Home.md, _Sidebar.md, _Footer.md) are ignored.
4. **Orchestrator** -- Absorbs editorial context: reads guidance files and the target project's CLAUDE.md if it exists.
5. **Orchestrator** -- Dispatches explorer agents to comprehend the source code from distinct angles.
6. **Explorer agents** -- Each reads the source code thoroughly and produces a structured report covering its assigned facet.
7. **Orchestrator** -- Collects all exploration reports.
8. **Planning agent** -- Synthesizes the exploration reports into a proposed wiki structure: sections containing pages, each with filename, title, description, and key source files.
9. **User** -- Reviews the proposed wiki structure and refines it through conversation with the orchestrator. Pages are added, removed, or reorganized until the user is satisfied with the plan.
10. **Orchestrator** -- Dispatches writer agents, one per approved page (excluding _Sidebar.md), each receiving its page assignment, key source file references, audience, tone, and editorial guidance.
11. **Writer agents** -- Each reads the assigned source files and writes one wiki page to disk.
12. **Orchestrator** -- Collects all writer results, writes _Sidebar.md with navigation reflecting the approved section structure, and confirms all approved pages are on disk.
    --> WikiPopulated
13. **User** -- Sees a summary: pages created organized by section, wiki structure, and suggested next steps (review pages for accuracy, run `/proofread-wiki` for editorial review, run `/save` to publish). The summary notes that content accuracy has not been independently verified.

## Goal obstacles

### Step 2a -- No workspace exists

1. **Orchestrator** -- Reports that no workspace exists and directs the user to run `/up` first.
2. **Orchestrator** -- Stops.

### Step 2b -- Workspace not found for the given identifier

1. **Orchestrator** -- Reports that no workspace matches the provided identifier and lists available workspaces.
2. **Orchestrator** -- Stops.

### Step 3a -- Wiki already has content

The wiki directory contains pages beyond structural files. This is not a new wiki.

1. **Orchestrator** -- Reports that the wiki already has content. Directs the user to `/refresh-wiki` for updating existing pages, or to clear the wiki directory manually and retry `/init-wiki`.
2. **Orchestrator** -- Stops. No content is deleted -- the user owns destructive actions.

### Step 5a -- One or more explorer agents fail

One or more explorer agents fail to produce a report (crash, timeout, or unusable results).

1. **Orchestrator** -- Reports which explorers failed and which facets of the source code were not examined.
2. **Orchestrator** -- Proceeds with the reports that succeeded. The gaps are visible to the user during plan approval (step 9), where they can account for missing coverage by adjusting the plan.

### Step 8a -- Planning agent fails

The planning agent cannot synthesize the exploration reports into a coherent wiki structure.

1. **Orchestrator** -- Reports the planning failure.
2. **Orchestrator** -- Stops. The user retries `/init-wiki`.

### Step 11a -- One or more writer agents fail

One or more writer agents fail to write their assigned page. Successfully written pages remain on disk.

1. **Orchestrator** -- Reports which pages were written successfully and which failed.
2. **Orchestrator** -- Writes _Sidebar.md reflecting only the pages that were successfully written.
3. **User** -- Is left with a partial wiki. Recovery options: manually delete the partial content and retry `/init-wiki`, or work with the partial wiki and use `/refresh-wiki` to update what exists.

## Domain events

- **WikiPopulated** -- The wiki directory has been populated with a complete set of documentation pages from an approved plan. This is the foundational event in the Wiki Creation bounded context. After this event, the wiki is ready for review (UC-02) and publishing (`/save`). Carries: repo identity, list of sections with their pages (hierarchical structure matching _Sidebar.md), audience, tone, and wiki directory path.

## Protocols

- **workspace.config.yml** -- step 2, input. The workspace config provides repo identity, source dir, wiki dir, audience, and tone. This is the contract defined in UC-05.
- **Explorer report** -- step 6, output from each explorer agent. A structured report covering one facet of the source code (architecture, public API, configuration, features, or examples). Includes specific file paths and line numbers. Consumed by the planning agent in step 8.
- **Wiki plan** -- step 8, output from the planning agent. A hierarchical structure of sections containing pages, each with filename, title, description, and key source files. Presented to the user for approval in step 9. Consumed by the orchestrator to dispatch writers in step 10.
- **Writer assignment** -- step 10, input to each writer agent. Contains: page file path, title, description, key source files to read, audience, tone, and editorial guidance. One assignment per writer agent.

## Notes

- **Accuracy is UC-02's concern.** UC-01 populates the wiki. UC-02 verifies its quality. The writer's production drive is insufficient to guarantee accuracy on its own. The summary step (step 13) explicitly notes that accuracy has not been independently verified, directing the user toward `/proofread-wiki`.
- **Context absorption belongs here.** Reading the target project's CLAUDE.md and editorial guidance is an editorial concern, not a workspace lifecycle concern. UC-05 (Provision Workspace) explicitly defers this to UC-01 and other editorial use cases. The orchestrator absorbs this context in step 4 and distributes it to downstream agents.
- **Plan approval is iterative, not one-shot.** The user and orchestrator work together to refine the wiki structure through conversation until the user is satisfied. This is closer to pair design than a confirm/reject gate.
- **Implementation note: AskUserQuestion may be too limited.** The current command file uses `AskUserQuestion` for plan approval, which presents options rather than enabling free-form conversation. This may be insufficient for the iterative design conversation envisioned in step 9. Acceptable as a first pass for MVP, but a richer interaction pattern may be needed.
- **Partial completion creates a design gap.** If writer agents partially fail (step 11a), the wiki has some content but not all. The user cannot re-run `/init-wiki` because the "new wikis only" invariant blocks it. A future use case for interactive wiki refactoring would address this gap. For now, the user's options are to manually clear the wiki directory and retry, or to work with the partial content.
- **Audience and tone design tension.** The current model treats audience and tone as single values for the entire wiki. Different sections may warrant different audiences (e.g., library users vs. repository contributors). Noted as a future design consideration -- for now, the single-value model holds.
- **Relationship to other use cases:** UC-01 requires UC-05 (Provision Workspace) as a prerequisite. Its output feeds UC-02 (Review Wiki Quality) and UC-04 (Sync Wiki with Source Changes). It has no dependency on UC-03 (Resolve Documentation Issues) or UC-06 (Decommission Workspace).
