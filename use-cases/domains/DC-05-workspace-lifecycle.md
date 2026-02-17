# DC-05 -- Workspace Lifecycle

## Purpose

Owns the provisioning and decommissioning of project workspaces. A workspace is the configuration, source clone, and wiki clone for one GitHub project. All other bounded contexts discover workspaces at runtime by scanning for config files. This context does not read or interpret project content -- that belongs to the editorial contexts.

## Ubiquitous language

- **Workspace config** -- A `workspace.config.md` file containing repo identity, source dir, wiki dir, audience, and tone. The contract between Workspace Lifecycle and all other bounded contexts.
- **Source clone** -- A readonly clone of the source repository, used as reference material.
- **Wiki clone** -- A clone of the wiki repository, the mutable working copy for all editorial operations.
- **Safety check** -- Inspection of the wiki working tree for uncommitted changes and unpushed commits before decommissioning.

## Use cases

- [UC-05](../UC-05-provision-workspace.md) -- Clone repos and write config for a new project workspace
- [UC-06](../UC-06-decommission-workspace.md) -- Remove a project workspace with safety checks for unpublished work

## Domain events produced

- [DE-06 WorkspaceProvisioned](DOMAIN-EVENTS.md#de-06----workspaceprovisioned)
- [DE-07 WorkspaceDecommissioned](DOMAIN-EVENTS.md#de-07----workspacedecommissioned)

## Integration points

- **Required by:** All operational contexts (DC-01 through DC-04) -- workspace must exist before any editorial operation.
- **Inverse operations:** UC-05 provisions, UC-06 decommissions. They never chain.
