# 2026-07-16: Production Runtime Hardening

## Related Issue

- [Issue 35: Harden production-like runtime before workload evidence runs](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/35)

## Context

The workload lab will produce evidence for vertical optimization and later
horizontal scaling decisions. That evidence needs to target a production-shaped
runtime rather than the current development-oriented Docker setup.

A static audit showed that the baseline runtime still uses development defaults:
the app image defaults to development, Compose bind-mounts source into the
container, production assets are not prepared through a release path, Active
Storage uses local disk in production, and hosted-style database, host, proxy,
SSL, health, and stale Action Cable assumptions need a hardening pass.

## Decision

Before implementing workload scenarios, Gridline will add a production-like
local runtime and validation path.

This work is not a SaaS deployment. The goal is to create a credible local
production target that can be built, booted, migrated, seeded, smoke-checked,
and targeted by future workload-lab scenarios.

The production hardening work will distinguish three database/data flows:

- **Provision**: first boot of a new local production-like environment.
- **Deploy**: non-destructive update of an existing production-like database.
- **Evidence Reset**: explicit local/workload-lab reset used to recreate known
  data for repeatable workload evidence.

Normal production deploy commands must be non-destructive. Destructive reset
commands must be separately named and documented as local or workload-lab-only.
Deploy-mode seeding must be limited to required baseline data, such as RBAC
definitions, and must not load development or demo scenario records.

The validation path will also be split:

- `bin/ci` remains the normal codebase validation pipeline.
- `bin/ci:production` validates the production-like local runtime end to end.
- `bin/production-smoke` validates an already-running production target by URL.

## Rationale

Production deployment usually targets an existing database with real data. The
project also needs a first-boot path for a fresh local production environment
and a resettable evidence path for repeatable workload experiments. Treating
those as one command would either make normal deployment dangerously
destructive or make workload evidence difficult to reproduce.

The split between `bin/ci:production` and `bin/production-smoke` keeps the
responsibilities clear. The production CI script can build and manage the local
runtime, while the smoke script can later be pointed at an already-running
hosted or SaaS environment without assuming local Docker control.

## Boundaries

This hardening does not choose a SaaS provider, deploy to a hosted environment,
introduce horizontal scaling infrastructure, or implement workload-lab
scenarios.

This work may keep some choices intentionally local while documenting their
limits. For example, Active Storage may remain local for this phase if that is
chosen deliberately, but the decision must be explicit because local disk is
not suitable for a horizontally scaled or ephemeral hosted runtime.

## AI Involvement

Codex audited the current application for production readiness and identified
the development-oriented runtime assumptions. The user identified that the
production data story needed to distinguish fresh environments from existing
databases, and that destructive reset behavior should be separated from normal
deployment. Codex helped frame those concerns as provision, deploy, and
evidence-reset modes, plus a separate production CI and production smoke
validation split.
