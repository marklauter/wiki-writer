# Use case model phases

How a use case model comes into existence. These phases are sequential in the sense that each builds on the previous — but the process is not a waterfall. Discovery at any phase can send you back to revise earlier work. A use case designed in phase 2 may reveal a new principle for phase 1, a shared invariant for phase 3, or an entirely new use case you hadn't considered.

The phases describe a *tendency*, not a procedure. Early work tends to be philosophical. Middle work tends to be individual use cases. Late work tends to be consolidation and refinement. But you will find yourself doing all of these simultaneously, and that is correct.

See [USE-CASE-MODEL-ARTIFACTS.md](USE-CASE-MODEL-ARTIFACTS.md) for what each artifact contains and why it exists.

---

## Phase 1: Establish principles

**Produce:** PHILOSOPHY.md, TEMPLATE.md (initial draft)

Before designing the first use case, write down what you believe. Not about the domain — about modeling itself. How do you think about actors? What makes a good goal statement? Where do invariants belong? What level of abstraction do scenario steps operate at?

These beliefs may be inherited from a methodology (Cockburn, Cooper, Evans) or discovered through practice. Either way, write them down. They are the constitution that the rest of the model must obey. When a use case contradicts the philosophy, one of them is wrong — resolve it.

The template follows from the philosophy. If you believe goals come before tasks, the template puts Goal before Scenario. The template is the philosophy made structural.

**What triggers backtracking here:** A use case that doesn't fit the template. A principle that turns out to be wrong. A new belief discovered during interviews ("actors have drives" emerged mid-process, not at the start).

---

## Phase 2: Design individual use cases

**Produce:** UC-{id}-{slug}.md (one at a time), ACTOR-CATALOG.md (started), SHARED-INVARIANTS.md (started)

This is the core of the work. Each use case is designed through a Socratic interview — goal discovery, invariants, domain events, scenario, obstacles, grounding against reality. One use case at a time. Do not batch them.

The first use case takes the longest. It establishes vocabulary, discovers the first actors, surfaces the first invariants, and tests the template. By the third use case, the domain language is settling and interviews go faster because both the designer and the domain expert share a working vocabulary.

**What to expect during this phase:**

- **Actors accumulate.** The first use case introduces the primary actor and a few supporting actors. Each subsequent use case may introduce new actors, reuse existing ones, or reveal that what you thought was one actor is actually two (because their drives conflict).

- **Invariants migrate.** A constraint stated in one use case turns out to apply to another. Extract it to SHARED-INVARIANTS.md the second time it appears.

- **New use cases are discovered.** Designing UC-01 may reveal a gap that requires UC-08. Stub it and move on — do not design it now unless it blocks the current use case.

- **The philosophy grows.** Interviews surface beliefs you hadn't articulated. "Drives explain separation" may not exist until the third interview, when you realize why the reviewer exists separate from the writer. Add it to PHILOSOPHY.md.

- **Protocols emerge at boundaries.** When two use cases share information (one produces, the other consumes), the handshake becomes a protocol. Define it in the producer's Protocols section and reference it from the consumer.

**Ordering heuristic:** Start with the use case that best represents the core domain problem. This is usually the one the user cares most about, not the one that's technically simplest. Workspace provisioning may be simpler, but wiki creation or editorial review is where the domain lives.

**What triggers backtracking here:** An actor redefined in a later use case that invalidates an earlier one. A shared invariant that changes the scenario of a previously designed use case. A protocol that doesn't fit the consumer's needs.

---

## Phase 3: Consolidate

**Produce:** ACTOR-CATALOG.md (complete), SHARED-INVARIANTS.md (complete), USE-CASE-CATALOG.md

After several use cases exist, step back and consolidate. The goal is DRY — no actor defined in two places, no invariant restated across use cases, no protocol described differently by producer and consumer.

**Actor catalog:** Gather every actor from every use case into one document. Define goals (primary actors) and drives (supporting actors). Build the appearance matrix. Look for actors that appear under different names in different use cases — they are probably the same actor, and the name needs to settle.

