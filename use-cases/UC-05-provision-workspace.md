# UC-05 -- Provision Workspace

## Goal

A new project workspace exists and is ready for wiki operations. The user can immediately run any downstream command (`/init-wiki`, `/proofread-wiki`, `/revise-wiki`, `/refresh-wiki`) and have it resolve the workspace without error.

## Context

- **Bounded context:** [DC-05 Workspace Lifecycle](domains/DC-05-workspace-lifecycle.md)
- **Primary actor:** User
- **Supporting actors:** GitHub (remote repository host), Git (cloning tool)
- **Trigger:** The user wants to manage wiki documentation for a GitHub project that does not yet have a workspace in this system.

## Agent responsibilities

No agents are involved. The User drives the interaction directly through the `/up` command, which coordinates all steps. This is a human-driven workflow, not an agent-orchestrated one.

## Invariants

See also: [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md) for cross-cutting invariants (GitHub CLI, source readonly, config as identity, scripts own deterministic behavior, etc.)

- **Provisioning never tears down.** `/up` will not remove, modify, or overwrite an existing workspace. Teardown is exclusively the concern of UC-06 (Decommission Workspace).
- **Both repos must pre-exist on GitHub.** The source repository and its wiki repository must both exist on GitHub before provisioning can complete. The wiki must have its Home page created via the GitHub UI -- no CLI or API endpoint exists to create a wiki programmatically.

## Success outcome

- Source repository is cloned into `workspace/{owner}/{repo}/` as a readonly reference.
- Wiki repository is cloned into `workspace/{owner}/{repo}.wiki/`.
- `workspace/artifacts/{owner}/{repo}/workspace.config.md` is written with repo identity, paths, audience, and tone.
- The user sees a summary of what was provisioned: repo identity, clone paths, config values (audience, tone), and suggested next steps (run `/init-wiki` to populate the wiki).

## Failure outcome

- No config file is written. No orphaned config or partial workspace state is left behind.
- The user is told what failed and what to do about it (fix authentication, correct the URL, etc.).
- Any directories created before the failure are cleaned up.

## Scenario

1. **User** -- Initiates provisioning by running `/up`.
2. **User** -- Provides the source repository clone URL, target audience, and writing tone in response to the interview prompts.
3. **System** -- Identifies the target repository from the provided clone URL.
4. **System** -- Confirms no workspace exists for this repository.
5. **System** -- Validates that the source repository exists on GitHub.
6. **System** -- Validates that the wiki repository exists on GitHub.
7. **System** -- Clones the source repository into the workspace.
8. **System** -- Clones the wiki repository into the workspace.
9. **System** -- Writes the workspace configuration file.
   --> WorkspaceProvisioned
10. **User** -- Sees a summary of the provisioned workspace: repo identity, clone paths, config values (audience, tone), and suggested next steps (run `/init-wiki` to populate the wiki).

## Goal obstacles

### Step 3a -- Clone URL is not a recognized GitHub URL

1. **System** -- Reports that the URL could not be parsed and shows the accepted formats (HTTPS and SSH).
2. **User** -- Provides a corrected URL. The scenario resumes at step 3.

### Step 4a -- Workspace already exists for this repository

1. **System** -- Reports that a workspace for this repository already exists and directs the user to run `/down` first if they want to start fresh.
2. **System** -- Stops. No state is modified.

### Step 5a -- Source repository does not exist on GitHub

1. **System** -- Reports that the repository could not be found on GitHub (not found, or permission denied).
2. **System** -- Stops. The user verifies the URL and their access, then retries `/up`.

### Step 6a -- Wiki does not exist on GitHub

1. **System** -- Reports that the wiki repository does not exist. The most likely cause is that the wiki has not been initialized.
2. **System** -- Provides instructions: navigate to the repository on GitHub, go to the Wiki tab, and create the Home page. GitHub wikis can only be initialized through the web UI -- no CLI or API endpoint exists.
3. **System** -- Waits for the user to confirm they have created the wiki.
4. **User** -- Creates the Home page on GitHub and confirms.
5. **System** -- Re-validates that the wiki now exists. If it does, the scenario resumes at step 7 (clone source). If it still does not exist, the system reports the issue and waits again.

### Step 7a -- Source clone fails

1. **System** -- Reports the clone failure (network error, permission denied, authentication failure).
2. **System** -- Cleans up any partial directory state. No config file is written.
3. **System** -- Stops. The user resolves the underlying issue and retries `/up`.

### Step 8a -- Wiki clone fails

1. **System** -- Reports the wiki clone failure. The wiki was validated as existing in step 6, so this is likely a network or authentication issue.
2. **System** -- Cleans up any partial directory state (source clone already created in step 7). No config file is written.
3. **System** -- Stops. The user resolves the underlying issue and retries `/up`.

## Domain events

See [DOMAIN-EVENTS.md](domains/DOMAIN-EVENTS.md) for full definitions.

- [DE-06 WorkspaceProvisioned](domains/DOMAIN-EVENTS.md#de-06----workspaceprovisioned) -- Workspace config written; discoverable by all operational contexts.

## Protocols

- **workspace.config.md** -- step 9, the output artifact of provisioning. This file is the contract between Workspace Lifecycle and all other bounded contexts. Its schema (repo, sourceDir, wikiDir, audience, tone) is consumed by the workspace selection procedure that every downstream command executes before operating.

## Notes

- **Validate before cloning.** The system verifies both the source repo and wiki repo exist on GitHub before attempting any clones. This provides clear, actionable error messages and enables the wait-and-retry flow for wiki creation.
- **Context absorption belongs to the editorial domain.** Reading the target project's CLAUDE.md and the wiki's `_Sidebar.md` is an editorial concern (UC-01, UC-02, UC-04), not a workspace lifecycle concern. Provisioning does not read or present project content.
- **Scripts own deterministic behavior.** (See [SHARED-INVARIANTS.md](SHARED-INVARIANTS.md).) The provisioning script (`provision-workspace.sh`) is the single source of truth for provisioning mechanics. The `/up` command delegates to it after collecting user inputs.
- **Audience and tone are immutable.** There is currently no edit path for these values. Changing them requires `/down` then `/up`.
- **Implementation: repository identification.** Step 3 extracts the owner and repository name by parsing the clone URL (supports both HTTPS and SSH formats).
- **Relationship to other use cases:** UC-05 is a prerequisite for UC-01 (Populate New Wiki), UC-02 (Review Wiki Quality), UC-03 (Revise Wiki), and UC-04 (Sync Wiki with Source Changes). UC-06 (Decommission Workspace) is its inverse. UC-07 (Publish Wiki Changes) is out of scope -- users commit and push using their own git tools.
