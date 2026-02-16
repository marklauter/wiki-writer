# Use case philosophy

Guiding principles for writing use cases in this project. Every use case must reflect these ideas.

## Actors have drives

An actor is an entity with a goal and a *drive* — the thing it naturally optimizes for. Classical actors have drives rooted in human motivation: self-interest, professional duty, economic pressure. AI agents have drives rooted in behavioral tendency: what they optimize for given their role and prompt.

Consider an elevator system. The rider's drive is self-interest — arrive at another floor safely. The building owner's drive is economic — minimize maintenance cost. The government inspector's drive is institutional — protect public safety. Now consider this system. A creator's drive is production — fill pages with content. A proofreader's drive is critique — find what's wrong.

Drives are what make actors predictable in a modeling sense. You know what an actor will optimize for, and therefore where it will fall short. An actor is not a tool. A tool has no drive — `grep` does exactly what you tell it. An actor makes decisions shaped by what it cares about.

## Drives explain separation

When a single drive cannot protect all the concerns at play, you need separate actors. The building owner's cost-minimization drive is insufficient to protect public safety — so the inspector exists. The creator's production drive is insufficient to guarantee accuracy — so the proofreader exists.

This is not about malice. The owner isn't trying to hurt riders. The creator isn't trying to produce inaccurate content. But a single drive cannot serve competing concerns. Separation of actors is the structural answer to conflicts of interest between drives.

Ask "whose drive is insufficient here, and what complementary drive is needed?"

## Goal conflicts spawn actors

Actors do not emerge from job descriptions. They emerge from goal conflicts. The inspector exists because the owner's incentives alone won't protect the rider. The proofreader exists because the creator's tendencies alone won't protect accuracy.

If there is no conflict of interest — no tension between what one drive optimizes for and what the overall goal requires — there is no reason for a separate actor.

## Goals over tasks

Use cases describe what an actor wants to achieve, not what steps they perform. Goals are stable — they survive model upgrades, tool changes, and prompt rewrites. Tasks are transient means to an end.

A goal includes its constraints. "Get to floor 12" is a task. "Arrive at another floor safely" is a goal. Safety is not a precondition bolted on afterward — it is part of the desired end state. If the elevator rips the rider's arm off on the way to floor 12, the goal was not satisfied.

Ask "what state of the world does the actor want?" not "what commands does the actor run?"

## Invariants over preconditions

Domain rules are not entry gates you check once. They are constraints that must hold continuously — before, during, and after execution. An actor that violates an invariant mid-scenario has failed, even if the final output looks correct.

Express constraints as invariants, not as preconditions or validation steps.

## Domain events over return values

Actors communicate through meaningful state transitions, not function returns. A drift assessment, a filed finding, a change report — these are domain events. They are the published language between bounded contexts.

Name them. Define them. They are the integration points of the system.

## Markdown is the wire format

Protocols, domain events, reports, and assessments are all materialized as markdown. Not JSON. Not YAML. Not protocol buffers. The consumers are humans and LLM agents, and markdown is the format both read natively. Formal machine-readable schemas are not needed when every consumer is a capable reader.

This is a deliberate choice, not a shortcut. A system whose integration points are optimized for human and AI consumption does not need a serialization layer between them.

## Obstacles over exceptions

When something goes wrong, describe the threat to the goal — not the error code. "Source code is unreachable" tells you what's at risk. "Exit code 128" tells you nothing about what to do next.

Frame failures as goal obstacles with recovery strategies, not try/catch blocks.

## Intent over mechanics

Scenario steps express what is accomplished, not how. "Wiki content is verified against current source" gives an actor room to find the best path. "Run grep on lines 1-50 of each file" does not.

The actor's job is to satisfy intent. The use case's job is to express it clearly.

## Bounded contexts over shared models

Each use case lives in a bounded context with its own language and its own rules. Proofread and resolve share a published language (the issue body protocol) but operate independently. They do not share internal state.

Respect boundaries. Define protocols at every crossing point.

## Single responsibility for actors

Creators write. Researchers explore. Proofreaders review. Orchestrators coordinate. An actor that both decides what to write and evaluates whether it wrote well has two jobs and will do both poorly.

This is a corollary of drive separation. Each actor has one drive. A creator's drive is production. A proofreader's drive is critique. An actor with both drives will compromise between them — producing content that is "good enough" rather than content that is excellent and then separately verified. Two actors with opposing drives produce better outcomes than one actor trying to balance competing concerns.

Separate judgment from execution. Separate analysis from mutation.

## Extract, don't invent

Use case design is Socratic. The designer asks questions; the domain expert has the answers. The designer's job is to draw out goals, constraints, and events that the expert already knows but hasn't structured — not to fabricate domain knowledge or infer requirements from silence.

Work one phase at a time: goal, then invariants, then domain events, then scenario and obstacles. Summarize what you heard before moving on. If the answer is task-oriented ("it runs git pull"), redirect to intent ("what state does that achieve?"). If something contradicts a principle in this document, flag it.

The user knows the domain. The designer knows how to structure it.
