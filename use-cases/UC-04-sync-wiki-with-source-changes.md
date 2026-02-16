# UC-04 -- Sync Wiki with Source Changes

## Goal

Every factual claim in the wiki accurately reflects the current state of its sources of truth -- source code, external references, linked resources. Claims that have drifted are corrected. Claims that are still accurate are left untouched. The user has a durable, time-stamped report showing what changed, what was verified, and what could not be checked. This is a fact-checking operation, not a full editorial review -- only accuracy matters, not structure, prose quality, or copy consistency.

## Context

- **Bounded context:** Drift Detection
- **Primary actor:** User
- **Supporting actors:** Orchestrator (`/refresh-wiki` command), Fact-checker agents, Writer agents (wiki-writer, shared with UC-03)
- **Trigger:** The user suspects the wiki has drifted from the source code -- source code has been updated, time has passed since the last sync, or the user wants to increase confidence in the wiki's accuracy.

## Agent responsibilities

Each agent has a single drive. Separation exists because no single drive can protect all the concerns at play. UC-04 is an abbreviated UC-02 + UC-03 without the GitHub Issues message queue in the middle -- the fact-checker replaces the reviewer's accuracy lens, and the writer is reused from UC-03's remediation drive.

- **Orchestrator** -- Drive: coordination. Resolves the workspace, absorbs editorial context, identifies recent source code changes as priority context, dispatches fact-checkers across all wiki pages, collects assessments, dispatches writers for pages with drift, compiles the sync report, and presents it to the user. The orchestrator makes no editorial judgments and applies no corrections.

- **Fact-checker agents** -- Drive: verification. Each reads its assigned wiki page, identifies all sources of truth referenced in the content (source code files, external URLs, linked resources), and verifies every factual claim against those sources. The fact-checker's drive is to determine what is true -- not to fix anything, not to improve prose, not to reorganize. It produces a structured assessment: each claim is verified, inaccurate (with the correct fact and source reference), or unverifiable (source unreachable). Recent source code changes are provided as context to focus attention, but the fact-checker checks all claims on the page, not only those related to recent changes.

