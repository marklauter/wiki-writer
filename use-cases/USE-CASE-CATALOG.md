# Use case catalog

## The user's goals

The primary actor is a developer or maintainer responsible for a GitHub project's wiki documentation. In Cooper's goal hierarchy:

- **Life goal:** Be a responsible steward of the project's knowledge.
- **Experience goal:** Trust that the wiki is accurate without constant manual vigilance.
- **End goals:** Populate a new wiki from source code. Verify that existing content is correct. Fix known problems. Keep the wiki in sync as source code evolves.

Each end goal maps to a use case. The system exists so the user can satisfy experience-level confidence through repeatable, auditable operations rather than heroic manual effort.

## The domain

The domain is documentation accuracy. Source code is the primary source of truth; external references (URLs, linked specifications) are secondary sources. The core domain problem is **drift** -- code changes, but the wiki does not. Drift is invisible until someone reads the wrong information and acts on it.

The domain decomposes into six **bounded contexts**, each with its own ubiquitous language and its own invariants. Contexts communicate through **domain events** materialized as durable artifacts -- GitHub Issues for the editorial pipeline, files on disk for sync reports. Full definitions live in the [domains/](domains/) folder.

- **[DC-01 Wiki Creation](domains/DC-01-wiki-creation.md)** -- transition from empty wiki to populated wiki.
- **[DC-02 Editorial Review](domains/DC-02-editorial-review.md)** -- critique of existing content across four editorial lenses.
- **[DC-03 Issue Resolution](domains/DC-03-issue-resolution.md)** -- remediation of documented problems.
- **[DC-04 Drift Detection](domains/DC-04-drift-detection.md)** -- ongoing verification of factual claims against sources of truth.
- **[DC-05 Workspace Lifecycle](domains/DC-05-workspace-lifecycle.md)** -- provisioning and decommissioning of project workspaces.
- **[DC-06 Wiki Restructuring](domains/DC-06-wiki-restructuring.md)** -- interactive restructuring of an existing wiki *(not yet designed)*.

The **published language** between Editorial Review and Issue Resolution is the GitHub issue body conforming to the `documentation-issue.md` template schema. This is the integration contract -- UC-02 produces issues in this format, UC-03 consumes them. No internal state is shared across the boundary.

Actors have **drives** -- behavioral tendencies that determine what each actor optimizes for (see [PHILOSOPHY.md](meta/PHILOSOPHY.md)). A creator's drive is production. A proofreader's drive is critique. A fact-checker's drive is verification. Where a single drive is insufficient to protect a concern, a separate actor with a complementary drive is introduced. This is the domain's answer to conflicts of interest: structural separation, not trust.

Supporting documents: [PHILOSOPHY.md](meta/PHILOSOPHY.md) (design principles), [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) (cross-cutting rules), [TEMPLATE.md](meta/TEMPLATE.md) (use case structure), [DOMAIN-EVENTS.md](domains/DOMAIN-EVENTS.md) (event catalog).

## Use cases

- **[UC-01](UC-01-populate-new-wiki.md)** -- Populate new wiki from source code with user-approved structure
- **[UC-02](UC-02-review-wiki-quality.md)** -- Review wiki quality across four editorial lenses, file GitHub issues
- **[UC-03](UC-03-resolve-documentation-issues.md)** -- Apply recommended corrections from GitHub issues to wiki pages
- **[UC-04](UC-04-sync-wiki-with-source-changes.md)** -- Fact-check wiki claims against source code and external references, correct drift
- **[UC-05](UC-05-provision-workspace.md)** -- Clone repos and write config for a new project workspace
- **[UC-06](UC-06-decommission-workspace.md)** -- Remove a project workspace with safety checks for unpublished work
- **[UC-07](UC-07-publish-wiki-changes.md)** -- Commit and push wiki changes *(out of scope -- users use their own git tools)*
- **[UC-08](UC-08-refactor-existing-wiki.md)** -- Interactively restructure an existing wiki *(not yet designed)*

## Bounded contexts

| Context | Use cases | Domain events |
|---------|-----------|---------------|
| [DC-01 Wiki Creation](domains/DC-01-wiki-creation.md) | UC-01 | DE-01 WikiPopulated |
| [DC-02 Editorial Review](domains/DC-02-editorial-review.md) | UC-02 | DE-02 FindingFiled, DE-03 WikiReviewed |
| [DC-03 Issue Resolution](domains/DC-03-issue-resolution.md) | UC-03 | DE-04 WikiRemediated |
| [DC-04 Drift Detection](domains/DC-04-drift-detection.md) | UC-04 | DE-05 WikiSynced |
| [DC-05 Workspace Lifecycle](domains/DC-05-workspace-lifecycle.md) | UC-05, UC-06 | DE-06 WorkspaceProvisioned, DE-07 WorkspaceDecommissioned |
| [DC-06 Wiki Restructuring](domains/DC-06-wiki-restructuring.md) | UC-08 | *(not yet designed)* |
