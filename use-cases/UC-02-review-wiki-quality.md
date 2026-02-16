# UC-02 -- Review Wiki Quality

## Goal

Every real problem in the wiki -- inaccuracies against source code, structural weaknesses, unclear prose, style violations -- is surfaced as a GitHub issue with enough context to act on. The wiki itself is untouched. The user has a clear picture of what is strong, what needs fixing, and where to start. The writer's production drive (UC-01) is insufficient to guarantee accuracy on its own; the reviewer's critique drive exists to find what the writer missed or got wrong.

## Context

- **Bounded context:** Editorial Review
- **Primary actor:** User
- **Supporting actors:** Orchestrator (`/proofread-wiki` command), Explorer agents (wiki-explorer), Reviewer agents (one per editorial lens), Deduplicator agent
- **Trigger:** The user has a populated wiki (UC-01 or manually authored) and wants an independent editorial review.

## Agent responsibilities

Each agent has a single drive. Separation exists because no single drive can protect all the concerns at play. The reviewer's critique drive is the complement to UC-01's production drive -- not because the writer is malicious, but because a single drive cannot serve competing concerns.

- **Orchestrator** -- Drive: coordination. Resolves the workspace, absorbs editorial context, dispatches explorers and reviewers, collects results, files issues, cleans up the cache, and presents the summary. The orchestrator makes no editorial judgments and performs no reviews.

- **Explorer agents** -- Drive: comprehension. Each examines the source code from a distinct domain facet and produces a structured summary. At minimum three facets: the public API surface (exported components -- public classes, interfaces, entry points), architecture (components, abstractions, data flows), and configuration (options, constraints, limitations, edge cases). Additional facets may be warranted for some projects. Explorers are read-only -- they never modify files. Their summaries serve as shared context for all reviewers.

- **Reviewer agents** -- Drive: critique. Each examines the wiki content through one editorial lens. There are four lenses, each representing a distinct editorial discipline:

  - **Structure lens** -- Organization, flow, gaps, redundancies. Requires whole-wiki visibility to assess how pages relate, where content is missing, and where it overlaps. Sidebar structural integrity (orphan pages, broken links) is checked here.
  - **Line lens** -- Sentence-level clarity, tightening, transitions. Page-local work. Each page is examined independently.
  - **Copy lens** -- Grammar, formatting, terminology consistency. Requires cross-page visibility for terminology -- the same concept must be named the same way across the entire wiki.
  - **Accuracy lens** -- Claims verified against source code. Requires source code access per page. Each page's code identifiers are traced back to source files and verified.

  A reviewer that finds nothing wrong reports that the content is clean. An editor who nitpicks everything is as unhelpful as one who misses real problems. The drive is to find real problems, not to generate findings.

- **Deduplicator agent** -- Drive: filtering. Compares findings against existing open GitHub issues labeled `documentation`. Its job is to prevent duplicate issues -- not to suppress legitimate findings. Only drops a finding when it clearly matches an existing open issue about the same problem. A finding about a different section of the same page is not a duplicate.

## Invariants

See also: [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) for cross-cutting invariants (GitHub CLI, source readonly, config as identity, scripts own deterministic behavior, etc.)

- **Review-only -- never edit wiki files.** The reviewer's output is exclusively GitHub issues (or local fallback files when GitHub is unreachable). A reviewer that "helpfully" fixes a problem it found has violated this invariant. This is the structural separation between UC-02 (critique drive) and UC-03 (resolution drive).
- **One issue per finding.** Findings are never grouped into a single issue. Each issue is independently actionable. This matters downstream -- UC-03 consumes individual issues.
- **Source code is the authority for accuracy.** When a reviewer checks whether a wiki claim is correct, the source code is the ground truth -- not training data, not inference, not external documentation. If a claim cannot be verified against source code, it is flagged as unverified rather than reported as a finding.
- **Findings must be grounded.** A finding without a quote of the problematic text is not actionable. Accuracy findings must cite the source file and line. Copy and line findings must provide corrected text. Structural findings must describe what is missing, misplaced, or redundant.
- **Err on the side of filing.** During deduplication, only skip when the match is clearly the same problem. When in doubt, file.
- **Issue template must exist.** The issue template (`.github/ISSUE_TEMPLATE/wiki-docs.yml`) belongs to the wiki-agent repo and must be present. Filed issues conform to its schema.
- **Editorial guidance must exist.** The editorial guidance (`.claude/guidance/editorial-guidance.md`) and wiki instructions (`.claude/guidance/wiki-instructions.md`) belong to the wiki-agent repo and must be present. Reviewers apply these standards.
- **`documentation` label is invariant.** All wiki-related issues carry the `documentation` label. Deduplication scopes to open issues with this label.
- **Proofread cache is ephemeral.** The `.proofread/{repo}/` cache exists only to coordinate agents during a single run. It is created at the start and cleaned up at the end. GitHub issues are the durable output.
- **Repo freshness is the user's responsibility.** The system does not pull or verify that clones are up to date. The user is responsible for ensuring the workspace reflects the state they want reviewed.

