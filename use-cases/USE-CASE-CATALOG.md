# Use case catalog

## The user's goals

The primary actor is a developer or maintainer responsible for a GitHub project's wiki documentation. In Cooper's goal hierarchy:

- **Life goal:** Be a responsible steward of the project's knowledge.
- **Experience goal:** Trust that the wiki is accurate without constant manual vigilance.
- **End goals:** Populate a new wiki from source code. Verify that existing content is correct. Fix known problems. Keep the wiki in sync as source code evolves.

Each end goal maps to a use case. The system exists so the user can satisfy experience-level confidence through repeatable, auditable operations rather than heroic manual effort.

## The domain

The domain is documentation accuracy. Source code is the primary source of truth; external references (URLs, linked specifications) are secondary sources. The core domain problem is **drift** -- code changes, but the wiki does not. Drift is invisible until someone reads the wrong information and acts on it.

The domain decomposes into five **bounded contexts**, each with its own ubiquitous language and its own invariants. Contexts communicate through **domain events** materialized as durable artifacts -- GitHub Issues for the editorial pipeline, files on disk for sync reports.

- **Wiki Creation** owns the transition from empty wiki to populated wiki. Its language includes *exploration reports*, *wiki plans*, and *writer assignments*.
- **Editorial Review** owns the critique of existing content across four editorial lenses (accuracy, structure, line, copy). Its language includes *findings*, *editorial lenses*, *severities*, and *deduplication*.
- **Issue Resolution** owns the remediation of documented problems. Its language includes *fixer agents*, *targeted edits*, and *skip reasons*.
- **Drift Detection** owns the ongoing verification of factual claims against their sources of truth. Its language includes *fact-checker assessments*, *drift*, *correction assignments*, and *sync reports*.
- **Workspace Lifecycle** owns the provisioning and decommissioning of project workspaces. Its language includes *workspace configs*, *source clones*, *wiki clones*, and *safety checks*.

The **published language** between Editorial Review and Issue Resolution is the GitHub issue body conforming to the `wiki-docs.yml` template schema. This is the integration contract -- UC-02 produces issues in this format, UC-03 consumes them. No internal state is shared across the boundary.

Agents are modeled as actors with **drives** -- behavioral tendencies that determine what each agent optimizes for (see [PHILOSOPHY.md](PHILOSOPHY.md)). A writer's drive is production. A reviewer's drive is critique. A fact-checker's drive is verification. Where a single drive is insufficient to protect a concern, a separate actor with a complementary drive is introduced. This is the domain's answer to conflicts of interest: structural separation, not trust.

Supporting documents: [PHILOSOPHY.md](PHILOSOPHY.md) (design principles), [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) (cross-cutting rules), [TEMPLATE.md](TEMPLATE.md) (use case structure).

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

| Context | Use cases | Key domain events |
|---------|-----------|-------------------|
| Wiki Creation | UC-01 | WikiPopulated |
| Editorial Review | UC-02 | FindingFiled, WikiReviewed |
| Issue Resolution | UC-03 | IssueCorrected, WikiRemediated |
| Drift Detection | UC-04 | DriftDetected, DriftCorrected, WikiSynced |
| Wiki Restructuring | UC-08 | *(not yet designed)* |
| Workspace Lifecycle | UC-05, UC-06 | WorkspaceProvisioned, WorkspaceDecommissioned |
