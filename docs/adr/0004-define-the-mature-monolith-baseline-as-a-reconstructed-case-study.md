# ADR 0004: Define The Mature Monolith Baseline As A Reconstructed Case Study

## Status

Accepted

## Context

Gridline Platform Evolution is a portfolio-oriented architecture case study, not
a source archive from a real company.

The project uses a fictional company, Gridline, to make architecture decisions
concrete. The ADRs should therefore be truthful about the decisions made for
this repository while still documenting the fictional production history we are
constructing to support the case study.

The case study starts with a mature Rails monolith because that is a realistic
point where platform evolution begins to matter. We are not modeling Gridline
from its first commit. We are modeling the point where the application has
already become valuable, operationally important, and constrained by its
original runtime and delivery model.

## Narrative Assumption

Gridline's internal operations platform has been in production for roughly three
years.

The first version was built as a conventional Rails monolith because Rails was a
strong fit for quickly modeling relational operations workflows: customers,
customer sites, service requests, work orders, technicians, SLA deadlines, and
reports.

The original production environment was a managed PaaS-style Rails deployment:

- one Rails application service
- managed Postgres
- environment-variable configuration
- basic logs and platform-managed process restarts
- CI-backed but manually promoted deploys
- vertical scaling through larger app/database plans
- no explicit load balancer or multi-instance application topology owned by the
  team

This setup was appropriate for the original stage of the business. Gridline had
a small engineering team, one regional operations team, modest request volume,
and a need to move quickly without owning infrastructure.

Back-of-envelope assumptions for the original workload:

- fewer than 10 dispatcher/manager users
- dozens of technicians
- hundreds of customer sites
- hundreds of service requests per week
- business-hours traffic with morning spikes
- basic daily reporting
- one regional operating footprint

These are narrative assumptions, not benchmark targets. Detailed load modeling
is deferred to scenario-specific documentation and demos.

## Decision

Define the repository's starting point as a reconstructed version of Gridline's
mature monolith at the moment it begins platform modernization.

The implementation will use the latest stable Rails version available when the
baseline is built, backed by Postgres.

Although the fictional application has a three-year production history, this
repository will not simulate historical Rails versions, framework upgrades,
deprecated patterns, or dependency archaeology. Those concerns are realistic,
but they are outside the primary learning goal.

The repository will focus on:

- reconstructing the mature monolith as a modern Rails baseline
- documenting the fictional production history honestly
- preserving the monolith before introducing distributed architecture
- making CI/CD and scenario verification part of each phase
- preparing the runtime for horizontal scaling

## Consequences

This gives the project a credible starting point without turning it into a
legacy-upgrade case study.

The three-year history explains why the monolith is mature enough to have real
workflows, operational pressure, reporting needs, and deployment risk. Using
latest stable Rails keeps the implementation modern and avoids distracting from
the platform evolution story.

The fictional managed PaaS history explains why the original runtime was
reasonable, why it survived for several years, and why it is now becoming a
constraint.

This ADR also creates the foundation for the next runtime decision: how to
simulate and modernize the production environment without requiring paid hosted
infrastructure.

## Tradeoffs

This approach is intentionally selective.

It does not literally reproduce every realism detail of a three-year-old Rails
application. A real app might have older framework versions, historical
migrations, accumulated data, dependency drift, and deployment quirks. This
repository abstracts those details away so the architecture story can focus on
scaling a mature monolith.

The risk is that the baseline may look cleaner than a real production app. The
mitigation is to keep the business workflows, CI expectations, runtime
constraints, and scaling pressures realistic even if the implementation uses a
modern Rails stack.

## AI Involvement

Codex was used as an AI development collaborator while drafting this decision.

The human maintainer directed the discussion, challenged assumptions, and made
the final framing decisions. Codex contributed by proposing plausible Rails
application timelines, deployment histories, scaling pressures, and ADR
structure. The maintainer reviewed and refined those suggestions, including the
decision to be explicit that Gridline is fictional and that the repository
reconstructs a modern case-study baseline rather than simulating a literal
three-year-old Rails codebase.

This ADR records the resulting project decision, not an autonomous AI decision
and not an in-universe Gridline company document.
