# UC-06 -- Decommission Workspace

## Goal

A project workspace ceases to exist. The system returns to the state it was in before the workspace was provisioned -- no config file, no source clone, no wiki clone, no leftover directories. The user can re-provision with `/up` if they choose, or simply move on. Unpublished wiki work is never silently destroyed.

## Context

- **Bounded context:** [DC-05 Workspace Lifecycle](domains/DC-05-workspace-lifecycle.md)
- **Primary actor:** User
- **Supporting actors:** Git (working tree inspection)
- **Trigger:** The user no longer needs the workspace for a given repository -- the wiki work is done, the project is archived, or the user wants to re-provision with different settings (audience, tone).

## Agent responsibilities

No agents are involved. The User drives the interaction directly through the `/down` command, which coordinates all steps. This is a human-driven workflow, not an agent-orchestrated one.

## Invariants

See also: [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) for cross-cutting invariants (GitHub CLI, source readonly, config as identity, scripts own deterministic behavior, etc.)

- **Decommissioning never provisions.** `/down` will not create, modify, or initialize any workspace state. Provisioning is exclusively the concern of UC-05 (Provision Workspace).
- **Unpublished work is never silently destroyed.** If the wiki working tree has uncommitted changes or unpushed commits, the system must inform the user and require explicit confirmation before proceeding. The system never skips the safety check.
- **Single workspace per invocation.** `/down` decommissions exactly one workspace. Batch removal is out of scope.

## Success outcome

- The source clone directory (`workspace/{owner}/{repo}/`) is removed.
- The wiki clone directory (`workspace/{owner}/{repo}.wiki/`) is removed.
- The config file (`workspace/config/{owner}/{repo}/workspace.config.md`) is removed.
- Empty parent directories under `workspace/config/` and `workspace/` are cleaned up.
- The user sees confirmation of what was removed: repo identity, directories deleted, config file deleted, and remaining workspace count. If other workspaces remain, lists them. If none remain, notes that `/up` can provision a new one.

## Failure outcome

- The workspace remains intact -- config, source clone, and wiki clone are all preserved.
- The user is told why decommissioning did not proceed (no workspace found, or user chose not to discard unpublished work).

## Scenario

1. **User** -- Initiates decommissioning by running `/down`.
2. **System** -- Resolves which workspace to decommission using the standard workspace selection procedure.
3. **System** -- Identifies the workspace components to remove.
4. **System** -- Checks the wiki working tree for uncommitted changes and unpushed commits.
5. **System** -- Removes all workspace artifacts.
   --> WorkspaceDecommissioned
6. **User** -- Sees confirmation of what was removed: repo identity, directories deleted, config file deleted, and remaining workspace count. If other workspaces remain, lists them. If none remain, notes that `/up` can provision a new one.

## Goal obstacles

### Step 2a -- No workspaces exist

1. **System** -- Reports that there are no workspaces to remove and suggests running `/up` first if the user intended to provision.
2. **System** -- Stops.

### Step 2b -- Workspace not found for the given identifier

1. **System** -- Reports that no workspace matches the provided identifier and lists the available workspaces.
2. **System** -- Stops.

### Step 4a -- Wiki has unpublished work

The wiki working tree has uncommitted changes, unpushed commits, or both. This is the critical safety gate.

1. **System** -- Reports the unsaved state: lists uncommitted files and/or unpushed commits.
2. **System** -- Informs the user: they can cancel and commit and push their changes using git before retrying, or type the repository name (e.g., `acme/WidgetLib`) to confirm deletion and discard the unpublished changes.
3. **User** -- Either types the repo name to confirm, or cancels.
4. If the user confirms, the scenario resumes at step 5. If the user cancels, the system stops and the workspace remains intact.

### Step 5a -- Removal fails

1. **System** -- Reports the failure (filesystem permissions, directory locked by another process).
2. **System** -- Stops. The workspace may be in a partial state. The user resolves the underlying issue and retries `/down`.

## Domain events

See [DOMAIN-EVENTS.md](domains/DOMAIN-EVENTS.md) for full definitions.

- [DE-07 WorkspaceDecommissioned](domains/DOMAIN-EVENTS.md#de-07----workspacedecommissioned) -- Workspace removed; no longer discoverable.

## Protocols

- **workspace.config.md** -- step 3, input to decommissioning. The config file is read to discover the source and wiki directory paths. This is the same contract defined in UC-05.
- **check-wiki-safety.sh** -- step 4, input: wiki directory path, output: structured report of uncommitted changes and unpushed commits (UNCOMMITTED, UNPUSHED flags with file/commit listings).
- **remove-workspace.sh** -- step 5, input: config file path. Parses the config, removes the source clone, wiki clone, config file, and empty parent directories. Does not perform safety checks -- the caller (step 4) owns that responsibility.

## Notes

- **No `--force` flag.** The system always checks for unsaved changes. This is an agent interaction, not a CLI tool. If unsaved changes exist, the user confirms by typing the repo name -- there is no flag to bypass the check.
- **No `--all` flag.** Decommissioning is single-workspace only. Batch removal, if needed, would be a separate use case.
- **Commands do not chain.** When unsaved work is detected, the system tells the user to publish their work using git (commit and push) but does not do it for them. The user cancels `/down`, publishes independently using whatever git tool they prefer, and then re-runs `/down`.
- **Source clone has no safety concern.** The source repo is readonly (invariant from UC-05). It was never mutated, so it can always be deleted without data loss. Only the wiki clone requires a safety check.
- **Scripts own deterministic behavior.** (See [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md).) The safety check (`check-wiki-safety.sh`) and removal (`remove-workspace.sh`) are separate scripts by design. The safety check produces a report; the removal script acts on it. The `/down` command should delegate to both scripts rather than inlining git commands.
- **Implementation gap: command vs. use case reconciliation.** The current `/down` command file supports `--force`, `--all`, and inlines git commands rather than delegating to scripts. It also uses a simple "proceed or abort" confirmation rather than requiring the user to type the repo name. The command file should be updated to match this use case: single workspace, always check safety, type-to-confirm, delegate to scripts.
- **Implementation: workspace discovery.** Step 3 reads `workspace.config.md` to locate the source and wiki directory paths.
- **Implementation: workspace removal.** Step 5 removes the source clone, wiki clone, config file, and empty parent directories under `workspace/config/` and `workspace/`.
- **Relationship to other use cases:** UC-06 is the inverse of UC-05 (Provision Workspace). It has no direct relationship to the editorial use cases (UC-01 through UC-04) -- it simply removes the workspace they operate on. If the user has unpublished wiki work, they should commit and push their changes using git before decommissioning.
