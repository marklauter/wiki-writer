# Subagent refactoring suggestions

Analysis of wiki-agent commands against the [Claude Code subagent documentation](https://code.claude.com/docs/en/sub-agents.md). Identifies concrete opportunities to replace inline Task-tool prompts with dedicated subagent definitions, and to adopt subagent features the project currently doesn't use.

## Current state

### How agents are used today

Every command lives in `.claude/commands/` as a skill (Markdown with YAML frontmatter). Commands that need parallel work — `init-wiki`, `refresh-wiki`, `proofread-wiki`, `revise-wiki` — manually spawn agents via the **Task tool** with long inline prompts embedded in the command file itself.

| Command | Agent pattern | Agent types spawned |
|---------|--------------|-------------------|
| `init-wiki` | 5 background Explore agents (Phase 1), 1 general-purpose planner (Phase 2), N background general-purpose writers (Phase 3) | Explore, general-purpose |
| `refresh-wiki` | N background Explore agents (Phase 2), N general-purpose updaters (Phase 3) | Explore, general-purpose |
| `proofread-wiki` | 3 background Explore summarizers (Phase 3), N background Explore reviewers (Phase 4), 1 general-purpose deduplicator (Phase 5) | Explore, general-purpose |
| `revise-wiki` | N background general-purpose fixers (Phase 2), N Bash closers (Phase 3) | general-purpose, Bash |

### What's missing

1. **No `.claude/agents/` directory exists.** Zero custom subagents are defined. All agent behavior is specified via inline prompts inside command files.
2. **No tool restrictions on agents.** Explorer agents get whatever tools the built-in Explore type provides, but writer/fixer agents use `general-purpose` with full tool access — they could accidentally modify the source repo.
3. **No persistent memory.** Agents start fresh every time. Knowledge about the target codebase, editorial patterns, or recurring issues is lost between sessions.
4. **No hooks.** The source-repo-readonly policy is enforced only by prose instructions in prompts, not structurally.
5. **No skill preloading.** Every agent prompt says "read `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md` before writing." This wastes agent turns on file reads that could be injected at startup.
6. **Massive prompt duplication.** The workspace selection procedure is copy-pasted verbatim into 6 of 7 commands. Editorial standards are inlined as a ~50-line section in `proofread-wiki.md`. Writing principles are repeated across `init-wiki`, `refresh-wiki`, and `revise-wiki`.

---

## Suggestions

### 1. Extract dedicated subagent definitions into `.claude/agents/`

The biggest structural improvement. Instead of embedding agent prompts inline in command files, define reusable subagent files with proper frontmatter configuration.

**Proposed agents:**

#### `wiki-explorer.md`

Replaces the ad-hoc Explore agents in `init-wiki` (Phase 1), `refresh-wiki` (Phase 2), and `proofread-wiki` (Phases 3-4).

```yaml
---
name: wiki-explorer
description: Read-only codebase explorer for wiki-agent. Examines source code and wiki pages to produce structured reports. Use proactively when comparing wiki content against source code.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: sonnet
memory: project
---
```

- **Why:** Every command that explores the codebase builds its own inline prompt with the same pattern: read source files, read wiki page, produce structured report. A dedicated subagent standardizes this.
- **Memory:** `project` scope so the explorer accumulates knowledge about the target codebase's file layout, naming conventions, and key source locations across sessions.
- **Model:** `sonnet` for speed. Exploration is high-volume, low-complexity.

#### `wiki-writer.md`

Replaces the general-purpose writer agents in `init-wiki` (Phase 3) and the update agents in `refresh-wiki` (Phase 3).

```yaml
---
name: wiki-writer
description: Writes and updates wiki pages from source code. Reads source files for accuracy, follows editorial guidance, and produces well-structured documentation.
tools: Read, Grep, Glob, Write, Edit
disallowedTools: Bash
model: opus
skills:
  - editorial-guidance
  - wiki-instructions
memory: project
---
```

- **Why:** Writing wiki pages is the core operation of `init-wiki` and `refresh-wiki`. A dedicated subagent with preloaded skills eliminates the repeated "read guidance files first" instruction and gives the writer immediate access to editorial standards.
- **Skills preloading:** `editorial-guidance` and `wiki-instructions` are injected at startup — no wasted turns reading files.
- **No Bash:** Writers have no legitimate need for shell access. Removing it eliminates the risk of accidental source-repo modifications.

#### `wiki-reviewer.md`

Replaces the Explore reviewer agents in `proofread-wiki` (Phase 4).

```yaml
---
name: wiki-reviewer
description: Senior technical editor that reviews wiki pages for structure, clarity, accuracy, and style. Produces structured findings. Use proactively after wiki content is written or updated.
tools: Read, Grep, Glob
disallowedTools: Write, Edit, Bash
model: opus
skills:
  - editorial-guidance
  - wiki-instructions
memory: project
---
```

- **Why:** Reviewers are strictly read-only. The current implementation uses `Explore` agents but gives them Bash access (via the built-in Explore type) for writing findings to disk. With a dedicated subagent, findings can be returned as the agent's output instead.
- **Reviewer memory:** Over multiple proofreading sessions, the reviewer learns which patterns and issues are common for this project, reducing false positives and improving finding quality.

#### `wiki-fixer.md`

Replaces the general-purpose fixer agents in `revise-wiki` (Phase 2).

```yaml
---
name: wiki-fixer
description: Applies corrections from documentation issues to wiki pages. Reads source code to verify accuracy, makes targeted edits, and reports results.
tools: Read, Grep, Glob, Edit
disallowedTools: Write, Bash
model: opus
skills:
  - editorial-guidance
  - wiki-instructions
---
```

- **Why:** Fixers should use `Edit` (targeted changes), never `Write` (full file replacement). The current prose instruction "use the Edit tool, not Write" would become a structural guarantee via `disallowedTools: Write`.

#### `doc-planner.md`

Replaces the general-purpose planner in `init-wiki` (Phase 2) and the deduplicator in `proofread-wiki` (Phase 5).

```yaml
---
name: doc-planner
description: Documentation architect that synthesizes exploration reports into wiki structure plans, and deduplicates findings against existing issues.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: opus
---
```

- **Why:** Planning and deduplication are analytical tasks that shouldn't modify files. Making this explicit via `disallowedTools` prevents accidental edits.

### 2. Add a PreToolUse hook to enforce the source-repo-readonly policy

The most important safety improvement. Currently, the source-repo-readonly policy is enforced only by a line in `CLAUDE.md`: "The source repo is READONLY. Never stage, commit, or push changes to it." This is a prompt-level constraint that agents can violate.

**Proposed hook** (in project `.claude/settings.json` or in subagent frontmatter):

```yaml
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: ".scripts/validate-wiki-only.sh"
```

With a validation script:

```bash
#!/bin/bash
# .scripts/validate-wiki-only.sh
# Blocks edits to anything outside wikiDir paths

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Allow edits to wiki directories, proofread cache, and refactor-issues
if echo "$FILE_PATH" | grep -qE '\.wiki/|\.proofread/|refactor-issues/'; then
  exit 0
fi

# Block edits to source repos under workspace/
if echo "$FILE_PATH" | grep -q 'workspace/'; then
  echo "Blocked: source repo is read-only. Only wiki repos can be modified." >&2
  exit 2
fi

exit 0
```

This turns a prose policy into a structural guarantee that applies to all agents regardless of their prompt instructions.

### 3. Use skill preloading instead of "read this file first" instructions

The subagent docs describe the `skills` frontmatter field: "The full content of each skill is injected into the subagent's context, not just made available for invocation."

Currently, every agent prompt includes instructions like:
- "Read `.claude/guidance/editorial-guidance.md` and `.claude/guidance/wiki-instructions.md` before writing"
- "Read `CLAUDE.md` for writing principles"

These waste agent turns on file I/O that could be eliminated. Convert the guidance files into skills and preload them:

**Action items:**
1. Create `.claude/skills/editorial-guidance.md` (or reference the existing guidance files as skills)
2. Add `skills: [editorial-guidance, wiki-instructions]` to writer, reviewer, and fixer subagent definitions
3. Remove the "read guidance files first" instructions from all command prompts

This saves 2-3 turns per agent invocation. At the scale of `init-wiki` (which launches 5 explorers + N writers), this adds up significantly.

### 4. Enable persistent memory for key agents

The subagent docs describe three memory scopes: `user`, `project`, and `local`. For wiki-agent, `project` scope is ideal — knowledge about a target codebase's structure, naming conventions, and documentation patterns is project-specific and shareable via version control.

**Best candidates for memory:**

| Agent | Memory scope | What it learns |
|-------|-------------|----------------|
| `wiki-explorer` | `project` | Source code layout, key file locations, module boundaries |
| `wiki-reviewer` | `project` | Common documentation patterns, recurring issues, false positive patterns |
| `wiki-writer` | `project` | API naming conventions, code example patterns, terminology |

**How it works:** The agent gets a persistent directory at `.claude/agent-memory/<agent-name>/`. Between sessions, it reads `MEMORY.md` from that directory to recall what it learned previously. This means the second `refresh-wiki` run is faster and more accurate than the first because the explorer already knows where key source files are.

**Caveat:** Memory is per-agent, not per-workspace. If the project serves multiple target repos simultaneously, agent memory could contain information about different codebases. Consider whether `local` scope (not checked into version control) is more appropriate.

### 5. Use `permissionMode` to enforce read-only behavior

Instead of relying on `disallowedTools` alone, use `permissionMode: plan` for explorers and reviewers:

```yaml
---
name: wiki-explorer
permissionMode: plan
---
```

`plan` mode restricts the agent to read-only exploration. This is a belt-and-suspenders approach alongside `disallowedTools`.

**Trade-off:** `plan` mode may be too restrictive for explorers that need Bash access (e.g., to run `git log`). In that case, `dontAsk` is better — it auto-denies permission prompts but still allows explicitly listed tools.

### 6. Add `maxTurns` to prevent runaway agents

None of the current agent invocations specify a turn limit. If an agent gets stuck in a loop (e.g., repeatedly failing to find a file), it burns through context and API credits.

**Recommended limits:**

| Agent | Suggested maxTurns | Rationale |
|-------|-------------------|-----------|
| Explorer | 15 | Exploring is bounded — read a few files, produce a report |
| Writer | 25 | Writing requires reading source + guidance + producing output |
| Reviewer | 20 | Similar to exploring but with more analytical depth |
| Fixer | 15 | Targeted edits on a single page shouldn't need many turns |
| Planner | 20 | Synthesis work with file reading |

### 7. Reduce prompt duplication in commands

The workspace selection procedure (steps 1-6) is copy-pasted into `init-wiki.md`, `refresh-wiki.md`, `proofread-wiki.md`, `revise-wiki.md`, and `save.md`. It's also described in `CLAUDE.md`.

**Options:**

1. **Create a `workspace-select` skill** and preload it into commands. Each command says "Follow the workspace-select skill" instead of repeating 6 steps.
2. **Create a `workspace-select` subagent** that resolves the workspace and returns the config values. Commands invoke it first.
3. **Rely solely on `CLAUDE.md`** — since the procedure is already documented there, commands could just say "Follow the Workspace selection procedure in CLAUDE.md" (some already reference it but then repeat it anyway).

Option 3 is the simplest. The commands already say "Follow the Workspace selection procedure in CLAUDE.md" — they just also repeat the full procedure inline. Removing the inline copy and trusting the `CLAUDE.md` reference would cut ~10 lines from each command.

### 8. Move proofread findings out of disk cache and into agent returns

`proofread-wiki` currently has agents write findings to `.proofread/{repo}/` files on disk, then reads those files back in later phases. This requires Bash access for the reviewer agents (to write files) and creates cleanup burden.

With dedicated subagents, findings can be returned as the agent's output (the return value of the Task tool). The orchestrating command collects these returns and passes them to the deduplication phase. This eliminates:
- The `.proofread/` directory and its cleanup
- Bash access for reviewer agents
- The disk I/O round-trip

**Trade-off:** If findings are very large, returning them through the Task tool puts them in the main conversation's context. But the current approach already reads them back into context via `Read` tool, so the net impact is the same.

### 9. Use `Task(agent_type)` restrictions for orchestrator commands

The subagent docs show that agents running as main thread can restrict which subagents they spawn:

```yaml
tools: Task(wiki-explorer, wiki-writer), Read, Bash
```

Apply this to command definitions to make the delegation pattern explicit:
- `init-wiki`: `Task(wiki-explorer, doc-planner, wiki-writer)`
- `refresh-wiki`: `Task(wiki-explorer, wiki-writer)`
- `proofread-wiki`: `Task(wiki-explorer, wiki-reviewer, doc-planner)`
- `revise-wiki`: `Task(wiki-fixer)`

This prevents commands from accidentally spawning the wrong agent type. Note: this feature applies to agents run via `claude --agent`, not skills. If commands remain as skills (not subagents), this doesn't apply directly — but it's worth considering if the orchestration layer ever moves to a subagent architecture.

### 10. Consider SubagentStart/SubagentStop hooks for observability

The subagent docs describe project-level hooks that fire when subagents start and stop:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "hooks": [
          { "type": "command", "command": ".scripts/log-agent-start.sh" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": ".scripts/log-agent-stop.sh" }
        ]
      }
    ]
  }
}
```

For a project that launches 5-15 agents per command, observability into agent lifecycle would be valuable for debugging and cost tracking. A simple logging hook that records agent type, start time, and duration would help identify which commands are most expensive.

---

## Priority ranking

| Priority | Suggestion | Effort | Impact |
|----------|-----------|--------|--------|
| 1 | Extract subagent definitions into `.claude/agents/` | Medium | High — enables all other improvements |
| 2 | Add PreToolUse hook for source-repo-readonly | Low | High — turns prose policy into structural guarantee |
| 3 | Use skill preloading for guidance files | Low | Medium — saves 2-3 turns per agent |
| 4 | Enable persistent memory for explorer/reviewer | Low | Medium — improves accuracy across sessions |
| 5 | Add `maxTurns` limits | Low | Medium — prevents runaway costs |
| 6 | Reduce workspace-selection duplication | Low | Low — cleaner command files |
| 7 | Move proofread findings to agent returns | Medium | Low — simplifies architecture |
| 8 | Add SubagentStart/Stop hooks for observability | Low | Low — debugging aid |
| 9 | Use `permissionMode` for read-only agents | Low | Low — defense in depth |
| 10 | Use `Task(agent_type)` restrictions | Low | Low — only applies if commands become agents |

## Notes

- The subagent documentation states: "Subagents cannot spawn other subagents." This is already respected by the current architecture — commands (skills) run in the main conversation and spawn one level of agents. No changes needed here.
- The `--agents` CLI flag for session-scoped subagents could be useful for testing new agent configurations before committing them to `.claude/agents/`.
- The `/agents` command provides an interactive UI for creating subagents — useful for rapid prototyping.
- Background subagents auto-deny permission prompts not pre-approved. The current commands already launch most agents with `run_in_background: true`, so this is already handled correctly.
