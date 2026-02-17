# Use case model artifacts

A guide to the artifacts that constitute a viable use case model. Each artifact has a purpose, a relationship to other artifacts, and a point in the process where it typically emerges. "Typically" is doing work in that sentence — discovery is non-linear and artifacts evolve as understanding deepens.

This document describes *what* to produce. See [USE-CASE-PHASES.md](USE-CASE-PHASES.md) for *when* and *how*.

---

## Philosophy

**File:** `PHILOSOPHY.md`

The constitution of the model. Guiding principles that every other artifact must reflect. Not project-specific rules — foundational beliefs about how actors, goals, invariants, events, and scenarios should be modeled.

A philosophy document is short, opinionated, and stable. It changes rarely — when a principle is discovered to be wrong or incomplete, not when a new use case is added. If you find yourself wanting to add a principle for every use case, you are writing invariants, not philosophy.

**Emerges:** First. Write it before the first use case, even if it's only two principles. It will grow as the modeling process reveals what you believe.

**Example principles:** "Actors have drives." "Goals over tasks." "Intent over mechanics." "Extract, don't invent."

---

## Template

**File:** `TEMPLATE.md`

The structural contract for individual use cases. Every use case follows this template exactly — same sections, same ordering, same voice. Consistency across use cases is what makes the model navigable.

The template encodes the philosophy into structure. If the philosophy says "goals over tasks," the template puts Goal before Scenario. If the philosophy says "obstacles over exceptions," the template has a Goal Obstacles section, not an Error Handling section.

**Emerges:** Early. Draft it before or alongside the first use case. Refine it after the second or third use case reveals what's missing.

**Sections (typical):** Goal, Context, Agent responsibilities, Invariants, Success outcome, Failure outcome, Scenario, Goal obstacles, Domain events, Protocols, Notes.

---

## Individual use cases

**Files:** `UC-{id}-{slug}.md`

The core of the model. Each use case describes one goal pursued by one primary actor. It is a self-contained document — a reader should understand the goal, constraints, happy path, failure modes, and integration points without reading any other use case.

A use case is not a feature spec, a user story, or a task list. It describes a desired end state and the conditions under which that state is achieved, threatened, or failed. Implementation details belong in notes or downstream artifacts, not in scenario steps.

**Emerges:** Iteratively, through Socratic interviews. Each use case is designed one at a time. The first use case takes the longest because it establishes vocabulary. Later use cases go faster because the domain language is settling.

**Relationships:** Use cases reference shared invariants, domain contexts, domain events, and other use cases (as prerequisites or consumers). They do not duplicate information that belongs in shared artifacts.

---

## Actor catalog

**File:** `ACTOR-CATALOG.md`

