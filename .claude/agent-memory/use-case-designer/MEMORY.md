# Use Case Designer Memory

## Domain terminology

- **WorkspaceProvisioned** -- domain event from UC-05. Materialized as the config file on disk, not a message.
- **WorkspaceDecommissioned** -- domain event from UC-06. Inverse of WorkspaceProvisioned. The workspace stops existing.
- **WikiPopulated** -- domain event from UC-01. Wiki directory goes from empty to fully populated. Carries: repo identity, sections with pages (hierarchical), audience, tone, wiki dir path.
- **Workspace identity** -- defined by the existence of `workspace/config/{owner}/{repo}/workspace.config.yml`. No config = no workspace.
- **Drift Detection** -- bounded context for UC-04. Separate from exploration and correction.
- **Wiki Creation** -- bounded context for UC-01. Separate from review (UC-02) and sync (UC-04).

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

## Implementation gaps found

- `/up` command file writes config BEFORE cloning; clone script clones first THEN writes config. Script ordering is safer.
- Command file and clone script are dual implementations of the same logic -- command does not call the script.
- `/down` command file supports `--force`, `--all`, inlines git commands. Needs update: single workspace, always check safety, type-to-confirm, delegate to scripts.

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
