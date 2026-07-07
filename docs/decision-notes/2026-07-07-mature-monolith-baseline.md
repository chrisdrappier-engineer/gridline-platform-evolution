# Decision Note: Mature Monolith Baseline

## Summary

This conversation refined the project's baseline architecture story and resulted
in a rewrite of ADR 0004.

The main outcome was to clarify that Gridline is a fictional company and that
the repository is a reconstructed portfolio case study, not an in-universe
archive of real company decisions. ADR 0004 now defines the mature monolith
baseline as a deliberately constructed starting point for platform evolution.

## Why This Needed A Note

The discussion involved substantial AI-assisted reasoning and several important
course corrections.

The original ADR 0004 focused on starting with a modular monolith before
distributed architecture. During discussion, that proved too abstract. The
project needed a more specific baseline: what production state we are assigning
to Gridline, how long the app has existed, how it was deployed, and why this is
the right moment to begin modernization.

Because the resulting ADR depends on both fictional narrative design and real
architecture judgment, this decision note records the reasoning path behind the
change.

## Questions Discussed

We discussed whether the project should represent Gridline as having started
Docker-first or whether the fictional company should have a more conventional
Rails history.

We discussed whether the ADRs should read as if they were internal Gridline
company records or as truthful records of this repository's case-study design
decisions.

We discussed whether the mature monolith should have a multi-year fictional
history, and why three years is a plausible but selective timeframe.

We discussed whether the repository should simulate historical Rails upgrades.
The decision was to use the latest stable Rails version and avoid making
framework migration part of the main story.

We discussed whether the original production deployment should be a manual or
semi-manual deployment to a managed PaaS-style environment. That was judged
plausible for a small internal operations app that gradually became
business-critical.

We discussed whether data size and request load should be modeled in detail now.
The decision was to include only lightweight back-of-envelope assumptions in ADR
0004 and defer detailed load modeling to scenario-specific docs and demos.

## Positions Considered

One possible direction was to say the project starts Docker-first because the
Rails application itself is new. That framing was rejected because it made the
fictional company story less realistic and made the runtime decision feel too
abrupt.

Another direction was to define a target production environment first, then
derive Docker usage from that. That was useful, but it risked expanding the ADR
into a deployment strategy discussion before the baseline fiction was clear.

The selected direction was to first define Gridline's fictional starting point:
a roughly three-year-old Rails monolith that began in a managed PaaS-style
environment, survived because it was appropriate for the original scale, and is
now being reconstructed as a modern case-study baseline before runtime
modernization and horizontal scaling.

## Decision Outcome

The discussion resulted in a rewrite of ADR 0004.

ADR 0004 now defines the mature monolith baseline as a reconstructed case study,
including the fictional production history, the modern Rails baseline choice,
and the boundary between realistic narrative assumptions and implementation
scope.

The exact decision text lives in ADR 0004. The implementation change was
committed in:

`e0ed93b Refine mature monolith baseline ADR`

## AI Involvement

Codex was materially involved in this decision.

Codex proposed initial framings for Docker-first development, target production
environments, fictional deployment history, the three-year timeline, and ADR
structure. The human maintainer challenged those assumptions, especially where
Codex filled in both sides of an argument or treated fictional Gridline
decisions as if they were real company history.

The maintainer redirected the process toward a more truthful framing: the ADRs
should document the actual design decisions behind this repository while using
fictional history only as a narrative device.

The final ADR framing came from that back-and-forth. Codex helped synthesize the
discussion into ADR language, but the maintainer made the final decision about
the story, scope, and level of process transparency.

## Related Artifacts

- [ADR 0004: Define the mature monolith baseline as a reconstructed case study](../adr/0004-define-the-mature-monolith-baseline-as-a-reconstructed-case-study.md)
- [Issue #15: Create Docker-first Rails monolith skeleton](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/15)
- Commit `e0ed93b`: Refine mature monolith baseline ADR

## Follow-Up Questions

The next major discussion should define how the repository will simulate
Gridline's production environment.

Open questions include:

- What exact production environment are we simulating?
- Why use Docker Compose instead of a real hosted PaaS, local host runtime,
  single VM, or Kubernetes?
- How should CI/CD verify each scenario?
- What parts of the original managed PaaS deployment should be represented in
  local simulation?
- How much load or data volume should Scenario 01 seed before later scaling
  scenarios introduce pressure?

