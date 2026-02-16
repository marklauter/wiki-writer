# UC-03 -- Resolve Documentation Issues

## Goal

Every actionable documentation problem tracked in GitHub Issues has its recommended correction applied to the wiki. The wiki content is fixed -- inaccuracies corrected, prose tightened, structure improved, terminology standardized. Issue closure is a consequence of successful remediation, not the goal itself. An issue closed without the fix actually applied is a violation.

## Context

- **Bounded context:** Issue Resolution
- **Primary actor:** User
- **Supporting actors:** Orchestrator (`/resolve-issues` command), Fixer agents (one per wiki page with issues)
- **Trigger:** The user has open documentation issues (typically produced by UC-02) and wants the recommended corrections applied to the wiki.

## Agent responsibilities

Each agent has a single drive. Separation exists because no single drive can protect all the concerns at play.

- **Orchestrator** -- Drive: coordination. Resolves the workspace, absorbs editorial context, fetches and parses issues, filters out unapplicable issues, groups actionable issues by wiki page, dispatches fixer agents, collects results, closes or comments on issues via scripts, and presents the summary. The orchestrator makes no editorial judgments and applies no fixes.

- **Fixer agents** -- Drive: remediation. Each receives a wiki page and its associated issues, reads the page, reads source code for accuracy issues, and applies each recommendation using targeted edits. The fixer's drive is to apply known fixes to known problems -- it does not discover new problems (that is UC-02's critique drive) and it does not create new content (that is UC-01's production drive). The fixer trusts the recommendation unless it contradicts source code, the target text no longer exists, or the recommendation is ambiguous. When the fixer cannot apply a recommendation, it skips the issue with a reason rather than guessing.

## Invariants

See also: [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) for cross-cutting invariants (GitHub CLI, source readonly, config as identity, scripts own deterministic behavior, etc.)

- **Remediate, never create.** Fixers apply corrections to existing wiki content. They do not add new pages, new sections, or substantial new content. If a structural issue's recommendation calls for adding a new section, the fixer applies it. But the fixer never generates content beyond what the recommendation describes.
- **Only close what you fixed.** An issue is closed only when the recommended correction has been applied to the wiki file and the edit tool reported success. An issue closed without the fix applied is a violation. This is the structural guarantee that issue closure tracks actual remediation.
- **Source code is readonly.** Fixers read source code to verify accuracy recommendations but never modify it. If an accuracy recommendation contradicts the source code, the fixer skips the issue -- it does not "fix" the source.
- **Targeted edits, not rewrites.** Fixers use the Edit tool for surgical changes. Entire pages are not rewritten unless a structural issue specifically requires it. The existing page structure, voice, and content beyond the finding are preserved.
- **Unstructured issues are skipped.** Issues that do not follow the `wiki-docs.yml` template format (missing Page, Finding, or Recommendation fields) are not actionable by the system. They are skipped without comment -- the system does not attempt to interpret freeform issue text.
- **Idempotency.** Running `/resolve-issues` twice is safe. If the quoted text from a finding no longer exists in the wiki (because a previous run or manual edit already addressed it), the fixer skips the issue. New issues filed since the last run are picked up.
- **Editorial guidance is current.** Fixers read the current editorial guidance and wiki instructions before applying fixes. Editorial standards may have evolved since the issue was filed. The applied fix conforms to current guidance, not just the recommendation text.
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

- If failure occurs before fixers are dispatched (workspace resolution, issue fetching, parsing), no wiki files are modified. The user is told what failed.
- If some fixer agents succeed and others fail, successfully applied corrections remain on disk. The summary reports which pages were corrected and which fixers failed.
- If GitHub is unreachable when fetching issues, the system cannot operate -- issues are the input. The user is told and the system stops.
- If issue closing fails after a fix is applied, the fix remains on disk. The user is told which issues were fixed but not closed so they can close them manually.
- In all cases, the user is told what happened and what to do about it.

## Scenario

1. **User** -- Initiates remediation by running `/resolve-issues`.
2. **Orchestrator** -- Resolves the workspace and loads config (repo identity, source dir, wiki dir, audience, tone).
3. **Orchestrator** -- Absorbs editorial context: reads editorial guidance, wiki instructions, and the target project's CLAUDE.md if it exists.
4. **Orchestrator** -- Fetches all open GitHub issues labeled `documentation` for this repository.
5. **Orchestrator** -- Parses each issue body against the `wiki-docs.yml` template schema, extracting structured fields: Page, Editorial lens, Severity, Finding, Recommendation, Source file, Notes. Issues that lack required structured fields are set aside as unapplicable.
6. **Orchestrator** -- Groups actionable issues by wiki page. For accuracy issues, notes the referenced source files that fixers will need to read.
7. **Orchestrator** -- Dispatches fixer agents, one per wiki page that has issues. Each receives: the page path, the list of parsed issues for that page, source file paths for accuracy issues, editorial guidance, audience, and tone.
8. **Fixer agents** -- Each reads the wiki page, reads source files for accuracy issues, and applies each recommendation using targeted edits. For each issue, the fixer reports: applied (with a description of the change) or skipped (with reason).
   --> IssueCorrected (one per applied issue)
   --> IssueSkipped (one per skipped issue)
9. **Orchestrator** -- For applied issues, closes the GitHub issue with a comment noting the correction. For skipped issues, comments on the GitHub issue explaining why it was skipped. For issues skipped due to ambiguity or need for clarification, also adds the `needs-clarification` label.
   --> IssueCloseDeferred (one per issue where closing or commenting fails)
10. **Orchestrator** -- Presents a brief summary: issues corrected, issues skipped (with reasons), issues where close failed, remaining open count.
    --> WikiRemediated

## Goal obstacles

### Step 2a -- No workspace exists

1. **Orchestrator** -- Reports that no workspace exists and directs the user to run `/up` first.
2. **Orchestrator** -- Stops.

### Step 2b -- Workspace not found for the given identifier

1. **Orchestrator** -- Reports that no workspace matches the provided identifier and lists available workspaces.
2. **Orchestrator** -- Stops.

### Step 4a -- GitHub is unreachable

The system cannot fetch issues. Unlike UC-02 (which has a local fallback for output), UC-03 has no fallback for input -- the issues live in GitHub.

1. **Orchestrator** -- Reports that GitHub is unreachable and issues cannot be fetched.
2. **Orchestrator** -- Stops. The user resolves the connectivity issue and retries.

### Step 4b -- No open documentation issues

No open issues with the `documentation` label exist. There is nothing to remediate.

1. **Orchestrator** -- Reports that there are no open documentation issues.
2. **Orchestrator** -- Stops. This is not a failure -- the wiki has no known problems.

### Step 5a -- All issues are unstructured

Every open documentation issue lacks the structured fields from the `wiki-docs.yml` template. None are actionable by the system.

1. **Orchestrator** -- Reports that all open issues lack structured fields and cannot be processed. Suggests the user review them manually on GitHub.
2. **Orchestrator** -- Stops.

### Step 8a -- One or more fixer agents fail

A fixer agent crashes, times out, or produces unusable results. The page it was responsible for is not corrected.

1. **Orchestrator** -- Reports which pages failed and which were successfully corrected.
2. **Orchestrator** -- Proceeds with closing/commenting on issues for the pages that were successfully corrected.
3. The summary reports which pages were not addressed. The user retries `/resolve-issues` to pick up the remaining issues.

### Step 8b -- Recommendation contradicts source code

A fixer reads the source file for an accuracy issue and finds that the wiki is actually correct -- the recommendation is wrong.

1. **Fixer agent** -- Skips the issue. Reports that the recommendation contradicts the source code, citing the specific disagreement.
2. **Orchestrator** -- Comments on the GitHub issue explaining the contradiction. The issue remains open for human review.

### Step 9a -- Issue close or comment fails

The fix was applied to the wiki file on disk, but the GitHub API call to close or comment on the issue fails.

1. **Orchestrator** -- Records the failure. The wiki file already contains the correction.
   --> IssueCloseDeferred
2. **Orchestrator** -- Continues processing remaining issues.
3. The summary reports issues that were fixed on disk but not closed on GitHub, so the user can close them manually.

## Domain events

- **IssueCorrected** -- A fixer agent has applied a recommendation to a wiki page. The fix is on disk. Carries: issue number, page, editorial lens, description of the change. Internal to Issue Resolution. Consumed by the orchestrator to close the corresponding GitHub issue.

- **IssueSkipped** -- A fixer agent has examined an issue and determined it cannot be remediated. Carries: issue number, page, reason (quoted text no longer present, recommendation is ambiguous, recommendation contradicts source code). Internal to Issue Resolution. Consumed by the orchestrator to comment on the GitHub issue.

- **IssueCloseDeferred** -- The orchestrator applied a fix to the wiki but could not close or comment on the GitHub issue (API failure). The fix is on disk; the issue remains open. Carries: issue number, page, error detail. Surfaced in the summary so the user can close the issue manually.

- **WikiRemediated** -- The remediation run has completed. Carries: issues corrected count, issues skipped count, issues close-deferred count, remaining open count. This is the completion event for Issue Resolution, analogous to UC-02's WikiReviewed.

## Protocols

- **workspace.config.yml** -- step 2, input. The workspace config provides repo identity, source dir, wiki dir, audience, and tone. Contract defined in UC-05.
- **Issue body (wiki-docs.yml)** -- step 5, input. The published protocol between UC-02 (producer) and UC-03 (consumer). Each GitHub issue body conforms to the `.github/ISSUE_TEMPLATE/wiki-docs.yml` schema. Fields: Page, Editorial lens, Severity, Finding, Recommendation, Source file, Notes. UC-03 parses these fields to determine what to fix and where.
- **fetch-docs-issues.sh** -- step 4, input: config path, output: JSON array of open issues labeled `documentation`. Delegates to `gh issue list`.
- **close-issue.sh** -- step 9, input: issue number, comment text, config path. Closes the issue with a comment (`--comment`) or comments without closing (`--skip`). Used for both applied and skipped issues.
- **Fixer report** -- step 8, output from each fixer agent. A structured report listing each issue it processed with status (applied or skipped), description of the change (if applied), and reason (if skipped).

## Notes

- **Remediation, not resolution.** The drive is applying fixes, not closing tickets. "Resolve issues" is the command name for discoverability, but the use case goal is wiki correction. This distinction matters: an agent that optimizes for closing issues would be tempted to close without fixing. An agent that optimizes for remediation applies the fix and lets closure follow naturally.
- **Consuming UC-02's output.** UC-03 consumes FindingFiled events from UC-02 via GitHub Issues. The issue body conforming to `wiki-docs.yml` is the published protocol. UC-03 has no dependency on UC-02's internal state (proofread cache, explorer summaries) -- only on the durable GitHub issues.
- **Unstructured issues are invisible.** Manually created issues that do not follow the template format are skipped silently. The system does not comment on them or mark them. This is a deliberate boundary: the system only processes what it can parse. Users who want manual issues resolved must do so manually.
- **Conflicting edits on the same section.** When multiple issues affect the same section of a wiki page, the fixer must coordinate edits so they do not conflict. This is an implementation concern -- the fixer applies edits sequentially within a page, reading the page state between edits if necessary. Not modeled as a use-case-level obstacle because it is a coordination problem internal to the fixer agent, not a threat to the goal.
- **`needs-clarification` label.** When a fixer skips an issue because the recommendation is ambiguous or needs human input, the orchestrator adds a `needs-clarification` label to the GitHub issue (in addition to commenting). This makes ambiguous issues filterable and queryable on GitHub. The `documentation` label remains.
- **Implementation gap: `close-issue.sh` does not support adding labels.** The use case requires adding a `needs-clarification` label to skipped issues, but the current script only supports closing with a comment or commenting without closing. The script needs a `--label` option or a separate `gh issue edit --add-label` call.
- **Implementation gap: command file uses old terminology.** The command file references "Pass" in the parsed fields. The issue template uses "Editorial lens." The command file should be updated to match.
- **Implementation gap: command file supports `-plan` and scope arguments.** The use case removes these. The command file should be updated to remediate all open actionable issues without scope selection.
- **Implementation gap: command file uses `docs` label reference.** The command file description mentions "docs-labeled" issues. The actual label is `documentation` (matching the issue template). Terminology should be aligned.
- **Relationship to other use cases:** UC-03 requires UC-05 (Provision Workspace) as a prerequisite. It consumes FindingFiled events from UC-02 (Review Wiki Quality) via GitHub Issues. It has no dependency on UC-01 (Populate New Wiki), UC-04 (Sync Wiki with Source Changes), or UC-06 (Decommission Workspace). UC-02 and UC-03 share a published protocol (the issue body schema) but operate independently -- they do not share internal state.
