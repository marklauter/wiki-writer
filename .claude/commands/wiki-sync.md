---
name: wiki-sync
description: Sync wiki pages with source code changes. Uses parallel background agents to minimize main context usage.
model: sonnet
allowed-tools: Bash, Read, Grep, Glob, Task
---

Sync wiki documentation with recent source code changes using a two-phase agent swarm.

## Phase 1: Identify changes

1. Run `git -C DynamoDbLite log --oneline -50` to see recent commits.
2. For each commit that changed behavior (skip pure refactors), identify the affected feature area.
3. Read `DynamoDbLite.wiki/_Sidebar.md` to discover all wiki pages and their sections. Map affected feature areas to the appropriate pages.

4. Build a list of `(wiki-page, feature-area, relevant-source-files)` tuples that may need updates.

## Phase 2: Explorer swarm (background agents)

For each potentially affected wiki page, launch a **background** Task agent (subagent_type: `Explore`, model: `sonnet`) that:
- Reads the relevant source files for that feature area
- Reads the corresponding wiki page in `DynamoDbLite.wiki/`
- Compares them and produces a structured verdict:
  - `UP_TO_DATE` — wiki accurately reflects current source code
  - `STALE` — wiki is missing or misrepresents current behavior, with a description of what's wrong and what the correct content should be

Launch all explorer agents **in parallel** using `run_in_background: true`. Then collect results from each.

Also launch one explorer agent for `API-Parity.md` that checks whether new operations were added that aren't in the parity matrix.

## Phase 3: Update swarm (parallel agents)

For each page the explorers marked `STALE`:
1. Launch a Task agent (subagent_type: `general-purpose`, model: `opus`) to update that wiki page. Pass it:
   - The explorer's diagnosis of what's wrong
   - The wiki writing principles from `CLAUDE.md` (second person, present tense, short sentences, sentence-case headings, reference-style not tutorial)
   - The path to the wiki page to edit
   - The relevant source file paths to read for accurate content

Launch all update agents **in parallel**. Each agent reads the source, reads the wiki page, and edits it.

## Phase 4: Summary

After all update agents complete:
1. Summarize what was updated and what was already in sync.
2. List each wiki page with its status: `UP_TO_DATE` or `UPDATED (what changed)`.
