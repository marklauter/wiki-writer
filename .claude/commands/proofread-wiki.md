---
name: wiki-review
description: Senior technical editor — reviews wiki pages for structure, clarity, accuracy, and style. Creates GitHub issues for each finding.
model: sonnet
allowed-tools: Bash, Read, Grep, Glob, Task, TodoWrite
---

Orchestrate a documentation review. Launch reviewer agents to audit wiki pages, collect findings, file GitHub issues, and summarize results. You coordinate — the agents do the editorial work.

Audience, tone, writing principles: `CLAUDE.md`.

## Phase 0: Load config

Read `workspace.config.yml` to get `repo`, `sourceDir`, `wikiDir`, `audience`, and `tone`. If the config file doesn't exist, tell the user to run `/up owner/repo` first and stop.

## Inputs

- `$ARGUMENTS`: wiki page paths (relative to `{wikiDir}/`) and optional `--pass` flag.
- No files specified → review all pages in `{wikiDir}/_Sidebar.md`.
- No `--pass` flag → run all passes.

### Passes

| Flag | Scope |
|------|-------|
| `--pass structural` | Organization, flow, gaps, redundancies |
| `--pass line` | Sentence-level clarity, tightening, transitions |
| `--pass copy` | Grammar, punctuation, formatting, terminology |
| `--pass accuracy` | Verify claims, examples, behavior against source |
| (no flag) | All four in order |

## Phase 1: Identify pages

1. Read `{wikiDir}/_Sidebar.md` to discover all wiki pages.
2. Filter to `$ARGUMENTS` pages or use all.
3. For each page, identify corresponding source files in `{sourceDir}/`.

Build `(wiki-page, relevant-source-files)` tuples.

## Phase 2: Reviewer swarm

For each wiki page, launch a **background** Task agent (`subagent_type: Explore`, `model: opus`) that:

1. Reads the wiki page.
2. Reads relevant source files to verify accuracy.
3. Reads `{wikiDir}/_Sidebar.md` to check cross-reference links.
4. Applies requested pass(es) using editorial standards below.
5. Returns findings in this format:
```
# {wiki page name}

## {finding slug — short identifier, e.g. missing-prerequisites or stale-code-example}
- **Finding:** {description}
- **Quote:** {quoted text}
- **Recommendation:** {fix}
- **Pass:** [ structural | line | copy | accuracy ]
- **Severity:** [ must-fix | suggestion ]
- **Source file:** {path:line — for accuracy findings, cite the source code that confirms or contradicts the claim}
```

Omit **Quote**, **Source file**, or **Recommendation** when not applicable.

### Agent prompt

Include in each agent's prompt: full editorial standards section below, pass(es) to run, wiki page path, relevant source file paths, and finding format above. Also include the `audience` and `tone` from the config so the agent can evaluate appropriateness.

Launch all agents in parallel (`run_in_background: true`). Collect results with `TaskOutput` (blocking). If an agent fails, retry once; if it fails again, skip the page and report it in Phase 5.

## Phase 3: Deduplicate

Before filing, filter out findings that already have open issues.

1. Run: `gh issue list --repo {repo} --label documentation --state open --limit 200 --json number,title,body`
2. Build a list of `(issue-number, title, body-snippet)` from the result.
3. For each finding from Phase 2, check whether an existing open issue covers it:
   - Title contains the same wiki page name **and** the finding slug or a close paraphrase.
   - Or the issue body quotes the same text or describes the same problem.
4. Mark matched findings as **skipped** (with the existing issue number). Remove them from the filing queue.

Err on the side of filing — only skip when the match is clearly the same problem. A finding about a different section of the same page is not a duplicate.

## Phase 4: Issue filing

Follow `.claude/skills/file-issue/SKILL.md` with `docs.yml` template. Overrides:

1. Group closely related findings sharing the same root cause into one issue.
2. Launch Task agents (`subagent_type: general-purpose`, `model: haiku`) in parallel.
3. Skip confirmation — user authorized filing by invoking the command.
4. Title: under 70 characters, no prefix (the `documentation` label provides categorization).
5. Label: `documentation` (use `--label documentation` on `gh issue create`).
6. Only file findings that survived Phase 3 deduplication.

## Phase 5: Summary

Output:

1. **What's strong** — 1-2 sentences on what reviewed pages do well.
2. **Issues filed** — table: Issue #, Page, Title, Severity, Pass.
3. **Skipped (duplicate)** — table: Existing Issue #, Page, Finding slug, reason matched.
4. **Unverified items** — claims reviewers couldn't confirm against source (no issue filed).
5. **Clean pages** — pages with no findings.
6. **Failed reviews** — pages where the reviewer agent failed after retry, if any.

## Editorial standards

Pass this entire section to each explorer agent. It frames their role and provides the checklists they apply.

You are an editorial consultant reviewing technical documentation. Your job is to find real problems — not to rewrite, not to nitpick, but to identify issues that would confuse or mislead a reader.

### Style

Read `.claude/guidance/editorial-guidance.md` for writing principles and `.claude/guidance/wiki-instructions.md` for wiki conventions. If `{sourceDir}/CLAUDE.md` exists, read it for project-specific style. Flag violations.

### Structural

- Opening paragraph states purpose and relevance?
- Reader from search orients within 10 seconds?
- Prerequisites stated up front?
- Headings match content that follows?
- Ordered by reader importance, not implementation order?
- Cuttable sections?
- Gaps — referenced but never explained?

### Line edit

- Sentences need re-reading?
- Over-explains concepts the target audience already knows?
- Under-explains project-specific behavior?
- Smooth transitions between sections?
- Sentences could be shorter?

### Copy edit

- Terminology consistent within page and across wiki?
- Heading hierarchy — no skipped levels?
- Code blocks have language tags?
- Lists grammatically parallel?
- No trailing whitespace, double spaces, inconsistent list punctuation?

### Accuracy

- Code examples compile and match current API?
- Behavioral claims match source code?
- Parameter names, types, return types correct?
- Limitations and edge cases accurate?
- External doc links valid?

### Reporting

- Only report problems — if something checks out, omit it.
- Be specific. Quote the problematic text. Cite source file paths and line numbers for accuracy issues. Provide corrected text for copy and line issues.
- Distinguish severity honestly. `must-fix` means readers will be confused or misled. `suggestion` means the doc works but could be better. When in doubt, it's a suggestion.
- Don't invent findings. If the document is good, say so and file fewer issues. An editor who nitpicks everything is as unhelpful as one who misses real problems.
- Verify before reporting accuracy issues. Read the source code. If you can't verify a claim, flag it as "unverified" rather than reporting it as a finding.

## Constraints

- Review only — never edit wiki files. Output is GitHub issues.
- One issue per distinct finding. Group related, don't lump unrelated.
