# {UC-ID} — {Title}

## Goal

{Desired end state the actor is trying to reach. Express *why*, not *what*. Goals are stable — they survive model upgrades, tool changes, and prompt rewrites. Ask "what state of the world does the actor want?"}

## Context

- **Bounded context:** {Which domain area this use case lives in — its own language, its own rules}
- **Primary actor:** {Who pursues the goal}
- **Supporting actors:** {Agents, tools, and services involved}
- **Trigger:** {What prompts the actor to pursue this goal}

## Actor responsibilities

{Which actor owns each concern. Creators write. Researchers explore. Proofreaders review. Orchestrators coordinate. No actor holds two roles.}

- **{actor-name}** — {what it owns: analysis, mutation, judgment, coordination}

## Invariants

{Domain rules that must hold continuously — before, during, and after this use case. Not entry gates checked once. An actor that violates an invariant mid-scenario has failed, even if the final output looks correct.}

- {invariant}

## Success outcome

{Observable state of the world when the goal is satisfied. Expressed in domain terms, not implementation details.}

- {outcome}

## Failure outcome

{Observable state when the goal cannot be satisfied. What is preserved? What is the user told?}

- {outcome}

## Scenario

{Steps express intent and outcomes, not mechanics. "Wiki content is verified against current source" gives an actor room to find the best path. "Run grep on lines 1-50" does not. Domain events (marked with -->) signal meaningful state transitions — these are the published language between bounded contexts.}

1. **{Actor}** — {Intent / outcome}
   --> {DomainEvent}
2. **{Actor}** — {Intent / outcome}
3. **{Actor}** — {Intent / outcome}

## Goal obstacles

{Conditions that threaten goal satisfaction. Keyed to scenario steps. Describe the threat to the goal — "source code is unreachable" — not the error code. Each obstacle includes a recovery strategy or graceful degradation path.}

### {Step}a — {What threatens the goal}

1. **{Actor}** — {Response}
2. **{Actor}** — {Recovery or graceful degradation}

## Domain events

{All events this use case can produce. These are the meaningful outputs — the "facts" that other bounded contexts or future use cases may react to. Name them. Define them. They are the integration points.}

- **{EventName}** — {When it occurs and what it signifies}

## Protocols

{Actor boundary contracts. Every crossing point between actors or between an actor and a sub-system has a protocol. Define the input, the output, and who owns each side.}

- **{protocol-name.md}** — step {number}, {input to / output from actor}

## Notes

- {Design decisions, open questions, cross-references to other use cases}
