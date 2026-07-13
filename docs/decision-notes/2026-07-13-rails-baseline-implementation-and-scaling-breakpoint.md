# Decision Note: Rails Baseline Implementation And Scaling Breakpoint

## Date

2026-07-13

## Related Work

- [Issue 15: Create Docker-first Rails monolith skeleton](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/15)
- [ADR 0004: Define The Mature Monolith Baseline As A Reconstructed Case Study](../adr/0004-define-the-mature-monolith-baseline-as-a-reconstructed-case-study.md)
- [ADR 0005: Simulate The Baseline Production Architecture](../adr/0005-simulate-the-baseline-production-architecture.md)
- [ADR 0006: Use Database-Backed Scoped RBAC For Authorization](../adr/0006-use-database-backed-scoped-rbac-for-authorization.md)
- [User Stories](../user-stories/README.md)
- [Application Interaction Rules](../design/application-interaction-rules.md)
- [Table Interaction Rules](../design/table-interaction-rules.md)

## Summary

This implementation phase moved Gridline from pre-code architecture planning to
a runnable Docker-first Rails monolith baseline.

The application now has a realistic enough operational surface to support the
next phase of the project: generating production-shaped load, identifying
vertical scaling chokepoints, applying responsible single-instance
optimizations, and then using the remaining constraints to justify horizontal
scaling work.

## Why This Needed A Note

This phase contained many individual implementation decisions that are too
small for separate ADRs but too significant to leave only in commit history.
The work also marks a narrative breakpoint for the project.

Before this phase, Gridline existed mostly as a documented architectural case
study. After this phase, it exists as a Rails application with enough domain
behavior, scoped access, UI workflows, seeded data, and browser coverage to be
used as a performance and scaling demonstration workload.

## Implementation Direction

The branch kept the Docker-first direction established by ADR 0005.

Rails, PostgreSQL, and the generator environment were kept in separate Docker
contexts so the application can be built, run, generated, and tested without
depending on a host-local Ruby/Rails installation.

The development app container was later changed to mount the local application
directory so view and code changes can be reflected without rebuilding the app
image. This keeps the Docker-first runtime while making day-to-day iteration
reasonable.

## Rails Generation And Baseline Models

The initial Rails app was generated through the repository's generator tooling
rather than hand-created file-by-file.

The first model layer established Gridline's core operational entities:

- users
- customers
- customer sites
- service providers
- service requests
- roles
- permissions
- role permissions
- scoped user role assignments

The application was also refactored to use UUID primary keys before the schema
grew more complex. That change supports the broader platform-evolution story by
avoiding early dependence on sequential integer identifiers.

## Authorization And Role-Based Workflows

The role model was refined around the workflows Gridline needs to demonstrate:

- dispatcher
- facility manager
- customer contact
- service provider user
- admin
- company management

The implementation added database-backed scoped RBAC and began enforcing it in
controllers, dashboards, record visibility, and table queries.

The important design principle is that authorization is not only a UI concern.
Dashboards, index pages, show pages, controller actions, and backend queries
all need to respect the same resource visibility rules.

## UI And Interaction Rules

The UI moved from simple generated views toward a role-aware operational
application.

Notable interface decisions included:

- role-specific dashboards
- a persistent left-side navigation panel
- contextual create flows, such as creating a service request from a site page
- dismissible flash notifications that automatically expire
- CRUD views for core resources where permissions allow them
- reduced manual entry in create forms by carrying available context forward

These choices are documented in the application interaction rules so future UI
work can follow the same patterns instead of adding one-off dashboard links.

## Data Tables

The app introduced a reusable backend-driven table pattern for index and
dashboard data.

The table direction includes:

- server-side filtering
- server-side sorting when pagination is present
- pagination
- per-page selection
- humanized column labels
- query-preserving controls
- focus restoration for dynamic search input updates

The project intentionally avoided client-side filtering because the core
concern is authorized access to backend data. Filtering and sorting must happen
inside the same scope boundaries as the rest of the application.

## Testing Direction

The test suite expanded in two directions.

Rails tests cover model behavior, controller permissions, authorization checks,
and CRUD access. Playwright covers browser workflows and visual interaction
paths.

The E2E suite was also given a real-world workflow constraint: tests should
move through visible navigation and UI controls rather than jumping directly to
deep URLs. Direct URL access is still useful at lower test layers, but browser
workflow tests should reflect what a real user can discover and do.

## Future Feature Planning

The project added user story files for each major role and created follow-up
GitHub issues for the next set of feature dimensions:

- service request cost tracking
- lifecycle timestamps and provider performance metrics
- request notes and visibility rules
- file uploads for request evidence
- facility manager feedback and service ratings
- customer and management reporting dashboards

These features are intentionally deferred from the current branch. They add the
data dimensions that will make reporting richer and more realistic, but the
current branch is already large enough to close as the baseline foundation.

## Scaling Breakpoint

The user identified that Gridline has reached an inflection point.

The application now has enough complexity to begin creating realistic pressure
on vertical scaling chokepoints:

- request spikes against normal workflows
- large, scoped, filtered, and sorted index queries
- reporting-style reads that compete with transactional actions
- seeded data large enough to make query plans meaningful
- mixed operational load across multiple roles

Codex recommended that the next scaling phase should not jump directly to
horizontal scaling. A stronger real-world narrative is to first demonstrate
responsible vertical optimization:

- measure slow endpoints and queries
- add missing database indexes
- identify N+1 queries
- optimize expensive table/reporting paths
- add load-test scenarios
- document before/after results
- then use the remaining constraints to justify horizontal scaling

The resulting project story is that Gridline does not move to horizontal
scaling because the monolith is carelessly broken. It moves there after a
well-maintained monolith approaches the limits of what one application instance
can responsibly support while the product roadmap continues adding operational
visibility and reporting demands.

## AI Involvement

Codex contributed by:

- implementing the Docker-first Rails baseline
- generating and adapting Rails models, controllers, views, migrations, seeds,
  tests, and E2E coverage
- suggesting the generator abstraction and documenting its use
- helping evaluate UUID primary keys before deeper schema work
- implementing the scoped RBAC model selected in ADR 0006
- proposing role-specific dashboard and navigation patterns
- helping shape design rules for contextual forms and backend-driven tables
- expanding test coverage around browser-visible workflows
- creating issue descriptions for future reporting and service-quality features
- recommending the vertical-optimization phase as the next architectural story

The user made the decisive product and architecture calls:

- keeping the project Docker-first
- using generated Rails artifacts where possible
- choosing UUID primary keys before schema growth
- requiring scoped authorization to be enforced beyond dashboards
- defining the supported role set and workflow expectations
- insisting that E2E tests behave like real user workflows
- choosing backend filtering over frontend filtering
- identifying the current branch as large enough to close and move into a new
  phase
- framing the next discussion around vertical scaling pressure before
  horizontal scaling
