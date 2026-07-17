# Gridline Platform Evolution

Gridline Platform Evolution is a portfolio-oriented architecture case study
about growing a realistic Rails monolith through evidence-driven scaling
decisions.

Gridline is a fictional commercial facilities maintenance company. Its
operations platform coordinates service requests across customers, sites,
dispatchers, facility managers, customer contacts, service providers, and
administrators. The application starts as a mature single-instance monolith
because that is a common and reasonable place for a business operations product
to begin.

The purpose of this repository is to show what happens next. As usage grows and
new operational requirements appear, the project measures the current system,
documents the pressure, and applies the smallest architecture change that
addresses the evidence. The goal is not to showcase infrastructure for its own
sake; the goal is to make scaling decisions legible.

The repository also demonstrates how AI collaboration can speed and simplify
the development lifecycle of a large, complex application when the work remains
organized around human-owned architecture decisions, reviewable issues,
reproducible verification, and explicit documentation.

## Start Here

- [Quick Start](docs/runtime/quick-start.md): verify the project, start the
  production-like runtime, run the first workload profile, and inspect the
  generated results.
- [Application Baseline](docs/application/README.md): understand the current
  feature-complete Rails monolith.
- [Roadmap](docs/roadmap/README.md): see where the product and scaling story is
  headed.

Version tags:

| Tag | Meaning |
|---|---|
| `app-v1` | First complete Gridline monolith application |
| `workload-lab-v1` | First meaningful workload lab scenario |

## Documentation Map

### Application

- [Current Rails monolith baseline](docs/application/README.md)
- [Facilities operations domain model](docs/domain/README.md)
- [Role-centered user stories](docs/user-stories/README.md)

### Runtime

- [Quick start](docs/runtime/quick-start.md)
- [Development runtime](docs/runtime/development.md)
- [Production-like runtime](docs/runtime/production-like.md)

### Workload Evidence

- [Workload lab](workload-lab/README.md)
- [Evidence-first workload lab ADR](docs/adr/0009-create-an-evidence-first-workload-lab.md)
- [Duration-based workload series ADR](docs/adr/0010-use-duration-based-workload-series-as-performance-evidence.md)

### Engineering Process

- [AI collaboration model](docs/development/ai-collaboration.md)
- [Rails generator tooling](docs/development/rails-generator-tooling.md)
- [Design and implementation rules](docs/design/README.md)
- [Browser workflow tests](e2e/README.md)

### Architecture And Planning

- [Architecture Decision Records](docs/adr/README.md)
- [Decision notes](docs/decision-notes/README.md)
- [Product and scaling roadmap](docs/roadmap/README.md)

## Repository Shape

The primary code areas are:

- `monolith/`: Rails monolith used as the system under test
- `workload-lab/`: deterministic workload profiles, runners, archive docs, and
  k6 integration
- `generator/`: containerized Rails file-generation tooling
- `docs/`: ADRs, decision notes, design rules, runtime docs, roadmap, domain
  notes, and user stories
- `e2e/`: Playwright browser workflow tests
- `bin/`: project automation scripts