- **Writer agents** -- Drive: correction. Each receives a page and its fact-checker assessment, reads the page, reads the cited sources to independently verify the assessment, and applies targeted corrections. The writer's drive is to make inaccurate content accurate -- it does not improve prose, restructure sections, or add new content beyond what the correction requires. This is the same correction drive as UC-03's fixer agents. The writer agent is reusable between UC-03 and UC-04 because both consume a structurally compatible input: a page, a finding (what's wrong), a recommendation (what it should say), and a source reference (the authority).

## Invariants

See also: [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) for cross-cutting invariants (GitHub CLI, source readonly, config as identity, scripts own deterministic behavior, etc.)

- **Accuracy only -- no editorial changes.** UC-04 corrects facts. It does not tighten prose, fix grammar, reorganize structure, or standardize terminology. A fact-checker that flags a style problem has exceeded its mandate. A writer that "improves" a sentence while correcting a fact has exceeded its mandate. Structure, line, and copy concerns belong to UC-02.
- **No new pages.** UC-04 syncs existing pages. It does not create new wiki pages, even if source code introduces features not covered by any existing page. Flagging coverage gaps is UC-02's structure lens concern, not UC-04's.
- **Targeted edits, not rewrites.** Writers use surgical edits. Entire pages are not rewritten. The existing page structure, voice, and content beyond the correction are preserved.
- **No interaction with GitHub Issues.** UC-04 does not read, file, close, or comment on GitHub Issues. It is decoupled from the issue system entirely. If UC-02 has filed an accuracy issue that UC-04 independently corrects, the issue becomes stale -- UC-03 will skip it when it finds the quoted text no longer matches. This is an accepted gap in favor of keeping UC-04 fast and focused.
- **All sources of truth are in scope.** Source code is not the only authority. External references within wiki content (URLs, linked documentation, specifications) are also sources of truth. The fact-checker verifies claims against whatever the authoritative source is for that claim.
- **Unreachable sources are skipped, not guessed.** When an external source (URL, API) is unreachable, the fact-checker skips that verification and records it in the assessment. The writer does not attempt to correct claims it cannot verify. The report's errata section surfaces these gaps.
- **Git is the approval gate.** The user does not approve changes before they are applied. Corrections are written directly to wiki files. The user reviews changes after the fact using git (diff, log, revert). This is a deliberate design choice: UC-04 is autonomous, and git provides the safety net.
- **Repo freshness is the user's responsibility.** The system does not pull or verify that clones are up to date. The user is responsible for ensuring the workspace reflects the state they want verified.

## Success outcome

- Every factual claim in the wiki has been checked against its source of truth. Inaccurate claims have been corrected on disk. Accurate claims are untouched.
- A durable, time-stamped sync report exists on disk showing: pages checked, corrections applied (with what changed and source references), pages verified as accurate, and claims that could not be verified (with the unreachable source).
- The user can review all changes via git diff and revert any correction they disagree with.
- Running `/refresh-wiki` again produces fewer or no corrections, increasing confidence in wiki accuracy over successive runs.

## Failure outcome

- If failure occurs before writers are dispatched (workspace resolution, no content pages, all fact-checkers fail), no wiki files are modified. The user is told what failed.
- If some fact-checkers fail, pages they were responsible for are not checked. Pages that were successfully checked proceed through the pipeline. The report notes which pages were not covered.
- If some writers fail, successfully applied corrections remain on disk. The report notes which corrections failed. The user retries `/refresh-wiki` to pick up uncorrected drift.
- In all cases, whatever partial report can be compiled is written to disk, and the user is told what happened.

## Scenario

1. **User** -- Initiates a wiki sync by running `/refresh-wiki`.
2. **Orchestrator** -- Resolves the workspace and loads config (repo identity, source dir, wiki dir, audience, tone).
3. **Orchestrator** -- Absorbs editorial context: reads editorial guidance, wiki instructions, and the target project's CLAUDE.md if it exists.
4. **Orchestrator** -- Discovers all content pages in the wiki directory, excluding structural files (`_`-prefixed `.md` files). If no content pages exist, reports "nothing to sync" and stops.
5. **Orchestrator** -- Identifies recent source code changes to provide as priority context for fact-checkers. This scopes attention, not coverage -- fact-checkers check all claims on every page, but recent changes tell them where drift is most likely.
6. **Orchestrator** -- Dispatches fact-checker agents across all content pages. Each receives: the page path, the source directory, recent change context, audience, tone, and editorial guidance.
7. **Fact-checker agents** -- Each reads its assigned wiki page, identifies all sources of truth (source code files referenced or implied by the content, external URLs, linked resources), and verifies every factual claim. Each claim is assessed as: verified (accurate against source), inaccurate (with the correct fact and source reference), or unverifiable (source unreachable, with the source that could not be reached).
   --> DriftDetected (one per inaccurate claim found)
   --> DriftSkipped (one per unverifiable claim)
8. **Orchestrator** -- Collects all fact-checker assessments. For pages where all claims are verified and no drift was detected, records them as up-to-date. For pages with drift, dispatches writer agents.
9. **Writer agents** -- Each reads the page, reads the fact-checker's assessment, reads the cited source files to independently verify accuracy, and applies targeted corrections using the Edit tool. For each correction, the writer reports what changed and cites the source reference.
   --> DriftCorrected (one per applied correction)
10. **Orchestrator** -- Compiles the sync report from all domain events (DriftDetected, DriftCorrected, DriftSkipped) and writes it to disk as a time-stamped report.
    --> WikiSynced
11. **User** -- Reads the sync report. Reviews changes via git diff. Reverts any corrections they disagree with.

## Goal obstacles

### Step 2a -- No workspace exists

1. **Orchestrator** -- Reports that no workspace exists and directs the user to run `/up` first.
2. **Orchestrator** -- Stops.

### Step 2b -- Workspace not found for the given identifier

1. **Orchestrator** -- Reports that no workspace matches the provided identifier and lists available workspaces.
2. **Orchestrator** -- Stops.

### Step 4a -- No content pages in wiki

1. **Orchestrator** -- Reports "nothing to sync" -- the wiki directory contains no content pages. Directs the user to `/init-wiki` to populate the wiki first.
2. **Orchestrator** -- Stops.

### Step 7a -- One or more fact-checker agents fail

A fact-checker agent crashes, times out, or produces unusable results. The pages it was responsible for are not checked.

1. **Orchestrator** -- Records which pages were not checked.
2. **Orchestrator** -- Proceeds with the assessments from successful fact-checkers. Pages with drift are sent to writers. The report notes unchecked pages.

### Step 7b -- All external sources are unreachable

Network connectivity is degraded. No external URLs can be reached. Source code is still available locally.

1. **Fact-checker agents** -- Verify all source-code-grounded claims normally. Record all external-reference-based claims as unverifiable.
2. **Orchestrator** -- Proceeds with whatever drift was detected from source code verification. The report's errata section lists all unverifiable claims.

### Step 9a -- One or more writer agents fail

A writer agent crashes, times out, or produces unusable results. The corrections it was responsible for are not applied.

1. **Orchestrator** -- Records which pages failed. Successfully applied corrections from other writers remain on disk.
2. **Orchestrator** -- Includes the failures in the sync report. The user retries `/refresh-wiki` to pick up uncorrected drift.

### Step 9b -- Writer finds the fact-checker's assessment is wrong

The writer reads the cited source file and finds that the wiki is actually correct -- the fact-checker made an error in judgment.

1. **Writer agent** -- Skips the correction. Reports that the wiki content is accurate and the assessment was incorrect, citing the source evidence.
2. **Orchestrator** -- Records the skipped correction in the report. No change is made to the wiki page.

## Domain events

- **DriftDetected** -- A fact-checker has found that a wiki claim does not match its source of truth. Internal to Drift Detection. Carries: page, the inaccurate claim (quoted text), the correct fact, the source reference (file path and line, URL, or other identifier). Structurally compatible with UC-03's writer input: both provide a page, a finding (what's wrong), a recommendation (what it should say), and a source reference. This compatibility enables writer agent reuse.