**Shared invariants:** Scan all use cases for repeated constraints. Extract them. Replace the duplicates with references. Define shared protocols (workspace selection, config schema) that multiple use cases depend on.

**Use case catalog:** Write the index. Frame the primary actor's goals, describe the domain, list all use cases, and provide the bounded contexts table (even if bounded contexts aren't formalized yet — informal groupings are fine at this stage).

**What triggers backtracking here:** Consolidation reveals inconsistencies. Two use cases describe the same actor with different drives. A shared invariant contradicts a use case's local invariant. The catalog reveals a gap — a goal that no use case addresses.

---

## Phase 4: Model the domain

**Produce:** domains/DC-{id}-{slug}.md, domains/DOMAIN-EVENTS.md

Bounded contexts and domain events become visible after multiple use cases exist. This phase formalizes what was implicit — the natural clustering of use cases, the language boundaries between them, and the events that cross those boundaries.

**Bounded contexts:** Each context gets its own file. Define the purpose, the ubiquitous language (terms that have precise meaning within this context), the use cases that live here, the domain events produced and consumed, and the integration points with other contexts. Pay attention to terms that mean different things in different contexts — that's a boundary.

**Domain events:** Extract events that cross bounded context boundaries or are exposed to the user. Catalog them with producer, consumer, materialization, and payload. Internal coordination events (consumed only within a single use case) stay in their use case — they are not domain events.

**Update use cases:** Replace informal references ("this produces a finding that UC-03 consumes") with formal references to domain context IDs and domain event IDs. Update the use case catalog's bounded contexts table.

**What triggers backtracking here:** A domain event that doesn't fit any bounded context. A bounded context that contains use cases with conflicting language. An integration point that reveals a missing protocol.

---

## Phase 5: Refine

**Produce:** Revisions to all artifacts. Implementation gap documentation.

The model exists. Now make it consistent, precise, and honest about its gaps.

**Remove implementation leaks.** Scenario steps should express intent, not mechanics. If a step says "writes to `workspace/artifacts/{owner}/{repo}/.proofread/findings-{page}.md`," it has leaked implementation into the model. Rewrite it to express what is accomplished. Move the implementation detail to a Notes section.

**Reconcile with reality.** If an implementation already exists, compare it to the model. Document every divergence as an implementation gap in the relevant use case's Notes section. The model is the source of truth — the implementation needs to catch up, not the other way around.

**Verify cross-references.** Every domain event referenced in a use case should exist in DOMAIN-EVENTS.md. Every bounded context referenced should have a file. Every actor should appear in the catalog. Every shared invariant referenced should exist in SHARED-INVARIANTS.md. Broken references mean something was renamed or removed without updating dependents.

**Check the philosophy.** Re-read PHILOSOPHY.md with fresh eyes. Does every use case still reflect every principle? If a principle was violated and nobody noticed, either the principle is wrong or the use case needs revision.

**What triggers backtracking here:** Everything. Refinement is where you discover that a decision made in phase 2 doesn't hold under scrutiny. That an actor's drive was mislabeled. That a domain event was misclassified as internal when it actually crosses a boundary. This is normal — refinement is not a sign that earlier phases were done poorly. It is a sign that understanding has deepened.

---

## On backtracking

The phases are numbered for exposition, not for compliance. In practice:

- Phase 2 will send you back to phase 1 repeatedly. The philosophy is not complete until the model is complete.
- Phase 3 will send you back to phase 2 to reconcile use cases that consolidated poorly.
- Phase 4 will send you back to phase 3 when bounded contexts reveal that shared invariants were scoped wrong.
- Phase 5 will send you back to anywhere.

This is not a deficiency of the process. It is the process. A use case model is discovered, not constructed. Each phase deepens understanding, and deeper understanding revises earlier assumptions.

The only rule: when you go back, update the artifact. Do not leave stale assumptions in place because they were written first. The model must be internally consistent at all times, even if that means rewriting something you thought was finished.
