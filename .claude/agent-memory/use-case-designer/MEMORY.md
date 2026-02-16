# Use Case Designer Memory

## Domain terminology

- **WorkspaceProvisioned** -- domain event from UC-05. Materialized as the config file on disk, not a message.
- **WorkspaceDecommissioned** -- domain event from UC-06. Inverse of WorkspaceProvisioned. The workspace stops existing.
- **WikiPopulated** -- domain event from UC-01. Wiki directory goes from empty to fully populated. Carries: repo identity, sections with pages (hierarchical), audience, tone, wiki dir path.
- **Workspace identity** -- defined by the existence of `workspace/config/{owner}/{repo}/workspace.config.yml`. No config = no workspace.
- **Drift Detection** -- bounded context for UC-04. Separate from exploration and correction.
- **Wiki Creation** -- bounded context for UC-01. Separate from review (UC-02) and sync (UC-04).
- **Editorial Review** -- bounded context for UC-02. Separate from creation (UC-01) and resolution (UC-03).
- **Editorial lens** -- replaces "pass." The four lenses (structure, line, copy, accuracy) are parallel editorial disciplines, not serial steps. Each has its own drive and input requirements.
- **IssueIdentified** -- domain event from UC-02. Reviewer finds a problem. Internal to Editorial Review. Carries: page, lens, severity, finding, recommendation, source file.
- **IssueToBeFiled** -- domain event from UC-02. Deduplicator confirms finding is new. Carries same payload as IssueIdentified.
- **FindingFiled** -- domain event from UC-02. GitHub issue created. Published event crossing into Issue Resolution (UC-03). Carries: issue number + IssueIdentified payload.
- **WikiReviewed** -- domain event from UC-02. Review complete. Carries stats. Success = identified after dedup == filed.
- **Issue Resolution** -- bounded context for UC-03. Separate from review (UC-02) and creation (UC-01).
- **IssueCorrected** -- domain event from UC-03. Fixer applied a recommendation to a wiki page. Internal to Issue Resolution. Carries: issue number, page, editorial lens, change description.
- **IssueSkipped** -- domain event from UC-03. Fixer could not remediate an issue. Internal to Issue Resolution. Carries: issue number, page, reason.
- **IssueCloseDeferred** -- domain event from UC-03. Fix applied on disk but GitHub issue could not be closed. Carries: issue number, page, error detail.
- **WikiRemediated** -- domain event from UC-03. Remediation run complete. Carries: corrected count, skipped count, close-deferred count, remaining open count.
- **Remediation drive** -- fixer agent drive in UC-03. Applying known fixes to known problems. Not discovery (UC-02) and not production (UC-01).

## Cross-cutting invariants

- **GitHub CLI installed** -- applies to ALL use cases, not any single one. If `gh` is not installed, notify the user.
- **Clones reflect remote state** -- operations that read or mutate a clone must operate against latest remote state. Each use case enforces this differently (ff-only, rebase, etc.). Fresh clones satisfy trivially.
- **Source repo is readonly** -- born at provisioning, enforced system-wide.

## Design decisions

