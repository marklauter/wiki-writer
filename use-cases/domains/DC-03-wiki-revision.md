# DC-03 -- Wiki Revision

## Purpose

Owns the revision of wiki content based on documented problems tracked in GitHub Issues. Correctors apply recommended corrections to wiki pages. Issue closure is a consequence of successful revision, not the goal. This context consumes the published protocol from [DC-02 Editorial Review](DC-02-editorial-review.md).

## Ubiquitous language

- **Corrector** -- An actor with a remediation drive that applies recommended corrections to a wiki page.
- **Targeted edit** -- A surgical change to a specific section of a wiki page, preserving surrounding content.
- **Skip reason** -- Why a corrector could not apply a recommendation: quoted text no longer exists, recommendation is ambiguous, recommendation contradicts source code.
- **Correction assignment** -- The input to a corrector: page path, finding (what's wrong), recommendation (what it should say), source reference (the authority). Structurally compatible with [DC-04 Drift Detection](DC-04-drift-detection.md)'s correction assignments, enabling corrector reuse.

## Use cases

- [UC-03](../UC-03-revise-wiki.md) -- Apply recommended corrections from GitHub issues to wiki pages

## Domain events produced

- [DE-04 WikiRemediated](DOMAIN-EVENTS.md#de-04----wikiremediated)

## Domain events consumed

- [DE-02 FindingFiled](DOMAIN-EVENTS.md#de-02----findingfiled) (from DC-02, via GitHub Issues)

## Integration points

- **Requires:** [DC-05 Workspace Lifecycle](DC-05-workspace-lifecycle.md) -- workspace must be provisioned.
- **Consumes from:** [DC-02 Editorial Review](DC-02-editorial-review.md) -- GitHub issues conforming to `documentation-issue.md` schema.
- **Shares with:** [DC-04 Drift Detection](DC-04-drift-detection.md) -- corrector protocol is structurally compatible.
