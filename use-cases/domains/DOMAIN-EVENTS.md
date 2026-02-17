# Domain events

Domain events are facts that cross bounded context boundaries or are exposed to the user as observable outcomes. Internal coordination events (e.g., DriftDetected, IssueIdentified) remain defined within their use cases.

See also: [USE-CASE-CATALOG.md](../USE-CASE-CATALOG.md) for the bounded contexts summary table.

## DE-01 -- WikiPopulated

- **Bounded context:** [DC-01 Wiki Creation](DC-01-wiki-creation.md)
- **Producer:** [UC-01](../UC-01-populate-new-wiki.md)
- **Consumers:** User, [DC-02](DC-02-editorial-review.md) (wiki is ready for review), [DC-04](DC-04-drift-detection.md) (wiki has content to sync)
- **Materialization:** Wiki pages on disk + summary presented to user

The wiki directory has been populated with a complete set of documentation pages from an approved plan. This is the foundational event in Wiki Creation -- after this event, the wiki is ready for review (UC-02) and publishing (`/save`).

### Payload

- Repo identity (owner/repo)
- Sections with their pages (hierarchical structure matching navigation)
- Audience and tone
- Wiki directory path

## DE-02 -- FindingFiled

- **Bounded context:** [DC-02 Editorial Review](DC-02-editorial-review.md)
- **Producer:** [UC-02](../UC-02-review-wiki-quality.md)
- **Consumer:** [DC-03 Wiki Revision](DC-03-wiki-revision.md) via [UC-03](../UC-03-revise-wiki.md)
- **Materialization:** GitHub issue with `documentation` label, conforming to `documentation-issue.md` schema

A GitHub issue has been created for a documentation problem. This is the only published event that crosses a bounded context boundary as a formal contract. The issue body schema (`documentation-issue.md`) is the integration protocol between Editorial Review and Wiki Revision. GitHub is a sub-system -- the issue is the durable fact.

### Payload

- Issue number
- Page
- Editorial lens
- Severity
- Finding text (with quoted problematic text)
- Recommendation (with corrected text where applicable)
- Source file citation (accuracy lens only)

## DE-03 -- WikiReviewed

- **Bounded context:** [DC-02 Editorial Review](DC-02-editorial-review.md)
- **Producer:** [UC-02](../UC-02-review-wiki-quality.md)
- **Consumer:** User
- **Materialization:** Summary presented to user; GitHub issues as durable record

The review process has completed. The user knows what is strong, what needs fixing, and where to start.

### Payload

- Pages reviewed count
- Issues identified count
- Issues filed count
- Clean pages
- Failed reviews
- Failed filings

## DE-04 -- WikiRemediated

- **Bounded context:** [DC-03 Wiki Revision](DC-03-wiki-revision.md)
- **Producer:** [UC-03](../UC-03-revise-wiki.md)
- **Consumer:** User
- **Materialization:** Summary presented to user; wiki files corrected on disk; GitHub issues closed

The remediation run has completed. Every actionable issue has been processed -- either corrected and closed, or skipped with a reason.

### Payload

- Issues corrected count
- Issues skipped count
- Issues close-deferred count
- Remaining open count

## DE-05 -- WikiSynced

- **Bounded context:** [DC-04 Drift Detection](DC-04-drift-detection.md)
- **Producer:** [UC-04](../UC-04-sync-wiki-with-source-changes.md)
- **Consumer:** User
- **Materialization:** Sync report on disk at `workspace/artifacts/{owner}/{repo}/reports/sync/{date-time}-sync-report.md`

The sync operation has completed. Every factual claim has been checked, drift has been corrected, and the user has a durable report.

### Payload

- Pages checked count
- Corrections applied count
- Claims skipped (unverifiable) count
- Pages up-to-date count
- Pages unchecked (fact-checker failure) count

## DE-06 -- WorkspaceProvisioned

- **Bounded context:** [DC-05 Workspace Lifecycle](DC-05-workspace-lifecycle.md)
- **Producer:** [UC-05](../UC-05-provision-workspace.md)
- **Consumer:** All operational bounded contexts (DC-01 through DC-04) via config file discovery
- **Materialization:** `workspace/artifacts/{owner}/{repo}/workspace.config.md` on disk

A new workspace configuration file has been written to disk. This is the durable fact that all other bounded contexts discover at workspace selection time by scanning for config files matching `workspace/artifacts/*/*/workspace.config.md`.

### Payload

- Repo slug (owner/repo)
- Source directory path
- Wiki directory path
- Audience
- Tone

## DE-07 -- WorkspaceDecommissioned

- **Bounded context:** [DC-05 Workspace Lifecycle](DC-05-workspace-lifecycle.md)
- **Producer:** [UC-06](../UC-06-decommission-workspace.md)
- **Consumer:** None (workspace simply ceases to exist)
- **Materialization:** Config file, source clone, and wiki clone removed from disk

The workspace config file, source clone, and wiki clone have been removed. This is the inverse of DE-06 WorkspaceProvisioned. After this event, the workspace selection procedure will no longer discover this workspace.

### Payload

- Repo slug (owner/repo)