- **DriftSkipped** -- A fact-checker could not verify a claim because its source of truth was unreachable. Internal to Drift Detection. Carries: page, the unverifiable claim (quoted text), the unreachable source (URL, API endpoint, etc.). Surfaces in the report's errata section.

- **DriftCorrected** -- A writer has applied a correction to a wiki page. The fix is on disk. Internal to Drift Detection. Carries: page, the original claim (quoted text), the corrected text, the source reference. Materializes in the sync report.

- **WikiSynced** -- The sync operation has completed. The completion event for Drift Detection, analogous to WikiReviewed (UC-02) and WikiRemediated (UC-03). Carries: pages checked count, corrections applied count, claims skipped (unverifiable) count, pages up-to-date count, pages unchecked (fact-checker failure) count. Materialized as the sync report on disk.

## Protocols

- **workspace.config.yml** -- step 2, input. The workspace config provides repo identity, source dir, wiki dir, audience, and tone. Contract defined in UC-05.
- **Fact-checker assessment** -- step 7, output from each fact-checker agent. A structured report for one wiki page listing every factual claim checked, with verdict (verified, inaccurate, unverifiable), the quoted claim text, the correct fact (if inaccurate), the source reference, and the unreachable source (if unverifiable). Consumed by the orchestrator to dispatch writers and compile the report.
- **Correction assignment** -- step 8, input to each writer agent. Contains: the page path, the list of inaccurate claims from the fact-checker assessment (each with quoted text, correct fact, and source reference), audience, tone, and editorial guidance. Structurally compatible with UC-03's fixer input -- both provide a page, findings, recommendations, and source references. This shared structure is what enables writer agent reuse between UC-03 and UC-04.
- **Sync report** -- step 10, output. A markdown file written to `workspace/reports/{owner}/{repo}/{date-time}/sync-report.md`. Time-stamped and durable -- reports accumulate across runs so the user can track accuracy over time. Contains: run metadata (repo, timestamp), corrections applied (page, original text, corrected text, source reference), pages verified as up-to-date, errata (unverifiable claims with unreachable sources), unchecked pages (fact-checker failures). The report template is the source of truth for the agent formatting the output.

