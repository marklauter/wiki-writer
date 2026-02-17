# Agent creation principles

Guiding principles for implementing agents in this project. Every agent definition must reflect these ideas. This document bridges the use case model (see `use-cases/meta/PHILOSOPHY.md`) to Claude Code's extension layer.

## Drives become system prompts

An actor's drive is the core of its subagent system prompt. The creator's production drive, the proofreader's critique drive — these are behavioral orientations, not job descriptions. The prompt should make the agent *want* what its drive says it wants.

A system prompt that says "review this page for errors" describes a task. A system prompt that says "your job is to find what's wrong — every claim is suspect until verified against source code" embodies a drive. The first produces compliance. The second produces vigilance.

Write prompts that express the drive first, then scope the work.

## Tool restrictions enforce single responsibility

"Separate judgment from execution" is not advisory — it is structural. A researcher gets `Read, Grep, Glob` and no `Write` or `Edit`. A creator gets `Write` and `Edit`. The tool boundary is where drive separation becomes real.

If an agent can both assess and mutate, it will compromise between the two. Removing the mutation tools from an assessor doesn't limit it — it focuses it. The agent can only do what its drive demands.

Ask "what tools does this drive need?" not "what tools might be useful?"

## Orchestrators live in the main conversation

Orchestrators are not subagents. They *are* the session. They coordinate, delegate, synthesize. Subagents are the actors they dispatch. This maps to Claude Code's architecture: the main conversation manages context and user interaction, subagents run in isolation and return results.

The orchestrator's "prompt" is the command file — the skill or slash command that sets up the scenario and delegates. It reads config, absorbs context, decides what to dispatch, and synthesizes what comes back. It is the only actor that talks to the user.

## Agents, reference material, and skills are different things

Three categories, each with a distinct role:

- **Agents** embody drives. Their identity comes from the system prompt — what they care about, what they optimize for. An agent *is* an actor.
- **Reference material** informs agents. Editorial guidance is rules ("prefer active voice"). Wiki instructions are a map ("the sidebar lives here, pages follow this naming convention"). Project conventions are constraints. None of these are capabilities — they are context an agent reads to do its work. Reference material is preloaded into agents via the `skills:` field as a delivery mechanism, but it is not conceptually a skill.
- **Skills** are user-invocable workflows — the slash commands (`/init-wiki`, `/proofread-wiki`, `/save`). Each skill maps to a use case entry point. The user triggers them. The orchestrator executes them.

Two agents can share the same reference material and produce different outputs because their drives differ. The creator reading editorial guidance produces pages. The proofreader reading the same guidance produces findings. The material is the same. The drive determines what happens.

Do not duplicate reference material across system prompts. Load it via the `skills:` field.

## Hooks enforce invariants

Invariants are constraints that must hold continuously — before, during, and after execution. Hooks are deterministic, non-negotiable enforcement. They run outside the agentic loop. The LLM cannot override them, negotiate with them, or forget them.

Advisory rules go in system prompts. Hard rules go in hooks. "Prefer concise headings" is advisory. "Never write to the source repo" is an invariant — enforce it with a `PreToolUse` hook that blocks writes outside the wiki directory.

If a rule must hold with zero exceptions, it is a hook. If a rule requires judgment, it belongs in the system prompt.

## Scripts own deterministic behavior

Git operations, GitHub CLI calls, filesystem setup, config parsing — these are deterministic. They do not require judgment. They belong in shell scripts called via `Bash`, not in LLM reasoning.

The LLM decides *what* to do. The script does it reproducibly. A script that clones a repo will always clone a repo. An LLM that "clones a repo" might decide to do something creative instead.

Scripts live in `.scripts/`. They are tested, versioned, and predictable. Every `Bash` call an agent makes should invoke a script, not improvise a shell command.

## Model selection follows cognitive demand

Not every drive demands the same cognitive capability. Match the model to the kind of work, not the actor's importance.

| Cognitive demand | Examples | Model |
|-----------------|----------|-------|
| Mechanical — run scripts, file issues, move files | Script execution, issue creation, config parsing | Haiku |
| Coordination — delegate, relay, synthesize status | Orchestrators dispatching agents, relaying events | Sonnet |
| Knowledge work — comprehension, production, critique, decision-making | Researchers, creators, proofreaders, fact-checkers, developmental editors | Opus |

Haiku can operate scripts but cannot do knowledge work. It does not comprehend source code well enough to research, write, or assess. Sonnet can orchestrate workflows but does not produce content at the quality bar required for wiki pages or editorial findings. Opus is the floor for any agent whose drive involves reading, understanding, judging, or creating.

When in doubt, use Opus. A cheaper model that produces wrong output costs more in rework than the right model costs in tokens.

## Commands are use case entry points

Each slash command maps to exactly one use case. The command file is the orchestrator's implementation — it sets up the scenario, resolves the workspace, absorbs context, and delegates to subagents.

| Command | Use case |
|---------|----------|
| `/up` | UC-05 Provision Workspace |
| `/down` | UC-06 Decommission Workspace |
| `/init-wiki` | UC-01 Populate New Wiki |
| `/proofread-wiki` | UC-02 Review Wiki Quality |
| `/resolve-issues` | UC-03 Resolve Documentation Issues |
| `/refresh-wiki` | UC-04 Sync Wiki with Source Changes |
| `/save` | UC-07 Publish Wiki Changes |

A command that does two use cases' work has two responsibilities. Split it.

## Context isolation and structured messaging

Subagents do not share context with each other. A creator cannot see the proofreader's findings while writing. A researcher cannot see what another researcher found. This is correct — isolation prevents drives from contaminating each other.

But agents within a use case need to exchange information. This happens through the orchestrator, which is the only actor that sees all results and constructs all prompts. Communication follows two patterns:

**Process events** are intra-UC messages relayed by the orchestrator. When a researcher completes, it returns a structured report to the orchestrator. The orchestrator extracts the relevant content and includes it in the next agent's prompt — for example, passing a researcher's findings to a creator as input. The orchestrator is the relay. Process events are structured markdown constructed from templates so that every agent receives information in a predictable format. They do not persist beyond the session.

**Domain events** are inter-UC messages that persist as durable artifacts. A proofreader's findings become GitHub issues. A sync report becomes a file in `workspace/reports/`. These cross bounded context boundaries and outlive the session that produced them. They are consumed by different use cases at different times.

The distinction matters: process events are prompt context passed through the orchestrator. Domain events are artifacts written to disk or external systems. Never pass raw subagent output between agents — transform it into a structured event first. The template is the form. The filled-in content is the memo.

## Markdown is the wire format

Domain events, reports, protocols, and assessments are all materialized as markdown. Not JSON. Not YAML. Not structured tool output. The consumers are humans and LLM agents, and markdown is the format both read natively.

Subagent results return as markdown. Scripts produce markdown. Inter-agent communication is markdown files on disk. The integration layer is human-readable and LLM-readable by default.

This is a deliberate choice carried forward from the use case philosophy. A system whose integration points are optimized for human and AI consumption does not need a serialization layer between them.
