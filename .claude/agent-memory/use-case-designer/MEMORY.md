# Use Case Designer Memory

## Domain terminology

- **WorkspaceProvisioned** -- domain event from UC-05. Materialized as the config file on disk, not a message.
- **Workspace identity** -- defined by the existence of `workspace/config/{owner}/{repo}/workspace.config.yml`. No config = no workspace.
- **Drift Detection** -- bounded context for UC-04. Separate from exploration and correction.

## Cross-cutting invariants

- **GitHub CLI installed** -- applies to ALL use cases, not any single one. If `gh` is not installed, notify the user.
- **Clones reflect remote state** -- operations that read or mutate a clone must operate against latest remote state. Each use case enforces this differently (ff-only, rebase, etc.). Fresh clones satisfy trivially.
- **Source repo is readonly** -- born at provisioning, enforced system-wide.

## Design decisions

- Authentication (`gh auth status`) is NOT our concern -- it belongs to `gh` itself. We only check that `gh` is installed.
- "Getting latest" (git pull) is a shared invariant, not a use case. Each use case enforces freshness in its own way.
- Context absorption (reading target CLAUDE.md, _Sidebar.md) happens in `/up` as UX convenience AND independently in each downstream command. It is not part of the provisioning contract.
- Audience and tone are immutable after provisioning. No edit path exists; user must `/down` then `/up`.

## Implementation gaps found

- `/up` command file writes config BEFORE cloning; clone script clones first THEN writes config. Script ordering is safer.
- Command file and clone script are dual implementations of the same logic -- command does not call the script.

## Use case map

See `C:\Users\Owner\.claude\projects\D--wiki-agent\memory\MEMORY.md` for the full 7-UC map.

## Conventions established

- File naming: `UC-{number}-{short-kebab-name}.md`
- Em dashes (--) not en dashes in prose
- "System" as actor name when no specific agent is involved (User-driven workflows)
- Domain events in PastTense: WorkspaceProvisioned
- Obstacles keyed to scenario steps as `{Step}a`
