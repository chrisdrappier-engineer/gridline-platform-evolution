# Gridline Application Baseline

The Gridline application is a mature single-instance Rails monolith used as the
realistic workload for this platform evolution case study.

It represents Gridline after the product has already proven useful in one
operating region. The monolith supports core dispatch workflows, but it has not
yet been adapted for horizontal scaling.

## Company Context

Gridline provides facilities maintenance services for multi-location
businesses: retail chains, clinics, warehouses, restaurants, and property
managers.

When something breaks at a customer site, Gridline dispatchers create and
triage service requests, assign internal teams or vendor partners, record
provider updates, and keep customers informed until the work is complete.

The platform began as a single-region Rails monolith. As Gridline expanded, the
system faced new pressures:

- More dispatchers using the system concurrently
- Service providers communicating work updates
- Customer sites submitting more service requests
- Dispatch dashboards becoming slower
- Reports blocking web requests
- Morning traffic spikes as facilities opened
- A growing need for operational visibility and safer deploys

This repository follows that platform through a realistic scaling journey.

## Baseline Status

The mature monolith baseline is feature complete for the purposes of this case
study. It is not a complete facilities management product, but it has enough
operational depth to create believable reporting, performance, and scaling
pressure.

Future work should generally shift from adding domain features toward measuring
vertical limits, tuning live queries, and documenting optimization tradeoffs
before introducing horizontal scaling.

The first complete application baseline is tagged as `app-v1`.

## Implemented Capabilities

The Rails app currently implements:

- customers, customer sites, service providers, users, roles, and permissions
- dispatcher-owned service request intake, triage, assignment, update, provider
  work recording, and completion verification
- customer-level quote approval thresholds
- one service request quote per request, with automatic approval under the
  customer threshold and facility-manager approval above the threshold
- quote amendment support when material site conditions, concealed damage,
  parts requirements, safety constraints, or other facts change the approved
  scope
- actual service cost entries by category, with quote-to-actual variance shown
  on request detail pages
- lifecycle timestamps and persisted provider performance metrics for response,
  completion, resolution, and verification timing
- service request notes with role-aware visibility rules and evidence file
  attachments
- facility-manager service feedback, ratings, and linked follow-up requests
- live authorization-scoped dashboard reporting for operational, financial,
  quality, and provider performance metrics
- scoped read access for facility managers, customer contacts, and service
  provider users
- admin maintenance screens for customers, sites, providers, users, role
  assignments, and the permission matrix
- role-specific dashboards
- backend-driven searchable, filterable, sortable, paginated tables
- seeded development and demo data
- health and identity endpoints
- RuboCop linting for Ruby and Rails code
- Stylelint linting for Rails CSS assets
- ERB linting for Rails templates
- custom dumb ERB linting for view-boundary rules
- Minitest controller/model/service coverage
- Playwright browser workflow coverage
- Docker Compose CI verification

## Domain Boundary

The initial facilities operations domain is defined in
[`docs/domain`](../domain/README.md).

The current implementation is intentionally narrower than the original domain
sketch. The app centers on customers, sites, service providers, service
requests, users, scoped RBAC, service request quotes, actual service costs,
request notes, request evidence files, service feedback, ratings, and linked
follow-up requests.

Lifecycle timing, provider performance summaries, live dashboard reporting,
note visibility rules, and local evidence-file storage are implemented for the
baseline workflow. SLA reporting and richer management drilldowns remain future
feature work.

## Known Limitations

These limitations motivate later scaling scenarios:

- One web process handles all traffic
- Deployments affect the only app instance
- No shared session store
- No external cache
- No background job processor
- No read replica
- Limited operational visibility
- Reporting is still live-query based and intentionally not cached or
  precomputed

## Repository Layout

The Rails application root lives under `monolith/`. Rails framework paths
therefore read as:

```text
monolith/app/models
monolith/app/controllers
monolith/config
monolith/db
```

The project is expected to remain a single Rails monolith. The `monolith/`
directory name is for repository clarity, not service decomposition.
