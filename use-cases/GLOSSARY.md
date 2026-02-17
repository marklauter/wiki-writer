# Glossary

Every term that has precise meaning within the use case model. If a word means something specific here -- and especially if it means something different from its everyday usage -- it belongs in this list. Bounded contexts have their own ubiquitous language (defined in their [DC files](domains/)); this glossary captures terms that span the model or deliberately narrow common meaning.

Each entry is one sentence. If a term needs a paragraph, it belongs in [PHILOSOPHY.md](meta/PHILOSOPHY.md) or its own artifact.

---

**Actor** -- An entity with a goal or drive that participates in use cases; not a tool (`grep` has no drive), not a role description, but a modeled participant whose behavioral tendencies are predictable.

**Assessor** -- Abstract actor archetype whose defining trait is read-only judgment: receives an assignment, applies judgment, produces structured output, and never modifies wiki content or source material.

**Audience** -- The intended readership for the wiki, configured per workspace (e.g., ".NET developers integrating the library") and honored by every actor that produces or evaluates content.

**Bounded context** -- A region of the domain with its own ubiquitous language and its own rules; the same word can mean different things in different contexts (e.g., "correction" in DC-03 vs. DC-04).

**Claim** -- A factual assertion in a wiki page that can be verified against a source of truth; the atomic unit that fact-checkers assess as verified, inaccurate, or unverifiable.

**Commands do not chain** -- Cross-cutting invariant: each command (`/up`, `/down`, `/init-wiki`, etc.) is self-contained and never invokes another command.

**Content Mutator** -- Abstract actor archetype whose defining trait is wiki write permission; children are creators and correctors, distinguished by the nature of their judgment.

**Content page** -- A wiki page that is not a structural file; the unit of editorial work in UC-02, UC-03, and UC-04.

**Correction assignment** -- The input to a corrector: page path, finding, recommendation, and source reference; structurally compatible between DC-03 and DC-04, enabling corrector reuse.

**Deduplication** -- Comparing new findings against existing open GitHub issues labeled `documentation` to prevent filing duplicates; only drops a finding when it clearly matches an existing open issue about the same problem.

**Domain event** -- A meaningful state transition that crosses a bounded context boundary or is exposed to the user as an observable outcome; named, defined, and cataloged in [DOMAIN-EVENTS.md](domains/DOMAIN-EVENTS.md).

**Drift** -- A factual claim in the wiki that no longer matches its source of truth; the core domain problem the system exists to solve.

**Drive** -- The behavioral tendency an actor optimizes for (e.g., production, critique, verification, remediation); drives are what make actors predictable and what reveal where they fall short.

**Editorial context** -- The combined guidance that shapes content production and evaluation: editorial guidance, wiki instructions, and the target project's CLAUDE.md if it exists.

**Editorial lens** -- A distinct editorial discipline applied to wiki content during review; four lenses exist -- structure (organization, flow, gaps), line (sentence-level clarity), copy (grammar, formatting, terminology), and accuracy (claims verified against source code).

**End goal** -- In Cooper's hierarchy, what the actor wants to accomplish in a specific use case (e.g., "populate a new wiki with complete documentation grounded in source code").

**Errata** -- The section of a sync report listing claims that could not be verified because their source of truth was unreachable.

**Experience goal** -- In Cooper's hierarchy, how the actor wants to feel while using the system (e.g., "feel confident that the wiki accurately represents the source code").

**Exploration report** -- A structured summary of one facet of the source code (API surface, architecture, configuration, etc.), produced by a researcher and consumed by the developmental editor (UC-01) or proofreaders (UC-02).

**Fact-checker assessment** -- A structured report for one wiki page listing every factual claim checked, with verdict (verified, inaccurate, or unverifiable), quoted text, correct fact, and source reference.

**Finding** -- A specific documentation problem identified by a proofreader, with quoted problematic text, a recommendation, and (for accuracy findings) a source file citation.

**Goal** -- The desired end state an actor pursues; includes its constraints (safety, accuracy) as intrinsic, not bolted-on preconditions.

**Goal obstacle** -- A condition that threatens goal satisfaction during a scenario; framed as a threat to the goal with a recovery strategy, not as an error code or exception.

**Internal event** -- A coordination event consumed only within a single use case (e.g., IssueIdentified, DriftDetected); not cataloged in DOMAIN-EVENTS.md.

**Invariant** -- A domain rule that must hold continuously -- before, during, and after execution; not an entry gate checked once.

**Life goal** -- In Cooper's hierarchy, who the actor wants to be (e.g., "a responsible steward of project documentation").

**Local fallback** -- Markdown files written to `workspace/artifacts/{owner}/{repo}/reports/review-fallback/{date-time}/` when GitHub is unreachable during UC-02; preserves findings outside both clones.

**No CLI-style flags** -- Cross-cutting invariant: commands are agent interactions, not C programs; confirmation and disambiguation happen through conversation, not `--force` or `--all`.

