# Workspace layout

This repo supports multiple target projects simultaneously. Each project gets its own source clone, wiki clone, and artifacts directory under `workspace/`.

```
workspace/
  artifacts/{owner}/{repo}/
    workspace.config.md                         # per-project config
    .proofread/                                 # ephemeral UC-02 cache
    reports/
      sync/{date-time}-sync-report.md           # UC-04 sync reports
      review-fallback/{date-time}/{slug}.md     # UC-02 local fallback
  {owner}/{repo}/                               # cloned source repo (READONLY)
  {owner}/{repo}.wiki/                          # cloned wiki repo
```

Example for `acme/WidgetLib`:

```
workspace/
  artifacts/acme/WidgetLib/workspace.config.md
  acme/WidgetLib/
  acme/WidgetLib.wiki/
```

Source clones are readonly reference material — never staged, committed, or pushed to. A PreToolUse hook enforces this for Write and Edit operations.

## Workspace selection protocol

Commands that need a workspace resolve which one to target:

1. List config files matching `workspace/artifacts/*/*/workspace.config.md`.
2. If none exist, tell the user to run `/up` first and **stop**.
3. If `$ARGUMENTS` contains a token matching `owner/repo` or `repo`, select that workspace.
4. If exactly one workspace exists and no token matched, auto-select it.
5. If multiple exist and no token matched, list them and prompt the user to choose.
6. Read the selected config for `repo`, `sourceDir`, `wikiDir`, `audience`, and `tone`.
