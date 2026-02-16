# Design conversations

Detailed record of key design discussions from the UC-01/02/03 session (2026-02-16). These conversations shaped PHILOSOPHY.md and informed all use case decisions.

## The elevator conversation — actors, drives, and separation

### Context

We were starting UC-01 (Populate New Wiki). The use-case-designer agent asked: "Who is the primary actor? The User, or the Orchestrator?" This triggered a foundational discussion about what an actor is when AI agents are involved.

### The user's classical position

The user has a background teaching use case design. Their sample domain was the elevator system. In their belief system, an actor is a sentient being with goals and responsibilities. This belief predates AI agents.

Their elevator actor taxonomy:

- **rider** — the general case
- **rider <- first-responder** — emergency access specialization
- **rider <- handicapped person** — accessibility specialization
- **rider <- hotel guest** — evening elevators go to their floor
- **rider <- office worker** — morning elevators go to their floor
- **operator** — runs the system day-to-day
- **maintainer** — repairs and upkeep
- **owner** — pays for the system
- **inspector** — government safety oversight

Common student mistakes: identifying floors as actors, or the elevator itself as an actor. These are wrong because floors have no goals, and the elevator is the system under design, not an actor using it.

The test for actor-hood: does this entity have a goal it's pursuing, and does it make decisions in service of that goal?

### Goal completeness — "arrive safely"

The user corrected an incomplete goal formulation. "Get to floor 12" is a task description, not a goal. The real goal is "arrive at another floor safely." Safety is not a nice-to-have bolted on afterward — it is part of what the rider wants. If the elevator rips the rider's arm off on the way to floor 12, the goal was not satisfied.

This principle — that goals include their constraints — was added to PHILOSOPHY.md under "Goals over tasks."

### Goal conflicts spawn actors

The user explained that the conflict of interest between the owner (who has to pay for repairs) and the general public's desire for safety is what spawns the government inspector actor. The inspector doesn't exist because inspecting is inherently interesting. The inspector exists because the owner's incentives alone won't protect the rider. Actors emerge from goal tensions, not from job descriptions or org charts.

### The discovery of "drive"

While discussing how to model AI agents as actors, Claude used the word "drive" to describe what an agent naturally optimizes for:

- The writer agent's drive is *production* — fill pages with content
- The reviewer agent's drive is *critique* — find what's wrong

The user identified this as a key concept: "yes, you nailed it. and you also uncovered a key concept: drive."

This led to the full framework:

**Classical actors** have drives rooted in human motivation:
- Rider's drive: self-interest (arrive safely)
- Owner's drive: economic (minimize cost)
- Inspector's drive: institutional (protect public safety)

**AI agents** have drives rooted in behavioral tendency:
- Explorer's drive: comprehension (understand thoroughly)
- Writer's drive: production (fill pages with content)
- Reviewer's drive: critique (find what's wrong)
- Deduplicator's drive: filtering (prevent duplicates)
- Fixer's drive: remediation (apply known fixes)

**The bridge principle:** In both cases, drives are what make actors predictable. You know what an actor will optimize for, and therefore where it will fall short. A tool has no drive — `grep` does exactly what you tell it. An actor makes decisions shaped by what it cares about.

**The separation principle:** When a single drive cannot protect all the concerns at play, you need separate actors. The owner's cost-minimization drive is insufficient to protect public safety — so the inspector exists. The writer's production drive is insufficient to guarantee accuracy — so the reviewer exists. Not malice, but insufficiency.

This became three new sections in PHILOSOPHY.md: "Actors have drives," "Drives explain separation," and "Goal conflicts spawn actors."

### Application to UC-01

The immediate application: the User is the primary actor (drive: accurate documentation for their audience). The orchestrator, explorers, planning agent, and writers are supporting actors — they have drives but those drives serve the user's goal. Like a plumber you hire: real judgment, but serving your goal.

The writer's production drive being insufficient to guarantee accuracy is exactly why UC-02 (Review Wiki Quality) exists as a separate use case with a separate critique drive. This was stated in UC-01's agent responsibilities section and noted in its summary step.