## Notes

- **Accuracy only, by design.** UC-04 is a single-lens operation. UC-02 applies four editorial lenses (structure, line, copy, accuracy). UC-04 applies only the accuracy lens equivalent -- but with broader scope, since it verifies against external references as well as source code. UC-02's accuracy lens is strictly source-code-grounded; UC-04's fact-checking includes any source of truth referenced in the wiki content. This is a noted gap in UC-02 that may be addressed in a future revision.
- **No `-plan` flag.** The command file currently supports `-plan` to stop after assessment. The use case removes this. Every run produces a different outcome based on the current state of source code and external references, making dry runs an inefficient use of tokens. The user reviews changes after the fact via git diff.
- **Git is the approval gate, not a confirmation step.** UC-01 requires plan approval before writing. UC-04 does not. The user trusts the system to make corrections and uses git as the post-hoc safety net. This is appropriate because UC-04 makes targeted factual corrections, not structural decisions. The risk of a bad correction is low and easily reversible.
- **Writer agent reuse.** The writer agent is shared between UC-03 and UC-04. Both consume the same structural input: a page, a finding (what's wrong), a recommendation (what it should say), and a source reference. In UC-03, this input comes from parsed GitHub Issues. In UC-04, it comes from the fact-checker assessment. The correction assignment protocol is designed to be compatible with both sources.
- **Recent changes are context, not scope.** The orchestrator identifies recent source code changes (step 5) and provides them to fact-checkers as priority context. Fact-checkers use this to focus attention on areas where drift is most likely. But they check all claims on every page -- recent changes do not filter which pages or claims are examined. A wiki page that references no recently changed source files still has its external references and stable source code claims verified.
- **Idempotent in spirit.** Running `/refresh-wiki` multiple times is expected and encouraged. Each run may catch drift that a previous run missed. Over successive runs, the wiki converges toward full accuracy. The user cannot prove completeness -- you cannot prove a negative -- but repeated runs increase confidence.
- **Stale UC-02 issues are an accepted gap.** If UC-02 has filed an accuracy issue and UC-04 independently corrects the same inaccuracy, the GitHub issue becomes stale. When the user runs `/resolve-issues` (UC-03), the fixer will find that the quoted text no longer exists and skip the issue. This is a known consequence of UC-04's independence from the issue system, accepted in favor of keeping UC-04 fast and focused.
- **Report accumulation.** Sync reports are time-stamped and stored persistently. The user can compare reports across runs to see trends: are the same pages drifting repeatedly? Are external references becoming unreachable? This supports subjective judgment about the system's effectiveness. The report path (`workspace/reports/{owner}/{repo}/{date-time}/`) is outside both clones, keeping them uncontaminated.
- **Implementation gap: command file scope is too narrow.** The current command file only checks wiki pages mapped to recently changed source files. The use case checks all content pages against all sources of truth, with recent changes as a priority hint. The command file needs to be updated to reflect this broader scope.
- **Implementation gap: command file supports `-plan` flag.** The use case removes this. The command file should be updated.
- **Implementation gap: command file uses "last 50 commits" heuristic.** The use case says "recent source code changes" without prescribing a specific commit count. The implementation may use 50 commits, HEAD-based diffs, or date-based ranges -- this is an implementation detail.
- **Implementation gap: command file has no report output.** The command file produces a console summary table but does not write a durable report to disk. The use case requires a persistent, time-stamped sync report.
- **Relationship to other use cases:** UC-04 requires UC-05 (Provision Workspace) as a prerequisite. It typically follows UC-01 (Populate New Wiki) -- there must be content pages to sync. Its corrections may render UC-02 accuracy findings stale (accepted gap). It has no dependency on UC-03 (Resolve Documentation Issues) but shares the writer agent protocol. It has no dependency on UC-06 (Decommission Workspace).
