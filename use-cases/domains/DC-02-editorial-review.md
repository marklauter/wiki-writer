# DC-02 -- Editorial Review

## Purpose

Owns the critique of existing wiki content across four editorial lenses: structure, line, copy, and accuracy. The review process surfaces problems as GitHub Issues -- it never modifies wiki content. This context produces the published protocol consumed by [DC-03 Wiki Revision](DC-03-wiki-revision.md).

## Ubiquitous language

- **Editorial lens** -- A distinct editorial discipline applied to wiki content. Four lenses: structure (organization, flow, gaps), line (sentence-level clarity), copy (grammar, formatting, terminology consistency), accuracy (claims verified against source code).
- **Finding** -- A specific documentation problem identified by a proofreader, with quoted problematic text, a recommendation, and (for accuracy) a source file citation.
- **Severity** -- Classification of a finding: must-fix or suggestion.
- **Deduplication** -- Comparing new findings against existing open GitHub issues to prevent duplicates. Only drops a finding when it clearly matches an existing open issue about the same problem.
- **Proofread cache** -- Ephemeral storage for coordinating actors during a single review run. Created at start, cleaned up at end.

## Use cases

- [UC-02](../UC-02-review-wiki-quality.md) -- Review wiki quality across four editorial lenses, file GitHub issues

## Domain events produced

- [DE-02 FindingFiled](DOMAIN-EVENTS.md#de-02----findingfiled) (published -- consumed by DC-03)
- [DE-03 WikiReviewed](DOMAIN-EVENTS.md#de-03----wikireviewed)

## Integration points

- **Requires:** [DC-05 Workspace Lifecycle](DC-05-workspace-lifecycle.md) -- workspace must be provisioned.
- **Publishes to:** [DC-03 Wiki Revision](DC-03-wiki-revision.md) -- findings filed as GitHub issues are consumed by correctors.
- **Gap:** Accuracy findings may become stale if DC-04 (Drift Detection) independently corrects the same inaccuracy. Accepted trade-off.
