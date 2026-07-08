# ADR 0005: Simulate The Baseline Production Architecture

## Status

Proposed

## Context

ADR 0004 defines Gridline's mature monolith baseline as a reconstructed case
study.

The fictional production history assumes that Gridline's Rails application has
been in production for roughly three years and originally ran in a managed
PaaS-style environment. That environment included one Rails application service,
managed Postgres, environment-variable configuration, basic logs,
platform-managed process restarts, CI-backed but manually promoted deploys, and
vertical scaling through larger app/database plans.

This repository now needs to decide how to represent that baseline production
architecture in a way that supports the project's goals.

The representation should help reviewers understand the original single-instance
monolith, its operating assumptions, and the constraints that motivate runtime
modernization and horizontal scaling.

One available option would be to deploy the baseline application to an actual
hosted PaaS or PaaS-like service. That would improve authenticity: reviewers
could inspect a running public application without cloning the repository,
building containers, or relying only on documentation. A hosted environment
would also exercise more of a real deployment path, including platform runtime
behavior, hosted database connections, logs, restarts, environment variables, and
release promotion.

For this project, the tradeoffs do not justify making real hosting the baseline
representation. Gridline Platform Evolution is a non-revenue-generating
portfolio case study with an open-ended lifecycle, so even modest hosting costs
become a recurring resource commitment. A public deployment would also introduce
ongoing operational work: billing, provider drift, secrets, dependency updates,
broken deploy recovery, database maintenance, abuse handling, and public attack
surface management.

The project should still assume a realistic production attack surface when
designing the application. Ruling out public hosting does not mean treating
security as irrelevant. Instead, the simulated baseline should document its
security assumptions and use low-overhead checks such as dependency vulnerability
scanning, container image scanning, secret scanning, Rails static analysis, and
OWASP-guided security review where appropriate. This provides useful security
discipline without adding a live operational target that does not materially
advance the scaling story.

The fictional customer profile also supports this boundary. Gridline is assumed
to serve procurement-light commercial facilities customers such as apartment
complexes, regional warehouses, property management groups, and maintenance
contractors. The baseline should represent a commercially plausible B2B SaaS
application with reasonable security hygiene, not an enterprise-grade platform
already expected to satisfy heavy procurement, formal compliance, or
mission-critical industrial requirements.

Based on these tradeoffs, real hosted deployment is ruled out for this phase.
ADR 0005 should focus on local or repository-contained simulation options that
make the baseline architecture understandable, repeatable, and useful for later
scaling experiments.

## Decision Drivers

- Represent the baseline production architecture clearly enough for reviewers to
  understand the starting point of the scaling story.
- Keep the project reproducible without requiring paid infrastructure or an
  open-ended hosted environment.
- Preserve enough operational realism to discuss deployment shape, runtime
  boundaries, database dependency, CI/CD, and security assumptions.
- Avoid creating a public attack surface or maintenance obligation that does not
  materially advance the project's current goals.
- Leave room for future public demo, hosted deployment, or artifact publication
  if the portfolio value later justifies the added cost and operational burden.

## Options Considered

- Actual hosted PaaS or PaaS-like deployment: ruled out for this phase.
- Local or repository-contained simulation options: still under consideration.

## Decision

TBD

## Consequences

TBD

## AI Involvement

TBD
