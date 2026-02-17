# UC-03 -- Resolve Documentation Issues

## Goal

Every actionable documentation problem tracked in GitHub Issues has its recommended correction applied to the wiki. The wiki content is fixed -- inaccuracies corrected, prose tightened, structure improved, terminology standardized. Issue closure is a consequence of successful remediation, not the goal itself. An issue closed without the fix actually applied is a violation.

## Context

- **Bounded context:** [DC-03 Issue Resolution](domains/DC-03-issue-resolution.md)
- **Primary actor:** User
- **Supporting actors:** [Fulfillment orchestrator](ACTOR-CATALOG.md#fulfillment-orchestrator) (`/resolve-issues` command), [Correctors](ACTOR-CATALOG.md#correctors) (one per wiki page with issues)
- **Trigger:** The user has open documentation issues (typically produced by UC-02) and wants the recommended corrections applied to the wiki.

## Agent responsibilities

See also: [ACTOR-CATALOG.md](ACTOR-CATALOG.md) for full actor definitions, drives, and the appearance matrix.

Each agent has a single drive. Separation exists because no single drive can protect all the concerns at play.

- **[Fulfillment orchestrator](ACTOR-CATALOG.md#fulfillment-orchestrator)** -- Drive: fulfillment. Resolves the workspace, absorbs editorial context, fetches and parses issues, filters out unapplicable issues, groups actionable issues by wiki page, dispatches correctors, collects results, closes or comments on issues via scripts, and presents the summary. The fulfillment orchestrator makes no editorial judgments and applies no fixes.

- **[Correctors](ACTOR-CATALOG.md#correctors)** -- Drive: remediation. Each receives a wiki page and its associated issues, reads the page, reads source code for accuracy issues, and applies each recommendation using targeted edits. The corrector's drive is to apply known fixes to known problems -- it does not discover new problems (that is UC-02's critique drive) and it does not create new content (that is UC-01's production drive). The corrector trusts the recommendation unless it contradicts source code, the target text no longer exists, or the recommendation is ambiguous. When the corrector cannot apply a recommendation, it skips the issue with a reason rather than guessing.

## Invariants

See also: [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) for cross-cutting invariants (GitHub CLI, source readonly, config as identity, scripts own deterministic behavior, etc.)

- **Remediate, never create.** Correctors apply corrections to existing wiki content. They do not add new pages, new sections, or substantial new content. If a structural issue's recommendation calls for adding a new section, the corrector applies it. But the corrector never generates content beyond what the recommendation describes.
- **Only close what you fixed.** An issue is closed only when the recommended correction has been applied to the wiki file and the edit tool reported success. An issue closed without the fix applied is a violation. This is the structural guarantee that issue closure tracks actual remediation.
- **Source code is readonly.** Correctors read source code to verify accuracy recommendations but never modify it. If an accuracy recommendation contradicts the source code, the corrector skips the issue -- it does not "fix" the source.
- **Targeted edits, not rewrites.** Correctors use the Edit tool for surgical changes. Entire pages are not rewritten unless a structural issue specifically requires it. The existing page structure, voice, and content beyond the finding are preserved.
- **Unstructured issues are skipped.** Issues that do not follow the `documentation-issue.md` template format (missing Page, Finding, or Recommendation fields) are not actionable by the system. They are skipped without comment -- the system does not attempt to interpret freeform issue text.
- **Idempotency.** Running `/resolve-issues` twice is safe. If the quoted text from a finding no longer exists in the wiki (because a previous run or manual edit already addressed it), the corrector skips the issue. New issues filed since the last run are picked up.
- **Editorial guidance is current.** Correctors read the current editorial guidance and wiki instructions before applying fixes. Editorial standards may have evolved since the issue was filed. The applied fix conforms to current guidance, not just the recommendation text.
- **No scope selection arguments.** The command remediates all open actionable documentation issues. There are no flags (`-plan`), issue number filters, or page name filters. If scope narrowing is ever needed, it happens through conversation, not arguments.
- **Repo freshness is the user's responsibility.** The system does not pull or verify that clones are up to date. The user is responsible for ensuring the workspace reflects the state they want corrected.

## Success outcome

- Every actionable documentation issue has its recommended correction applied to the corresponding wiki page.
- Corrected issues are closed on GitHub with a comment noting the fix.
- Skipped issues remain open with a comment explaining why.
- Issues that needed clarification are labeled `needs-clarification` on GitHub.
- The user sees a brief summary: issues corrected, issues skipped, remaining open count.
- Wiki files on disk reflect all applied corrections.

## Failure outcome

- If failure occurs before correctors are dispatched (workspace resolution, issue fetching, parsing), no wiki files are modified. The user is told what failed.
- If some correctors succeed and others fail, successfully applied corrections remain on disk. The summary reports which pages were corrected and which correctors failed.
- If GitHub is unreachable when fetching issues, the system cannot operate -- issues are the input. The user is told and the system stops.
- If issue closing fails after a fix is applied, the fix remains on disk. The user is told which issues were fixed but not closed so they can close them manually.
- In all cases, the user is told what happened and what to do about it.

## Scenario

1. **User** -- Initiates remediation by running `/resolve-issues`.
2. **Fulfillment orchestrator** -- Resolves the workspace and loads config (repo identity, source dir, wiki dir, audience, tone).
3. **Fulfillment orchestrator** -- Absorbs editorial context for the target project.
4. **Fulfillment orchestrator** -- Fetches all open GitHub issues labeled `documentation` for this repository.
5. **Fulfillment orchestrator** -- Extracts actionable information from each issue. Issues that lack required structured fields are set aside as unapplicable.
6. **Fulfillment orchestrator** -- Organizes actionable issues for remediation.
7. **Fulfillment orchestrator** -- Dispatches correctors with their page assignments and context.
8. **Correctors** -- Each reads the wiki page, reads source files for accuracy issues, and applies each recommended correction. For each issue, the corrector reports: applied (with a description of the change) or skipped (with reason).
   --> IssueCorrected (one per applied issue)
   --> IssueSkipped (one per skipped issue)
9. **Fulfillment orchestrator** -- For applied issues, closes the GitHub issue with a comment noting the correction. For skipped issues, comments on the GitHub issue explaining why it was skipped. For issues skipped due to ambiguity or need for clarification, also adds the `needs-clarification` label.
   --> IssueCloseDeferred (one per issue where closing or commenting fails)
10. **Fulfillment orchestrator** -- Presents a brief summary: issues corrected, issues skipped (with reasons), issues where close failed, remaining open count.
    --> WikiRemediated

## Goal obstacles

### Step 2a -- No workspace exists

1. **Fulfillment orchestrator** -- Reports that no workspace exists and directs the user to run `/up` first.
2. **Fulfillment orchestrator** -- Stops.

### Step 2b -- Workspace not found for the given identifier

1. **Fulfillment orchestrator** -- Reports that no workspace matches the provided identifier and lists available workspaces.
2. **Fulfillment orchestrator** -- Stops.

### Step 4a -- GitHub is unreachable

The system cannot fetch issues. Unlike UC-02 (which has a local fallback for output), UC-03 has no fallback for input -- the issues live in GitHub.

1. **Fulfillment orchestrator** -- Reports that GitHub is unreachable and issues cannot be fetched.
2. **Fulfillment orchestrator** -- Stops. The user resolves the connectivity issue and retries.

### Step 4b -- No open documentation issues

No open issues with the `documentation` label exist. There is nothing to remediate.

1. **Fulfillment orchestrator** -- Reports that there are no open documentation issues.
2. **Fulfillment orchestrator** -- Stops. This is not a failure -- the wiki has no known problems.

### Step 5a -- All issues are unstructured

Every open documentation issue lacks the structured fields from the `documentation-issue.md` template. None are actionable by the system.

1. **Fulfillment orchestrator** -- Reports that all open issues lack structured fields and cannot be processed. Suggests the user review them manually on GitHub.
2. **Fulfillment orchestrator** -- Stops.

### Step 8a -- One or more correctors fail

A corrector crashes, times out, or produces unusable results. The page it was responsible for is not corrected.

1. **Fulfillment orchestrator** -- Reports which pages failed and which were successfully corrected.
2. **Fulfillment orchestrator** -- Proceeds with closing/commenting on issues for the pages that were successfully corrected.
3. The summary reports which pages were not addressed. The user retries `/resolve-issues` to pick up the remaining issues.

### Step 8b -- Recommendation contradicts source code

A corrector reads the source file for an accuracy issue and finds that the wiki is actually correct -- the recommendation is wrong.

1. **Corrector** -- Skips the issue. Reports that the recommendation contradicts the source code, citing the specific disagreement.
2. **Fulfillment orchestrator** -- Comments on the GitHub issue explaining the contradiction. The issue remains open for human review.

### Step 9a -- Issue close or comment fails

The fix was applied to the wiki file on disk, but the GitHub API call to close or comment on the issue fails.

1. **Fulfillment orchestrator** -- Records the failure. The wiki file already contains the correction.
   --> IssueCloseDeferred
2. **Fulfillment orchestrator** -- Continues processing remaining issues.
3. The summary reports issues that were fixed on disk but not closed on GitHub, so the user can close them manually.

## Domain events

See [DOMAIN-EVENTS.md](domains/DOMAIN-EVENTS.md) for full definitions of published events.

### Published events

- [DE-04 WikiRemediated](domains/DOMAIN-EVENTS.md#de-04----wikiremediated) -- Remediation run completed.

### Internal events

- **IssueCorrected** -- A corrector has applied a recommendation. Consumed by the fulfillment orchestrator to close the GitHub issue.
- **IssueSkipped** -- A corrector could not remediate an issue. Consumed by the fulfillment orchestrator to comment on the GitHub issue.
- **IssueCloseDeferred** -- Fix applied but GitHub issue could not be closed (API failure). Surfaced in summary.

## Protocols

- **workspace.config.md** -- step 2, input. The workspace config provides repo identity, source dir, wiki dir, audience, and tone. Contract defined in UC-05.
- **Issue body (documentation-issue.md)** -- step 5, input. The published protocol between UC-02 (producer) and UC-03 (consumer). Each GitHub issue body conforms to the `.claude/forms/documentation-issue.md` schema. Fields: Page, Editorial lens, Severity, Finding, Recommendation, Source file, Notes. UC-03 parses these fields to determine what to fix and where.
- **fetch-docs-issues.sh** -- step 4, input: config path, output: JSON array of open issues labeled `documentation`. Delegates to `gh issue list`.
- **close-issue.sh** -- step 9, input: issue number, comment text, config path. Closes the issue with a comment (`--comment`) or comments without closing (`--skip`). Used for both applied and skipped issues.
- **Corrector report** -- step 8, output from each corrector. A structured report listing each issue it processed with status (applied or skipped), description of the change (if applied), and reason (if skipped).

## Notes

- **Remediation, not resolution.** The drive is applying fixes, not closing tickets. "Resolve issues" is the command name for discoverability, but the use case goal is wiki correction. This distinction matters: an agent that optimizes for closing issues would be tempted to close without fixing. An agent that optimizes for remediation applies the fix and lets closure follow naturally.
- **Consuming UC-02's output.** UC-03 consumes FindingFiled events from UC-02 via GitHub Issues. The issue body conforming to `documentation-issue.md` is the published protocol. UC-03 has no dependency on UC-02's internal state (proofread cache, explorer summaries) -- only on the durable GitHub issues.
- **Unstructured issues are invisible.** Manually created issues that do not follow the template format are skipped silently. The system does not comment on them or mark them. This is a deliberate boundary: the system only processes what it can parse. Users who want manual issues resolved must do so manually.
- **Conflicting edits on the same section.** When multiple issues affect the same section of a wiki page, the corrector must coordinate edits so they do not conflict. This is an implementation concern -- the corrector applies edits sequentially within a page, reading the page state between edits if necessary. Not modeled as a use-case-level obstacle because it is a coordination problem internal to the corrector, not a threat to the goal.
- **`needs-clarification` label.** When a corrector skips an issue because the recommendation is ambiguous or needs human input, the fulfillment orchestrator adds a `needs-clarification` label to the GitHub issue (in addition to commenting). This makes ambiguous issues filterable and queryable on GitHub. The `documentation` label remains.
- **Implementation gap: `close-issue.sh` does not support adding labels.** The use case requires adding a `needs-clarification` label to skipped issues, but the current script only supports closing with a comment or commenting without closing. The script needs a `--label` option or a separate `gh issue edit --add-label` call.
- **Implementation gap: command file uses old terminology.** The command file references "Pass" in the parsed fields. The issue template uses "Editorial lens." The command file should be updated to match.
- **Implementation gap: command file supports `-plan` and scope arguments.** The use case removes these. The command file should be updated to remediate all open actionable issues without scope selection.
- **Implementation gap: command file uses `docs` label reference.** The command file description mentions "docs-labeled" issues. The actual label is `documentation` (matching the issue template). Terminology should be aligned.
- **Implementation: editorial context sources.** Step 3 absorbs editorial context from: editorial guidance (`.claude/guidance/editorial-guidance.md`), wiki instructions (`.claude/guidance/wiki-instructions.md`), and the target project's CLAUDE.md if it exists (`{sourceDir}/CLAUDE.md`).
- **Implementation: issue parsing.** Step 5 parses each issue body against the `documentation-issue.md` template schema, extracting structured fields: Page, Editorial lens, Severity, Finding, Recommendation, Source file, Notes. The field schema is defined in the Protocols section.
- **Implementation: corrector dispatch.** Step 6 groups actionable issues by wiki page and notes source file references for accuracy issues. Step 7 dispatches one corrector per wiki page, providing the page path, parsed issues, source file paths, editorial guidance, audience, and tone.
- **Relationship to other use cases:** UC-03 requires UC-05 (Provision Workspace) as a prerequisite. It consumes FindingFiled events from UC-02 (Review Wiki Quality) via GitHub Issues. It has no dependency on UC-01 (Populate New Wiki), UC-04 (Sync Wiki with Source Changes), or UC-06 (Decommission Workspace). UC-02 and UC-03 share a published protocol (the issue body schema) but operate independently -- they do not share internal state.
