# Shared Invariants

Cross-cutting rules that apply to every use case in the system. Individual use cases reference this document rather than restating these invariants.

## Multi-repo workspace architecture

This system manages wiki documentation for **multiple GitHub projects simultaneously**. Each project gets its own isolated workspace: a source clone, a wiki clone, and a config file. Workspaces are independent -- operations on one workspace never affect another.

The workspace directory structure enforces isolation:

```
workspace/
  config/{owner}/{repo}/workspace.config.md
  {owner}/{repo}/          # source clone (readonly)
  {owner}/{repo}.wiki/     # wiki clone (mutable)
```

Every use case (except UC-05, which creates the workspace) begins by resolving which workspace to operate on. This is handled by the **workspace selection protocol** (see Protocols section below).

## Invariants

- **GitHub CLI is installed.** The `gh` CLI must be available on the system. If it is not, the user is notified. Authentication is the concern of `gh` itself, not this system.

- **Source repo is readonly.** Source clones are reference material. No use case may stage, commit, or push to a source repo. This invariant is born in UC-05 (Provision Workspace) and enforced system-wide.

- **Config is the source of truth for workspace identity.** The existence of `workspace/config/{owner}/{repo}/workspace.config.md` defines whether a workspace exists. Directories without a config file are not workspaces. All workspace discovery is done by scanning for config files matching `workspace/config/*/*/workspace.config.md`.

- **One workspace per repository.** A workspace for a given `owner/repo` either exists or it does not. There is no partial state, no dual config, no overlapping workspaces for the same repo.

- **Repo freshness is the user's responsibility.** The system does not pull or verify that clones are up to date. UC-05 satisfies freshness trivially (fresh clone). All other use cases operate against whatever state the local clone is in. The user is responsible for pulling before running a command if they want to operate against the latest remote state.

- **Scripts own deterministic behavior.** All deterministic operations (git clone, gh API calls, config I/O, filesystem manipulation) belong in `.scripts/`, not inlined in command prompts. Scripts are testable, predictable, and immune to prompt drift. The LLM's role is judgment: interviews, analysis, content authoring.

- **Commands do not chain.** Each command (`/up`, `/down`, `/init-wiki`, etc.) is a self-contained interaction. One command never invokes another. If a command detects that the user should run a different command, it informs the user and stops.

- **No CLI-style flags.** Commands are agent interactions, not C programs. Confirmation and disambiguation happen through conversation, not `--force` or `--all` flags.

## Protocols

### Workspace selection

Every use case (except UC-05) begins by resolving which workspace to operate on. This is a shared protocol implemented by `resolve-workspace.sh`.

**Input:** Optional identifier token (`owner/repo` or just `repo`).

**Output (on success):** eval-able shell variables:
- `CONFIG_PATH` -- path to the workspace config file
- `REPO` -- `owner/repo` slug
- `SOURCE_DIR` -- path to source clone
- `WIKI_DIR` -- path to wiki clone
- `AUDIENCE` -- target audience from config
- `TONE` -- writing tone from config
- `OWNER` -- repository owner
- `REPO_NAME` -- repository name

**Algorithm:**
1. Scan for all config files under `workspace/config/`.
2. If none found -- no workspaces exist. Report and stop.
3. If an identifier token was provided, match it against `owner/repo` or `repo`. If no match -- report available workspaces and stop.
4. If exactly one workspace exists and no token was provided -- auto-select it.
5. If multiple workspaces exist and no token was provided -- list them and prompt the user to choose.

**Exit codes:**
- `0` -- resolved. Variables are printed to stdout.
- `1` -- no workspaces found.
- `2` -- multiple workspaces, none matched. Caller should prompt user.
- `3` -- identifier given but no match found.

### workspace.config.md

The config file is the contract between Workspace Lifecycle and all other bounded contexts. It uses `key: value` format:

```
repo: owner/repo
sourceDir: workspace/owner/repo
wikiDir: workspace/owner/repo.wiki
audience: target audience description
tone: writing tone/style
```

Created by UC-05 (Provision Workspace). Read by every other use case via workspace selection. Removed by UC-06 (Decommission Workspace).
