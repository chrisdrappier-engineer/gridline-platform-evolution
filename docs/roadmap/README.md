# Roadmap

This roadmap explains how Gridline should grow from the current runnable
baseline into a richer facilities operations platform and a more convincing
scaling case study.

It is not a commitment to implement every listed feature. GitHub issues track
near-term executable work. This document preserves the broader product and
architecture direction so future issues can be created deliberately.

## Current Baseline

Gridline currently has a Docker-first Rails monolith with:

- customers, customer sites, service providers, users, roles, and permissions
- dispatcher-owned service request intake, triage, assignment, update,
  provider work recording, and completion verification
- scoped RBAC for customer, site, provider, and global access
- role-specific dashboards
- backend-driven searchable, filterable, sortable, paginated tables
- seeded demo/development data
- Minitest and Playwright workflow coverage

This baseline is intentionally still a single Rails app instance backed by
PostgreSQL. Redis, background workers, load-balanced app replicas, read
replicas, object storage, and orchestration are deferred until the application
has earned those architecture changes through product behavior and measured
pressure.

## Roadmap Principles

- Build real facilities-operations behavior before adding infrastructure for
  its own sake.
- Keep GitHub issues focused on work that is likely to be implemented soon.
- Use this roadmap for broader feature families and sequencing.
- Treat scaling decisions as consequences of measured pressure.
- Apply responsible vertical optimizations before moving to horizontal
  scaling, unless evidence shows a different order is needed.
- Keep browser tests close to real user workflows instead of relying on direct
  URL jumps.
- Keep backend filtering, sorting, and pagination inside authorization scopes.
- Capture major AI-assisted reasoning in decision notes when the discussion is
  useful context for future reviewers.

## Horizon 1: Operational Richness

This horizon makes the baseline application more like a real facilities
operations product.

The goal is to add enough domain behavior that later performance and scaling
work has believable user, data, and workflow pressure behind it.

Near-term issues:

- [#16 Add service request quote approval and actual cost tracking](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/16)
- [#17 Add lifecycle timestamps and provider performance metrics](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/17)
- [#18 Add request notes and visibility rules](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/18)
- [#19 Add file uploads for request evidence](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/19)
- [#20 Add facility manager feedback and service ratings](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/20)
- [#21 Add customer and management reporting dashboards](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/21)

Additional candidate features:

- SLA policies by customer, site, request type, or priority
- request escalation rules
- request reopen workflows
- duplicate request detection
- emergency request handling
- site contacts and notification preferences
- site access instructions
- provider specialties, territories, and availability windows
- provider acceptance/decline workflow
- provider ETA updates
- work completion checklists
- customer-specific service categories
- customer-specific approval rules

## Horizon 2: Reporting And Vertical Pressure

This horizon uses richer product data to create realistic single-instance
pressure.

The goal is to measure where the monolith slows down, then apply normal
vertical optimizations before introducing distributed architecture.

Candidate work:

- larger deterministic seed profiles for load and stress testing
- query instrumentation and slow-query visibility
- request latency measurement for key workflows
- database indexes for common filters, sorts, joins, and authorization scopes
- N+1 query detection and eager-loading fixes
- table/reporting query optimization
- cost, provider, SLA, aging, and backlog reports
- management dashboards with expensive aggregate reads
- customer dashboards scoped across many sites
- before/after performance notes for optimization work

Load scenarios should include:

- request intake spikes
- dispatcher queue refreshes
- customer reporting spikes
- provider update activity
- mixed workday traffic across supported roles

## Horizon 3: Async Work And Background Processing

This horizon introduces work that should not stay in the web request path.

The goal is to create honest pressure for background jobs, queues, idempotency,
and operational monitoring.

Candidate work:

- large report exports
- notification fanout by email or SMS
- scheduled preventive maintenance generation
- SLA breach calculation
- file processing or attachment post-processing
- provider/customer digest emails
- webhook or event delivery
- background reconciliation jobs

This horizon is the natural place to introduce Redis or another queue backend
if synchronous processing begins to affect ordinary request availability.

## Horizon 4: Horizontal Scaling

This horizon begins after the application has richer workflows and the
single-instance monolith has been measured and optimized.

Candidate work:

- multiple Rails web containers
- load-balanced web traffic
- stateless web process assumptions
- shared session storage
- shared cache storage
- Redis-backed coordination where needed
- background worker containers
- idempotent job and request handling
- database connection pool pressure management
- safe deploy and restart behavior
- cache invalidation in a multi-instance environment

The desired story is not that Gridline moves horizontally because the monolith
was neglected. It moves horizontally because a maintained, measured,
vertically optimized monolith is approaching the limit of what one application
instance can responsibly support.

## Horizon 5: Production-Grade Hardening

This horizon strengthens operational trust after the app has more realistic
scale and workflow surface area.

Candidate work:

- full audit log of request changes
- permission and role-assignment audit logs
- attachment access history
- data retention and archival rules
- customer data export
- soft deletion where operationally appropriate
- security posture documentation
- dependency and CVE checks
- OWASP-aligned review checklist
- structured logs and metrics
- runbooks for local scenarios and future deployed environments
- health, readiness, and operational smoke checks

## Deferred Ideas

These ideas are plausible for the industry context but should remain parked
until they clearly support the product or scaling story:

- asset and equipment inventory
- asset service history
- location hierarchy beyond customer sites
- provider compliance documents
- insurance/license expiration tracking
- labor/material/trip charge rate cards
- invoice review and disputes
- customer approval before exceeding cost thresholds
- budget tracking by customer, site, or department
- public customer portal features beyond scoped tracking
- mobile-first provider workflow
- advanced charting and BI-style exploration

## Issue Creation Guidance

Create GitHub issues when a roadmap item becomes concrete enough to implement.

An issue should usually include:

- the user or role affected
- the business problem
- the workflow or data model change
- authorization and visibility expectations
- test expectations
- how the work supports the scaling narrative, if relevant

Avoid creating issues for every deferred idea. A smaller, intentional backlog is
more useful for this project than a very large speculative one.