## Success outcome

- Every actionable finding exists as a GitHub issue with the `documentation` label, conforming to the issue template schema.
- Each issue quotes the problematic text, provides a recommendation, and (for accuracy issues) cites the source file and line.
- The user sees a summary: what is strong, issues filed (with numbers, pages, titles, severities, and lenses), clean pages, and any unverified items.
- The proofread cache has been cleaned up.
- The wiki content is unmodified.

## Failure outcome

- If failure occurs before reviewers complete (workspace resolution, explorer failure, all reviewers fail), no issues are filed. The user is told what failed.
- If some reviewers succeed and some fail, findings from successful reviewers proceed through the pipeline. The summary reports which pages or lenses were not covered.
- If GitHub is unreachable, issues are written locally to `workspace/reviews/{owner}/{repo}/{date-time}/` as fallback files. The summary reports locally-written issues with file paths.
- If individual issue filings fail, those issues are written locally as fallback. Other filings proceed.
- In all cases, the proofread cache is cleaned up and the user is told what happened.

## Scenario

1. **User** -- Initiates a wiki review by running `/proofread-wiki`.
2. **Orchestrator** -- Resolves the workspace and loads config (repo identity, source dir, wiki dir, audience, tone).
3. **Orchestrator** -- Absorbs editorial context: reads editorial guidance, wiki instructions, issue template, and the target project's CLAUDE.md if it exists.
4. **Orchestrator** -- Discovers all content pages in the wiki directory, excluding structural files (`_`-prefixed `.md` files). If no content pages exist, reports "nothing to review" and stops.
5. **Orchestrator** -- Dispatches explorer agents to build a project summary from the source code. Explorers examine the source from distinct domain facets -- at minimum the public API surface, architecture, and configuration -- and write structured summaries to the proofread cache.
6. **Explorer agents** -- Each reads the source code and produces a summary covering its assigned facet.
7. **Orchestrator** -- Dispatches reviewer agents across all four editorial lenses. Each lens is applied to the wiki content.
8. **Reviewer agents** -- Each examines the wiki through its assigned editorial lens, using project summaries and source code as reference. Each problem found is written to the proofread cache as a finding.
   --> IssueIdentified (one per finding)
9. **Deduplicator agent** -- Reads all findings from the cache. Reads all open GitHub issues labeled `documentation`. Drops findings that clearly match existing open issues. Produces the set of findings to be filed.
   --> IssueToBeFiled (one per surviving finding)
10. **Orchestrator** -- Files one GitHub issue per IssueToBeFiled event, using the issue template format.
    --> FindingFiled (one per issue)
11. **Orchestrator** -- Cleans up the proofread cache.
    --> WikiReviewed
12. **User** -- Sees the review summary: what is strong, issues filed, unverified items, clean pages, failed reviews, failed filings.

## Goal obstacles

### Step 2a -- No workspace exists

1. **Orchestrator** -- Reports that no workspace exists and directs the user to run `/up` first.
2. **Orchestrator** -- Stops.

### Step 2b -- Workspace not found for the given identifier

1. **Orchestrator** -- Reports that no workspace matches the provided identifier and lists available workspaces.
2. **Orchestrator** -- Stops.

### Step 4a -- No content pages in wiki

1. **Orchestrator** -- Reports "nothing to review" -- the wiki directory contains no content pages (only structural files or nothing at all).
2. **Orchestrator** -- Stops.

### Step 6a -- One or more explorer agents fail

One or more explorer agents fail to produce a summary (crash, timeout, or unusable results).

1. **Orchestrator** -- Reports which explorers failed and which facets of the source code were not summarized.
2. **Orchestrator** -- Proceeds with the summaries that succeeded. Reviewers work with incomplete context. Accuracy verification may be less thorough, and affected findings may be flagged as lower-confidence.

### Step 8a -- One or more reviewer agents fail

A reviewer agent crashes, times out, or produces unusable results. The page or lens it was responsible for is not reviewed.

1. **Orchestrator** -- Retries the failed reviewer once.
2. If the retry fails, the orchestrator records the failure. Findings from other reviewers proceed through the pipeline.
3. The summary reports which pages or lenses were not covered.

### Step 9a -- GitHub is unreachable

The deduplicator cannot read open issues, and the orchestrator cannot file new issues. The entire GitHub integration is unavailable.

1. **Orchestrator** -- Skips deduplication (cannot compare against existing issues).
2. **Orchestrator** -- Writes all findings as local fallback files to `workspace/reviews/{owner}/{repo}/{date-time}/`, one file per finding, using the issue frontmatter format.
3. **Orchestrator** -- Reports that issues were written locally because GitHub was unreachable, and provides the file paths.

### Step 9b -- All findings are duplicates

Every finding matches an existing open GitHub issue. Nothing new to file.

1. **Deduplicator agent** -- Reports that all findings are already covered by open issues (listing the matching issue numbers).
2. **Orchestrator** -- Reports this in the summary. No issues are filed. This is not a failure -- the wiki's known problems are already tracked.

### Step 10a -- Individual issue filing fails

