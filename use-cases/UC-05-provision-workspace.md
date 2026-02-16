# UC-05 -- Provision Workspace

## Goal

A new project workspace exists and is ready for wiki operations. The user can immediately run any downstream command (`/init-wiki`, `/proofread-wiki`, `/refresh-wiki`, `/save`) and have it resolve the workspace without error.

## Context

- **Bounded context:** Workspace Lifecycle
- **Primary actor:** User
- **Supporting actors:** GitHub (remote repository host), Git (cloning tool)
- **Trigger:** The user wants to manage wiki documentation for a GitHub project that does not yet have a workspace in this system.

## Agent responsibilities

No agents are involved. The User drives the interaction directly through the `/up` command, which coordinates all steps. This is a human-driven workflow, not an agent-orchestrated one.

## Invariants

- **One workspace per repository.** A workspace for a given `owner/repo` either exists or it does not. If the config file exists, provisioning refuses. There is no partial update, no overwrite, no merge.
- **Provisioning never tears down.** `/up` will not remove, modify, or overwrite an existing workspace. Teardown is exclusively the concern of UC-06 (Decommission Workspace).
- **Source repo is readonly.** The source clone is created during provisioning and must never be staged, committed, or pushed to by any use case in the system. It exists solely as reference material.
- **Config is the source of truth for workspace identity.** The existence of `workspace/config/{owner}/{repo}/workspace.config.yml` defines whether a workspace exists. Directories without a config file are not workspaces.
- **GitHub CLI is installed.** (Cross-cutting -- applies to all use cases.) The `gh` CLI must be available on the system. If it is not installed, the user is notified. Authentication is the concern of `gh` itself, not this system.

## Success outcome

- Source repository is cloned into `workspace/{owner}/{repo}/` as a readonly reference.
- Wiki repository is cloned into `workspace/{owner}/{repo}.wiki/` if the wiki exists on GitHub.
- `workspace/config/{owner}/{repo}/workspace.config.yml` is written with repo identity, paths, audience, and tone.
- The user sees a summary of what was provisioned: repo identity, paths, and config values.

## Failure outcome

- No config file is written. No orphaned config or partial workspace state is left behind.
- The user is told what failed and what to do about it (fix authentication, correct the URL, etc.).
- Any directories created before the failure are cleaned up.

## Scenario

1. **User** -- Initiates provisioning by running `/up`.
2. **User** -- Provides the source repository clone URL, target audience, and writing tone in response to the interview prompts.
3. **System** -- Extracts repository identity (owner and repo name) from the clone URL.
4. **System** -- Confirms no workspace exists for this repository.
5. **System** -- Clones the source repository into the workspace.
6. **System** -- Attempts to clone the wiki repository (non-fatal if the wiki does not exist yet).
7. **System** -- Writes the workspace configuration file.
   --> WorkspaceProvisioned
8. **User** -- Sees a summary of the provisioned workspace: repo identity, paths, and config values.

## Goal obstacles

### Step 3a -- Clone URL is not a recognized GitHub URL

1. **System** -- Reports that the URL could not be parsed and shows the accepted formats (HTTPS and SSH).
2. **User** -- Provides a corrected URL. The scenario resumes at step 3.

### Step 4a -- Workspace already exists for this repository

1. **System** -- Reports that a workspace for this repository already exists and directs the user to run `/down` first if they want to start fresh.
2. **System** -- Stops. No state is modified.

### Step 5a -- Source clone fails

1. **System** -- Reports the clone failure (network error, repository not found, permission denied, authentication failure).
2. **System** -- Cleans up any partial directory state. No config file is written.
3. **System** -- Stops. The user resolves the underlying issue (network, permissions, URL correctness) and retries `/up`.

### Step 6a -- Wiki clone fails

1. **System** -- Warns that the wiki repository could not be cloned. The project may not have its wiki initialized on GitHub yet.
2. **System** -- Continues with provisioning. The workspace is created without a wiki directory. The user can initialize the wiki later with `/init-wiki` or create the first page on GitHub to enable cloning.

## Domain events

- **WorkspaceProvisioned** -- A new workspace configuration file has been written to disk. This is the durable fact that all other bounded contexts discover at workspace selection time by scanning for config files matching `workspace/config/*/*/workspace.config.yml`. Carries: repo slug, source dir path, wiki dir path, audience, tone, and whether the wiki was successfully cloned.

## Protocols

- **workspace.config.yml** -- step 7, the output artifact of provisioning. This file is the contract between Workspace Lifecycle and all other bounded contexts. Its schema (repo, sourceDir, wikiDir, audience, tone) is consumed by the workspace selection procedure that every downstream command executes before operating.

## Notes

- **No repo validation before cloning.** The system does not pre-verify that the repository exists on GitHub. It attempts the clone and reports failure if it does not succeed. This is intentional -- `git clone` provides the most accurate error information.
- **Context absorption belongs to the editorial domain.** Reading the target project's CLAUDE.md and the wiki's `_Sidebar.md` is an editorial concern (UC-01, UC-02, UC-04), not a workspace lifecycle concern. Provisioning does not read or present project content.
- **Scripts own deterministic behavior.** All deterministic operations (git clone, gh API calls, config I/O, filesystem manipulation) belong in `.scripts/`, not inlined in command prompts. Scripts are testable, predictable, and immune to prompt drift. The LLM's role is judgment: interviews, analysis, content authoring. The clone script (`clone-workspace.sh`) is the single source of truth for provisioning mechanics. The `/up` command should delegate to it after collecting user inputs.
- **Implementation gap: command vs. script reconciliation.** The `/up` command file and `clone-workspace.sh` currently implement the same logic independently. The command file writes config before cloning; the script clones first then writes config. The script's ordering is safer (no orphaned config on clone failure). This use case follows the script's ordering and the command should be updated to delegate to the script.
- **Wiki directory absence.** Downstream commands that operate on the wiki directory must handle its absence gracefully when the wiki was not cloned during provisioning (obstacle 6a).
- **Audience and tone are immutable.** There is currently no edit path for these values. Changing them requires `/down` then `/up`.
- **Relationship to other use cases:** UC-05 is a prerequisite for UC-01 (Populate New Wiki), UC-02 (Review Wiki Quality), UC-03 (Resolve Documentation Issues), UC-04 (Sync Wiki with Source Changes), and UC-07 (Publish Wiki Changes). UC-06 (Decommission Workspace) is its inverse.