- Authentication (`gh auth status`) is NOT our concern -- it belongs to `gh` itself. We only check that `gh` is installed.
- "Getting latest" (git pull) is a shared invariant, not a use case. Each use case enforces freshness in its own way.
- Context absorption (reading target CLAUDE.md, _Sidebar.md) happens in `/up` as UX convenience AND independently in each downstream command. It is not part of the provisioning contract.
- Audience and tone are immutable after provisioning. No edit path exists; user must `/down` then `/up`.
- **Wiki repo must exist before provisioning.** User must create Home page via GitHub UI first. No CLI/API can create a wiki. Updated in UC-05 as invariant.
- **Commands do not chain.** Each command is a self-contained interaction. User cancels, uses other tools, comes back.
- **UC-07 (Publish Wiki Changes) is OUT OF SCOPE.** Users commit and push using their own git tools. The system does not own the publish workflow. Design decisions recorded before scoping out: semantic commit messages (diff-based), no confirmation gate, pull --rebase before push.
- **No CLI-style flags on agent commands.** No `--force`, no `--all`. These are agent interactions, not C programs. Confirmation is done through typed repo name, not flags.
- **Type-to-confirm pattern.** When destructive action threatens unpublished work, user types the repo name (e.g., `acme/WidgetLib`) to confirm. Established in UC-06.
- **Repo freshness is user's responsibility.** System does not pull or verify clones are up to date. User owns this. Clarifies shared invariant "clones reflect remote state." Established in UC-01.
- **Actors have drives.** PHILOSOPHY.md updated with three new principles: actors have drives, drives explain separation, goal conflicts spawn actors. Agent responsibilities sections now describe drives, not just tasks.
- **Structural files vs. content pages.** Home.md, _Sidebar.md, _Footer.md are structural. "New wikis only" invariant ignores them. Established in UC-01.
- **Partial completion design gap.** If writers partially fail in UC-01, user cannot re-run `/init-wiki`. Future UC for interactive wiki refactoring would address this.
- **GitHub is a sub-system.** GitHub Issues is our event queue / durable event store, not an external system. Issues are durable facts within our system boundary. Established in UC-02.
- **`--pass` flag removed from UC-02.** Every invocation runs all four editorial lenses. No CLI-style flags. Command file needs updating.
- **Dispatch pattern is implementation.** Use case specifies input requirements per lens (whole-wiki, per-page, cross-page). How to satisfy them (agent count, parallelism) is implementation.
- **Explorer facets are extensible.** API surface, architecture, configuration are the minimum three. Projects may warrant more.
- **Sidebar validation is reviewer work.** Structure lens checks sidebar integrity, not the orchestrator.
- **Local fallback path for issues.** `workspace/reviews/{owner}/{repo}/{date-time}/` -- outside both clones. Used when GitHub is unreachable or individual filings fail.
- **Deduplicator is a dedicated agent.** Not orchestrator work. Separate drive: filtering. Compares findings against open issues labeled `documentation`.
- **Remediation drive vs. resolution.** "Resolve issues" is the command name, but the drive is remediation (applying fixes). Issue closure is a consequence, not the goal. An agent optimizing for closure would be tempted to close without fixing. Established in UC-03.
- **No scope selection for /resolve-issues.** No `-plan` flag, no issue number filters, no page name filters. Remediates all open actionable issues. Scope narrowing, if needed, through conversation.
- **Unstructured issues are invisible.** Issues not following wiki-docs.yml template are skipped silently. System only processes what it can parse.
- **`needs-clarification` label.** When fixer skips due to ambiguity, orchestrator adds `needs-clarification` label to GitHub issue. Makes ambiguous issues filterable.

## Implementation gaps found

- `/up` command file writes config BEFORE cloning; clone script clones first THEN writes config. Script ordering is safer.
- Command file and clone script are dual implementations of the same logic -- command does not call the script.
- `/down` command file supports `--force`, `--all`, inlines git commands. Needs update: single workspace, always check safety, type-to-confirm, delegate to scripts.
- `/proofread-wiki` command file supports `--pass` flag. Use case removes it -- always run all four lenses. Command needs updating.
- `/proofread-wiki` command file uses "pass" terminology throughout. Use case uses "editorial lens." Command needs terminology update.
- `/proofread-wiki` command file has orchestrator do sidebar validation (Phase 1). Use case assigns this to the structure lens reviewer.
- `/proofread-wiki` command file does not clean up `.proofread/` cache. Use case requires cache cleanup.
- `/proofread-wiki` local fallback path in command writes to `issues/{sourceDir}/`. Use case writes to `workspace/reviews/{owner}/{repo}/{date-time}/`.
- `/resolve-issues` command file supports `-plan` flag and scope arguments (issue numbers, page names). Use case removes all of these.
- `/resolve-issues` command file uses "Pass" in parsed fields. Use case uses "Editorial lens." Command needs terminology update.
- `/resolve-issues` command file description says "docs-labeled." Actual label is `documentation`. Terminology mismatch.
- `close-issue.sh` does not support adding labels. UC-03 requires adding `needs-clarification` label. Script needs `--label` option or separate `gh issue edit --add-label` call.

## Use case map

See `C:\Users\Owner\.claude\projects\D--wiki-agent\memory\MEMORY.md` for the full 7-UC map.

## Conventions established

- File naming: `UC-{number}-{short-kebab-name}.md`
- Em dashes (--) not en dashes in prose
- "System" as actor name when no specific agent is involved (User-driven workflows)
- "Orchestrator" as actor name when `/init-wiki` (or similar agent-orchestrated commands) coordinates agents
- Domain events in PastTense: WorkspaceProvisioned, WikiPopulated
- Obstacles keyed to scenario steps as `{Step}a`
- Agent responsibilities section describes drives and why separation exists, not just task lists
