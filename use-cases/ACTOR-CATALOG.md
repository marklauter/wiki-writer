# Actor Catalog

Every actor that interacts with or operates within this system — who they are, what they want, and where they appear. Primary actors are framed using Alan Cooper's goal-oriented design: life goals (who they want to be), experience goals (how they want to feel), and end goals (what they want to accomplish). Supporting actors have *drives*: behavioral tendencies they optimize for in service of the primary actor's goals. A drive that is insufficient to protect a goal is why a separate actor exists. See [PHILOSOPHY.md](PHILOSOPHY.md) for the full treatment.

UC-07 (Publish Wiki Changes) is out of scope and excluded.

---

## Human actors

### User

- **Role:** Primary actor in every use case.
- **Appears in:** UC-01, UC-02, UC-03, UC-04, UC-05, UC-06

**Goals:**

- Provide software projects that are well-documented and trustworthy.
- Be a responsible steward of project documentation.

**Experience goals:**

- Feel confident that the wiki accurately represents the source code.
- Feel in control of what gets written and what gets published — no surprises from autonomous agents.
- Feel that the system respects their judgment: plan approval before content is written (UC-01), post-hoc review via git (UC-04), type-to-confirm before destructive actions (UC-06).
- Feel that their time is not wasted — summaries are actionable, failures are explained, next steps are clear.

**End goals:**

| UC | End goal |
|----|----------|
| UC-01 | Populate a new wiki with complete documentation grounded in source code. |
| UC-02 | Surface every real documentation problem as an actionable GitHub issue. |
| UC-03 | Apply recommended corrections so the wiki content is fixed. |
| UC-04 | Bring every factual claim in line with current sources of truth. |
| UC-05 | Set up a workspace so wiki operations can begin. |
| UC-06 | Remove a workspace cleanly, with no silent loss of unpublished work. |

---

## Agent actors

Agents appear only in the editorial use cases (UC-01 through UC-04). Each agent has a single drive — a behavioral tendency it optimizes for. Drives are not goals; they are what make agents predictable and what reveal where they fall short. When a single drive cannot protect the primary actor's goal, separate agents exist. See [PHILOSOPHY.md](PHILOSOPHY.md), "Drives explain separation."

Agents divide into two families defined by their relationship to wiki content — plus two that stand alone.

### Orchestrator

- **Drive:** Coordination.
- **Appears in:** UC-01 (`/init-wiki`), UC-02 (`/proofread-wiki`), UC-03 (`/resolve-issues`), UC-04 (`/refresh-wiki`)

Resolves the workspace, absorbs editorial context, dispatches other agents, collects results, and presents summaries. The orchestrator makes no editorial judgments — it delegates comprehension to explorers, synthesis to the planner, production to creators, critique to reviewers, and remediation to correctors. Each command instantiates an orchestrator for its bounded context.

### Planning agent

- **Drive:** Synthesis.
- **Agent type:** `general-purpose`
- **Appears in:** UC-01

Receives all exploration reports and produces a coherent wiki structure — sections containing pages, each with a filename, title, description, and key source files. Turns raw understanding into a structure that serves the audience. Does not write content; it organizes. The proposed structure requires user approval before any pages are written.

The planning agent reads reports and produces structured output like an assessor, but its output is a *plan*, not an *assessment*. Synthesis is categorically different from evaluation — it decides what *should* exist, not whether what exists is correct.

### «abstract» Assessor

Receives an assignment from the orchestrator. Reads inputs. Applies judgment to produce structured output. **Never modifies wiki content. Never modifies source material.** The read-only constraint is the defining behavioral trait. Each child specializes in what it judges and what vocabulary its output uses, but the protocol with the orchestrator is the same: assignment in, structured assessment out.

#### Explorer agents

- **Drive:** Comprehension.
- **Agent type:** `wiki-explorer`
- **Appears in:** UC-01, UC-02

Read-only examination of source code from distinct angles or domain facets. Each produces a structured report. In UC-01, reports feed the planning agent. In UC-02, summaries serve as shared context for reviewer agents. Explorers never modify files. The minimum facets in UC-02 are: public API surface, architecture, and configuration. Facet count is extensible per project.

#### Reviewer agents

- **Drive:** Critique.
- **Agent type:** `wiki-reviewer`
- **Appears in:** UC-02

Each examines wiki content through one editorial lens. Four lenses represent distinct editorial disciplines:

| Lens | Scope | What it checks |
|------|-------|----------------|
| Structure | Whole wiki | Organization, flow, gaps, redundancies, sidebar integrity |
| Line | Per page | Sentence-level clarity, tightening, transitions |
| Copy | Cross-page | Grammar, formatting, terminology consistency |
| Accuracy | Per page + source | Claims verified against source code |

A reviewer that finds nothing wrong reports clean content. The drive is to find real problems, not to generate findings.

#### Fact-checker agents

- **Drive:** Verification.
- **Appears in:** UC-04