## Minor unwritten nuances

These decisions were made during the session but may not be fully captured in the use case files themselves.

### Audience and tone may need per-section values

Currently, `audience` and `tone` are single values in `workspace.config.yml`, set during `/up`. During UC-01 design, the user noted that different sections of a wiki may have different audiences — for example, library users vs. repository contributors. This is noted as a design tension in UC-01 but hasn't been formally addressed. A future refactoring of the config schema may be needed.

### GitHub is a sub-system, not an external dependency

During UC-02 design, we established that GitHub is part of our system boundary, not an external service. GitHub Issues serves as the system's event queue / service bus. FindingFiled events are materialized as GitHub issues. This framing means:

- GitHub unreachability is a system degradation, not an external dependency failure
- Issues are durable facts within our system, not remote API responses
- The issue body protocol (`wiki-docs.yml`) is an internal contract, not an integration spec

This framing is captured in UC-02's notes but is a cross-cutting architectural decision that applies to all use cases.

### IssueToBeFiled reclassified from domain event to milestone

During UC-02 design, the deduplicator's output (IssueToBeFiled) was initially modeled as a domain event. On reflection, we reclassified it as a milestone — it's consumed only within the same use case (by the orchestrator's filing step) and nothing outside the scenario reacts to it. The test: does anything outside the scenario react to this fact? If not, it's a milestone, not a domain event.

### The `-plan` flag and scope selection removal

UC-03's command file supported `-plan` (preview without applying), issue number filters, and page name filters. These were removed from the use case because:

1. `-plan` violates "no CLI-style flags" (SHARED-INVARIANTS.md)
2. The user can preview by reading issues on GitHub directly
3. Scope narrowing, if ever needed, should happen through conversation, not arguments
4. The user said the plan flag "was a bad idea anyway"

The same reasoning led to removing `--pass` from UC-02.

### Remediation vs. resolution — why naming matters

UC-03's drive is *remediation* (applying fixes), not *resolution* (closing tickets). The user explained: "it's common to say 'resolve issues' but that puts the emphasis on closing issues rather than on applying actionable recommendations." An agent optimizing for resolution would be tempted to close issues without fixing them. An agent optimizing for remediation applies the fix and lets closure follow naturally. The command is still called `/resolve-issues` for discoverability, but the use case goal is wiki correction.

### Editorial lens terminology

"Pass" was replaced by "editorial lens" across the system because:

1. "Pass" implies serial execution — first pass, second pass
2. These are parallel editorial disciplines, like a human editing department
3. Each lens has its own drive and input requirements
4. The four lenses (structure, line, copy, accuracy) map to distinct editorial disciplines

Updated files: `wiki-docs.yml` (field id and label), `README.md` (command documentation), UC-02 (throughout). The proofread command file still uses old terminology — flagged as implementation gap.

### Dispatch pattern for editorial lenses

The dispatch model (how many agents, per-page vs. multi-page) depends on the lens and even on sub-concerns within a lens:

- **Accuracy** — per-page parallel. Needs source code access, which fills context window.
- **Copy** — hybrid. Grammar/formatting per-page, but terminology consistency needs cross-page visibility.
- **Structure** — multi-page. Must see the whole wiki for organization/flow/gaps.
- **Line** — per-page parallel. Sentence-level work is page-local.

The use case specifies *input requirements* per lens (domain constraint), not *dispatch pattern* (implementation). This was a deliberate decision: "intent over mechanics."

### `needs-clarification` as a GitHub label

When UC-03's fixer skips an issue because the recommendation is ambiguous, the orchestrator adds a `needs-clarification` label to the GitHub issue (in addition to commenting). This makes ambiguous issues filterable/queryable. The current `close-issue.sh` script doesn't support adding labels — flagged as implementation gap.

### Explorer agents appear in multiple use cases

UC-01 has explorers (for wiki planning), UC-02 has explorers (for review context). If the user runs init then proofread, the source gets explored twice. The explorations serve different purposes, so this is probably fine. But if UC-04 also needs explorers, we might want shared exploration artifacts. Noted as a pattern to watch.