A single document that defines every actor in the system — who they are, what drives them, and where they appear. Primary actors have goals (framed using Cooper's hierarchy: life goals, experience goals, end goals). Supporting actors have drives — behavioral tendencies that determine what they optimize for.

The catalog also defines sub-systems — infrastructure components that the system depends on but that have no drives and make no decisions.

The appearance matrix shows which actors participate in which use cases, making it easy to see coverage gaps and actor reuse.

**Emerges:** After the first two or three use cases, when actors start repeating and the need for a consolidated view becomes obvious. Updated every time a new use case introduces or redefines an actor.

**Key elements:** Actor name, role, drive (or goal for primary actors), agent type (for AI agents), appearance list, separation rationale.

---

## Shared invariants

**File:** `SHARED-INVARIANTS.md`

Cross-cutting rules that apply to every use case in the system. Individual use cases reference this document rather than restating these invariants. If the same constraint appears in three use cases, it belongs here.

This document also defines shared protocols — workspace selection, config file schema, and any other contract that multiple use cases depend on.

**Emerges:** After the second or third use case, when you notice the same invariant written in two places. Extract it, name it, and replace the duplicates with references.

**Distinction:** An invariant in a use case is local to that use case. An invariant in SHARED-INVARIANTS.md applies system-wide. The bar for promoting an invariant is repetition — if it appears in more than one use case unchanged, it is shared.

---

## Use case catalog

**File:** `USE-CASE-CATALOG.md`

The index. Frames the primary actor's goals, describes the domain, lists all use cases with one-line summaries, and provides a bounded contexts table showing which use cases and domain events belong to which context.

This is the entry point for someone new to the model. It answers: who is this for, what problem does it solve, and what are the pieces.

**Emerges:** After the first use case exists. Start simple — a list of use cases. It grows into a richer document as bounded contexts and domain events are identified.

**Maintenance:** Update it every time a use case, bounded context, or domain event is added or removed. It must stay current — a stale catalog is worse than no catalog.

---

## Domain contexts

**Files:** `domains/DC-{id}-{slug}.md`

Each bounded context gets its own file defining its purpose, ubiquitous language, use cases, domain events produced and consumed, and integration points with other contexts.

A bounded context is not a module or a folder — it is a region of the domain with its own language and its own rules. The same word can mean different things in different contexts. A "correction" in Wiki Revision is an applied fix from a GitHub issue. A "correction" in Drift Detection is an applied fix from a fact-checker assessment. The correction assignment protocol is structurally compatible, but the contexts are separate.

**Emerges:** Late. Bounded contexts become visible after several use cases reveal natural clustering. You may name them informally during early use cases ("this lives in the editorial review area") and formalize them later.

**Key elements:** Purpose, ubiquitous language (domain-specific terms defined precisely), use case references, domain events produced/consumed, integration points (requires, feeds, shares with, gaps).

---

## Domain events catalog

**File:** `domains/DOMAIN-EVENTS.md`

A single document defining every domain event that crosses a bounded context boundary or is exposed to the user as an observable outcome. Internal coordination events (those consumed only within a single use case) stay defined in their use case.

Each event has a bounded context, producer, consumer(s), materialization (how it becomes observable — a file on disk, a GitHub issue, a summary), description, and payload.

**Emerges:** Late, alongside or after domain contexts. Events are first identified informally during use case design ("at this point, the wiki is populated — that's an event"). They are extracted and cataloged when the model is mature enough to distinguish published events from internal ones.

**Distinction:** A domain event crosses a boundary or is user-visible. An internal event is consumed only within one use case. Only domain events are cataloged here. Internal events remain in their use case's Domain Events section.

---

## Glossary

**File:** `GLOSSARY.md`

A single document defining every term that has precise meaning within the model. If a word means something specific — and especially if it means something different from its everyday usage — it belongs here.

The glossary is the shared vocabulary across the entire model. Bounded contexts have their own ubiquitous language (defined in their DC files), but the glossary captures terms that span the model: "drive," "invariant," "domain event," "bounded context," "editorial lens," "protocol." It also captures terms where the model's usage deliberately narrows or redirects common meaning — "actor" is not just "user," "obstacle" is not just "error."

A good glossary entry is one sentence. If it takes a paragraph, the term may need a philosophy principle or its own artifact, not a glossary entry.

**Emerges:** Gradually, starting in phase 2 when vocabulary begins to settle. Updated whenever a term is coined, redefined, or discovered to be ambiguous. The glossary is never "done" — it grows with the model.

**Maintenance:** When a term is renamed (e.g., "pass" to "editorial lens"), update the glossary and every artifact that uses the old term. The glossary is the canonical spelling.

---

## Design conversations

**File:** `design-conversations.md` (or similar)

An optional but valuable artifact that captures the reasoning behind non-obvious decisions — the "why" that doesn't fit in any single use case's Notes section. This is where you record the elevator discussions, the moments where a principle was discovered, the debates that resolved a naming conflict.

This document is append-only and informal. It is not part of the model's formal structure — it is the model's memory.

**Emerges:** Organically, whenever a design conversation produces insight that would be lost if not written down.

---

## Relationship map

How the artifacts reference each other:

```
PHILOSOPHY.md
  ↓ (principles encoded into)
TEMPLATE.md
  ↓ (structure followed by)
UC-{id}-{slug}.md ←→ UC-{id}-{slug}.md
  ↑ (references)        ↑ (references)
  │                      │
  ├─ SHARED-INVARIANTS.md (cross-cutting rules)
  ├─ domains/DC-{id}-{slug}.md (bounded context)
  └─ domains/DOMAIN-EVENTS.md (published events)

ACTOR-CATALOG.md ←── (consolidates actors from all UCs)
USE-CASE-CATALOG.md ←── (indexes everything)
GLOSSARY.md ←── (canonical vocabulary for all artifacts)
```

Every arrow is a reference, not a dependency. Any artifact can be read standalone — but the model is richer when read as a whole.