Each reads an assigned wiki page, identifies all sources of truth (source code files, external URLs, linked resources), and verifies every factual claim. Claims are assessed as verified, inaccurate, or unverifiable. The fact-checker determines what is true — it does not fix anything, improve prose, or reorganize.

The fact-checker's scope includes external references (URLs, linked docs, specifications) as sources of truth. This is broader than UC-02's accuracy lens, which is strictly source-code-grounded.

#### Deduplicator agent

- **Drive:** Filtering.
- **Appears in:** UC-02

Compares findings against existing open GitHub issues labeled `documentation`. Prevents duplicate issues without suppressing legitimate findings. Only drops a finding when it clearly matches an existing open issue about the same problem. A finding about a different section of the same page is not a duplicate.

### «abstract» Content Mutator

Receives a page assignment with source file references from the orchestrator. Reads source files for grounding. **Modifies wiki content.** The write permission is the defining behavioral trait. Children differ in the nature of their judgment: creators synthesize what to say, correctors apply what someone else determined.

| | Creator | Corrector |
|---|---------|-----------|
| Input | Plan assignment | Finding + recommendation |
| Judgment | Synthetic — decides what to say | Mechanical — applies what to fix |
| Authority | Self (constrained by plan) | The finding (constrained by source) |
| On uncertainty | Must produce something | Must skip |

**Separation rationale:** An agent that both produces content and evaluates whether it produced well has two jobs and will do both poorly. Two agents with opposing drives produce better outcomes than one agent balancing competing concerns. Production, critique, and remediation are three distinct drives — a creator cannot reliably evaluate its own output, and a corrector must not second-guess the reviewer or generate new content.

#### Writer agents (Creator)

- **Drive:** Production.
- **Agent type:** `wiki-writer`
- **Appears in:** UC-01

Each receives a page assignment with source file references, audience, tone, and editorial guidance, then reads the source files and writes one wiki page. The writer optimizes for coverage and clarity, not for catching its own mistakes. This drive is insufficient to guarantee accuracy — which is why UC-02 exists with a separate critique drive.

#### Fixer agents (Corrector)

- **Drive:** Remediation.
- **Agent type:** `wiki-writer` (reused)
- **Appears in:** UC-03, UC-04

Each receives a wiki page, its associated findings, and source file references, then applies targeted corrections using the Edit tool. The fixer's drive is to apply known fixes to known problems — it does not discover new problems (UC-02's critique drive) and does not create new content (UC-01's production drive). When a recommendation contradicts source code or is ambiguous, the fixer skips rather than guesses.

UC-03 and UC-04 both consume the same protocol: a page, a finding (what's wrong), a recommendation (what it should say), and a source reference (the authority). The shared protocol enables agent reuse across bounded contexts.

---

## Sub-systems

Infrastructure components that the system depends on. These are not actors — they have no drives and make no decisions. `grep` does exactly what you tell it; so do these.

### GitHub

- **Role:** Remote repository host and durable event store.
- **Used by:** UC-02 (issue filing, deduplication), UC-03 (issue reading, closing, labeling), UC-05 (repository validation)

GitHub Issues serves as the message queue between UC-02 (producer) and UC-03 (consumer). The issue body conforming to `wiki-docs.yml` is the published protocol. GitHub is a sub-system, not an external dependency — issues are the durable facts that cross bounded context boundaries.

### Git

- **Role:** Cloning, working tree inspection, post-hoc approval.
- **Used by:** UC-04 (approval gate via diff/revert), UC-05 (cloning), UC-06 (safety checks)

Git provides repository cloning, change detection, and the post-hoc approval gate for UC-04's autonomous corrections. In UC-06, git working tree inspection detects unpublished work before destructive actions.

---

## Appearance matrix

| Actor | Goal / Drive | UC-01 | UC-02 | UC-03 | UC-04 | UC-05 | UC-06 |
|-------|--------------|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| User | (goal per UC) | P | P | P | P | P | P |
| Orchestrator | Coordination | S | S | S | S | — | — |
| Planning agent | Synthesis | S | — | — | — | — | — |
| *«Assessor»* | *read-only judgment* | *S* | *S* | — | *S* | — | — |
| ↳ Explorer agents | Comprehension | S | S | — | — | — | — |
| ↳ Reviewer agents | Critique | — | S | — | — | — | — |
| ↳ Fact-checker agents | Verification | — | — | — | S | — | — |
| ↳ Deduplicator | Filtering | — | S | — | — | — | — |
| *«Content Mutator»* | *wiki modification* | *S* | — | *S* | *S* | — | — |
| ↳ Writer agents | Production | S | — | — | — | — | — |
| ↳ Fixer agents | Remediation | — | — | S | S | — | — |

**P** = primary actor, **S** = supporting actor, **—** = not involved, *italics* = abstract (not instantiated directly)

| Sub-system | UC-01 | UC-02 | UC-03 | UC-04 | UC-05 | UC-06 |
|------------|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| GitHub | — | x | x | — | x | — |
| Git | — | — | — | x | x | x |