**Orchestrator** -- Abstract parent for the four coordinating actors in editorial use cases; each child has a distinct drive — commissioning (UC-01), oversight (UC-02), fulfillment (UC-03), alignment (UC-04) — but shares the same mechanics: workspace resolution, editorial context absorption, dispatch, result collection, and summary presentation.

**Commissioning orchestrator** -- The orchestrator in UC-01; drive is commissioning; named for the *commissioning editor* who identifies what content is needed, recruits authors, and shepherds manuscripts to completion.

**Oversight orchestrator** -- The orchestrator in UC-02; drive is oversight; named for the *managing editor* who runs the editorial quality process and ensures standards are met.

**Fulfillment orchestrator** -- The orchestrator in UC-03; drive is fulfillment; named for the *production editor* who manages the flow of corrections through the production pipeline.

**Alignment orchestrator** -- The orchestrator in UC-04; drive is alignment; named for the *revisions editor* who manages the process of updating existing content to reflect new information.

**Primary actor** -- The actor who pursues the goal of a use case; in this system, always the User; framed using Cooper's goal hierarchy (life, experience, end goals).

**Proofread cache** -- Ephemeral storage (`workspace/artifacts/{owner}/{repo}/.proofread/`) for coordinating actors during a single UC-02 review run; created at start, cleaned up at end.

**Protocol** -- An actor boundary contract defining the input, output, and ownership at every crossing point between actors or between an actor and a sub-system.

**Published language** -- The integration contract between bounded contexts; in this system, the GitHub issue body conforming to `documentation-issue.md` is the published language between DC-02 (Editorial Review) and DC-03 (Wiki Revision).

**Remediation** -- The drive of applying known corrections to known problems; distinguished from revision (the use case of revising wiki content from issue findings) and from creation (producing new content).

**Safety check** -- Inspection of the wiki working tree for uncommitted changes and unpushed commits before decommissioning (UC-06); the gate that prevents silent destruction of unpublished work.

**Scenario** -- The sequence of steps through which actors pursue a goal; steps express intent and outcomes, not mechanics.

**Scripts own deterministic behavior** -- Cross-cutting invariant: all deterministic operations (git, gh, filesystem) belong in `.scripts/`; the LLM handles judgment only.

**Severity** -- Classification of a finding: must-fix or suggestion.

**Skip reason** -- Why a corrector could not apply a recommendation: quoted text no longer exists, recommendation is ambiguous, recommendation contradicts source code.

**Source clone** -- A readonly clone of the source repository used as reference material; never staged, committed, or pushed to.

**Source of truth** -- The authoritative reference for a factual claim; may be source code, an external URL, a linked specification, or other referenced material.

**Structural file** -- A wiki file prefixed with `_` (e.g., `_Sidebar.md`, `_Footer.md`) or `Home.md`; not counted as content pages for the "new wikis only" invariant.

**Sub-system** -- An infrastructure component the system depends on that has no drives and makes no decisions (e.g., GitHub, Git); not an actor.

**Supporting actor** -- An actor that participates in a use case in service of the primary actor's goal; has a drive, not a goal of its own.

**Sync report** -- A durable, time-stamped markdown file at `workspace/artifacts/{owner}/{repo}/reports/sync/{date-time}-sync-report.md` showing corrections applied, pages verified, and claims that could not be checked; reports accumulate across runs.

**Targeted edit** -- A surgical change to a specific section of a wiki page, preserving surrounding content; the required editing style for correctors in UC-03 and UC-04.

**Tone** -- The writing style for the wiki, configured per workspace (e.g., "reference-style", "tutorial-style") and honored by every actor that produces content.

**Type-to-confirm** -- The confirmation pattern for destructive actions: the user types the repository name to confirm deletion when unsaved changes exist (UC-06); replaces `--force` flags.

**Ubiquitous language** -- Terms that have precise meaning within a single bounded context; defined in each DC file.

**Use case** -- A description of one goal pursued by one primary actor, including the conditions under which that goal is achieved, threatened, or failed; not a feature spec, user story, or task list.

**Wiki clone** -- A clone of the wiki repository; the mutable working copy for all editorial operations.

**Wiki plan** -- A hierarchical structure of sections containing pages, each with filename, title, description, and key source files; proposed by the developmental editor, refined and approved by the user before writing begins (UC-01).

**Workspace** -- The configuration, source clone, and wiki clone for one GitHub project; defined by the existence of a `workspace.config.md` file.

**Workspace config** -- The `workspace.config.md` file containing repo identity, source dir, wiki dir, audience, and tone; the contract between Workspace Lifecycle and all other bounded contexts.

**Workspace selection** -- The shared protocol every use case (except UC-05) executes to resolve which workspace to operate on; implemented by `resolve-workspace.sh`.

**Writing assignment** -- The input to a creator in UC-01: page file path, title, description, key source files, audience, tone, and editorial guidance.