The `file-issue.sh` script fails for a specific finding after its internal retry.

1. **Orchestrator** -- Writes the failed issue as a local fallback file to `workspace/reviews/{owner}/{repo}/{date-time}/`, using the issue frontmatter format.
2. **Orchestrator** -- Continues filing remaining issues.
3. The summary reports locally-written issues with file paths alongside successfully filed issues.

## Domain events

- **IssueIdentified** -- A reviewer agent has found a documentation problem. Internal event within Editorial Review. Carries: page, editorial lens, severity, finding text, recommendation, source file citation (accuracy lens only). Materialized as a finding file in the proofread cache. Consumed by the deduplicator.

- **IssueToBeFiled** -- (Milestone, not a domain event.) The deduplicator has confirmed that a finding is new -- no matching open issue exists. Carries the same payload as IssueIdentified. Materialized as a deduplicated finding in the cache. Consumed by the orchestrator for issue filing within this same use case.

- **FindingFiled** -- A GitHub issue has been created for a documentation problem. Published event that crosses the boundary into Issue Resolution (UC-03). Carries: issue number, page, editorial lens, severity, finding text, recommendation. Materialized as a GitHub issue with the `documentation` label. GitHub is a sub-system of this system -- the issue is the durable fact.

- **WikiReviewed** -- The review process has completed. Carries: pages reviewed, issues identified count, issues filed count, clean pages, failed reviews, failed filings. Success is defined as: every finding that survived deduplication was successfully filed as a GitHub issue (issues identified after dedup == issues filed).

## Protocols

- **workspace.config.yml** -- step 2, input. The workspace config provides repo identity, source dir, wiki dir, audience, and tone. Contract defined in UC-05.
- **Explorer summary** -- step 6, output from each explorer agent. A structured summary covering one domain facet of the source code (API surface, architecture, configuration). Written to the proofread cache. Consumed by reviewer agents in step 8.
- **Finding format** -- step 8, output from each reviewer agent. A structured finding with: page, editorial lens, severity, finding text (with quoted problematic text), recommendation (with corrected text where applicable), and source file citation (accuracy lens only). Written to the proofread cache. Values for editorial lens and severity must match the exact dropdown options in the issue template (`wiki-docs.yml`).
- **Issue body (wiki-docs.yml)** -- step 10, output from the orchestrator. A GitHub issue body conforming to the `.github/ISSUE_TEMPLATE/wiki-docs.yml` schema. Fields: Page, Editorial lens, Severity, Finding, Recommendation, Source file, Notes. This is the published protocol between UC-02 (producer) and UC-03 (consumer).
- **Local fallback format** -- steps 9a/10a, output when GitHub is unreachable. A markdown file with YAML frontmatter (title, page, editorial lens, severity) and body sections (Finding, Recommendation, Source file). Written to `workspace/reviews/{owner}/{repo}/{date-time}/`.

## Notes

- **`--pass` flag removed.** The command file currently supports `--pass` to run a single editorial lens. The use case does not model this -- every invocation runs all four lenses. The command file should be updated to remove `--pass` support. This resolves the tension with SHARED-INVARIANTS.md ("No CLI-style flags").
- **Editorial lenses, not passes.** The term "editorial lens" replaces "pass" to reflect that these are parallel editorial disciplines, not serial processing steps. Each lens has its own drive and its own input requirements. The four lenses -- structure, line, copy, accuracy -- map to distinct editorial disciplines in a human editing department.
- **Dispatch pattern is an implementation concern.** The use case specifies what each lens requires as input (whole-wiki visibility for structure, source code access for accuracy, cross-page terminology visibility for copy, page-local for line). How those requirements are satisfied -- per-page agents, multi-page agents, or hybrids -- is an implementation decision driven by context window constraints and model capabilities.
- **Explorer facets are extensible.** The three named facets (API surface, architecture, configuration) are the minimum. Some projects may warrant additional facets. The use case does not prescribe a fixed count.
- **Sidebar validation is reviewer work.** Sidebar structural integrity (orphan pages, broken links) is checked by the structure lens reviewer, not by the orchestrator. The orchestrator orchestrates; reviewers review.
- **GitHub is a sub-system.** GitHub Issues serves as the system's durable event store for findings. The issue is the published fact that UC-03 (Resolve Documentation Issues) consumes. This framing means GitHub unreachability is a system degradation, not an external dependency failure.
- **Local fallback path.** When GitHub is unreachable or individual filings fail, issues are written to `workspace/reviews/{owner}/{repo}/{date-time}/` -- outside both the source clone and wiki clone. This keeps the source clone clean (readonly invariant) and the wiki clone uncontaminated by review artifacts.
- **Relationship to other use cases:** UC-02 requires UC-05 (Provision Workspace) as a prerequisite and typically follows UC-01 (Populate New Wiki), though it can review any populated wiki. Its output (FindingFiled) feeds UC-03 (Resolve Documentation Issues) via the issue body protocol. It has no dependency on UC-04 (Sync Wiki with Source Changes) or UC-06 (Decommission Workspace).
