# Gridline Platform Evolution

Gridline Platform Evolution is a portfolio-oriented architecture case study.
It uses a realistic Rails monolith as the system under test, then evolves that
system through evidence-driven scaling decisions.

The goal is not to showcase infrastructure for its own sake. Each phase starts
from business or engineering pressure, measures how the current system behaves,
and then applies the smallest architecture change that addresses the pressure.

## Why This Exists

Gridline is a fictional commercial facilities maintenance company. Its internal
operations platform starts as a mature single-instance Rails monolith and is
expected to grow into a horizontally scalable operations system.

This repository demonstrates how that kind of platform can evolve as usage
increases, operational risk grows, and scaling pressure appears. It also
demonstrates how AI collaboration can speed and simplify the development
lifecycle of a large, complex application when the work remains organized
around human-owned architecture decisions, reviewable issues, reproducible
verification, and explicit documentation.

The main story is the engineering process: documentation, AI-assisted planning,
CI/CD, workload evidence, optimization tradeoffs, and architecture decisions.

## What Gridline Is

Gridline provides facilities maintenance services for multi-location
businesses: retail chains, clinics, warehouses, restaurants, and property
managers.

When something breaks at a customer site, Gridline dispatchers create and
triage service requests, assign internal teams or vendor partners, record
provider updates, and keep customers informed until the work is complete.

The Rails monolith is feature complete for the current baseline. It includes
customers, sites, service providers, users, scoped RBAC, service requests,
quotes, actual costs, request notes, evidence files, feedback, follow-up
requests, role-specific dashboards, admin workflows, backend-driven tables,
live reporting metrics, demo data, and test coverage.

Detailed application context lives in
[`docs/application`](docs/application/README.md).

## How The Project Evolves

The project starts from a complete single-instance monolith, then uses a
production-like local runtime and workload lab to create evidence about
performance, operational pressure, and scaling limits.

The near-term direction is vertical pressure and measurement before horizontal
scaling. Later stages introduce infrastructure such as load-balanced web
workers, shared session state, Redis caching, background jobs, read scaling,
backpressure, observability, and orchestration patterns when the measured
behavior justifies those changes.

Architecture decisions live in [`docs/adr`](docs/adr/README.md). The product
and scaling roadmap lives in [`docs/roadmap`](docs/roadmap/README.md).

## Workload Lab

The workload lab is the evidence-generation foundation for the project. It
generates deterministic, business-shaped traffic against the production-like
runtime so changes can be evaluated through repeatable workload evidence rather
than isolated anecdotes.

Current workload-lab capabilities include deterministic traffic generation,
profile validation, an ESLint-backed `Math.random()` ban, a smoke profile, a
Scenario 00 normal-operations profile, k6 integration, archive naming, and
summary output.

Run workload-lab checks:

```bash
bin/workload-ci
```

Run the first normal-operations workload profile:

```bash
bin/workload-scenario-00
```

Generate a UUID-formatted workload seed:

```bash
bin/workload-seed
```

Full workload-lab documentation lives in
[`workload-lab/README.md`](workload-lab/README.md).

The workload strategy is captured in
[`ADR 0009`](docs/adr/0009-create-an-evidence-first-workload-lab.md), and the
duration-based series model is captured in
[`ADR 0010`](docs/adr/0010-use-duration-based-workload-series-as-performance-evidence.md).

## Quick Start

Start with the [Quick Start Guide](docs/runtime/quick-start.md).

It covers the shortest useful path through project verification, the
production-like runtime, the first workload profile, where workload summaries
are written, and what the first run does and does not prove.

## Production-Like Runtime

The production-like runtime is the target for workload evidence. It builds the
Rails app with the production Docker target, runs with `RAILS_ENV=production`,
does not bind-mount source code, precompiles assets, and applies the default
`local-small` resource envelope.

Run production-like validation:

```bash
bin/ci:production
```

Production-like runtime details live in
[`docs/runtime/production-like.md`](docs/runtime/production-like.md).

## Browser Tests

Run headed browser workflow tests:

```bash
npm run test:e2e:headed
```

Run the full browser workflow suite:

```bash
npm run test:e2e
```

The E2E suite runs with one worker because the browser workflows intentionally
mutate shared demo data while exercising realistic user paths.

Additional browser test details live in [`e2e/README.md`](e2e/README.md).

## Version Tags

| Tag | Meaning |
|---|---|
| `app-v1` | First complete Gridline monolith application |
| `workload-lab-v1` | First meaningful workload lab scenario |

## Documentation Map

| Topic | Location |
|---|---|
| Current Rails monolith baseline | [`docs/application`](docs/application/README.md) |
| Quick start | [`docs/runtime/quick-start.md`](docs/runtime/quick-start.md) |
| Development runtime | [`docs/runtime/development.md`](docs/runtime/development.md) |
| Production-like runtime | [`docs/runtime/production-like.md`](docs/runtime/production-like.md) |
| AI collaboration model | [`docs/development/ai-collaboration.md`](docs/development/ai-collaboration.md) |
| Rails generator tooling | [`docs/development/rails-generator-tooling.md`](docs/development/rails-generator-tooling.md) |
| Workload lab | [`workload-lab/README.md`](workload-lab/README.md) |
| Architecture decisions | [`docs/adr`](docs/adr/README.md) |
| AI-assisted planning context | [`docs/decision-notes`](docs/decision-notes/README.md) |
| Domain model | [`docs/domain`](docs/domain/README.md) |
| Product and scaling roadmap | [`docs/roadmap`](docs/roadmap/README.md) |
| Design and implementation rules | [`docs/design`](docs/design/README.md) |
| User stories | [`docs/user-stories`](docs/user-stories/README.md) |
| Browser workflow tests | [`e2e/README.md`](e2e/README.md) |

## Development Workflow

This project is being built with Codex as an AI development collaborator.

Codex helps convert planning discussions into issues, ADRs, documentation,
implementation branches, verification steps, commits, and pull request
summaries. Architectural direction and merge decisions remain human-owned.

Codex is not part of the Gridline application at runtime. It is part of the
engineering process used to build, document, and verify the case study.

Substantial AI-assisted architecture discussions may be summarized in
[`docs/decision-notes`](docs/decision-notes/README.md). ADRs remain the source
of truth for final architecture decisions.

The AI collaboration model is documented in
[`docs/development/ai-collaboration.md`](docs/development/ai-collaboration.md).

## Repository Structure

```text
gridline-platform-evolution/
  monolith/
    # Rails monolith root; contains Rails' own app/, config/, db/, and Gemfile

  workload-lab/
    # Deterministic workload profiles, runners, archive docs, and k6 integration

  generator/
    # Container image for Rails file generation

  docs/
    adr/
      # Architecture Decision Records
    application/
      # Current Rails baseline feature and limitation documentation
    decision-notes/
      # Context for substantial planning discussions
    design/
      # Application interaction, table, and implementation rules
    development/
      # Development tooling documentation
    domain/
      # Facilities operations domain model
    roadmap/
      # Product and scaling roadmap horizons
    runtime/
      # Development and production-like runtime documentation
    user-stories/
      # Role-centered workflow stories for implemented and planned features

  e2e/
    # Playwright browser workflow tests

  scenarios/
    # Future scaling scenario workspaces

  bin/
    # Project automation scripts
```
