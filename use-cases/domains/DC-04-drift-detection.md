# DC-04 -- Drift Detection

## Purpose

Owns the ongoing verification of factual claims in the wiki against their sources of truth -- source code, external references, linked specifications. Claims that have drifted are corrected. Claims that are accurate are left untouched. This context operates autonomously (git is the approval gate) and does not interact with GitHub Issues.

## Ubiquitous language

- **Drift** -- A factual claim in the wiki that no longer matches its source of truth.
- **Fact-checker assessment** -- A structured report for one wiki page listing every factual claim checked, with verdict (verified, inaccurate, unverifiable), quoted text, correct fact, and source reference.
- **Correction assignment** -- The input to a corrector: page path, list of inaccurate claims with correct facts and source references, audience, tone, editorial guidance. Structurally compatible with [DC-03 Wiki Revision](DC-03-wiki-revision.md)'s correction assignments, enabling corrector reuse.
- **Sync report** -- A durable, time-stamped report showing corrections applied, pages verified, and claims that could not be checked. Stored at `workspace/artifacts/{owner}/{repo}/reports/sync/{date-time}-sync-report.md`.
- **Source of truth** -- The authoritative reference for a factual claim. May be source code, an external URL, a linked specification, or other referenced material.

## Use cases

- [UC-04](../UC-04-sync-wiki-with-source-changes.md) -- Fact-check wiki claims against source code and external references, correct drift

## Domain events produced

- [DE-05 WikiSynced](DOMAIN-EVENTS.md#de-05----wikisynced)

## Integration points

- **Requires:** [DC-05 Workspace Lifecycle](DC-05-workspace-lifecycle.md) -- workspace must be provisioned.
- **Shares with:** [DC-03 Wiki Revision](DC-03-wiki-revision.md) -- corrector protocol is structurally compatible.
- **Gap:** Corrections may render DC-02 accuracy findings stale. Accepted trade-off in favor of keeping drift detection fast and independent.
