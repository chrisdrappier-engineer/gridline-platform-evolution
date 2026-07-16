# Gridline Platform Evolution

Gridline is a fictional commercial facilities maintenance company whose internal Rails platform grows from a mature single-instance monolith into a horizontally scalable operations system.

This repository is a portfolio-oriented architecture case study. It demonstrates how a real business application can evolve as usage increases, operational risk grows, and scaling pressure appears.

The goal is not to showcase infrastructure for its own sake. Each scenario introduces a specific business or engineering pressure, then implements the smallest architecture change that addresses it.

## Company Context

Gridline provides facilities maintenance services for multi-location businesses: retail chains, clinics, warehouses, restaurants, and property managers.

When something breaks at a customer site, Gridline dispatchers create and
triage service requests, assign internal teams or vendor partners, record
provider updates, and keep customers informed until the work is complete.

The platform began as a single-region Rails monolith. As Gridline expanded, the system faced new pressures:

- More dispatchers using the system concurrently
- Service providers communicating work updates
- Customer sites submitting more service requests
- Dispatch dashboards becoming slower
- Reports blocking web requests
- Morning traffic spikes as facilities opened
- A growing need for operational visibility and safer deploys

This repository follows that platform through a realistic scaling journey.

## What This Repository Demonstrates

The project focuses on horizontal scaling concepts commonly encountered as a Rails application matures:

- Modular monolith design
- Dockerized local runtime
- Load-balanced web workers
- Shared session state
- Persistent database state
- Read/write database separation
- Redis caching
- Background job processing
- Rate limiting and backpressure
- Health and readiness checks
- Observability foundations
- Deployment and orchestration patterns

CI/CD is included as a supporting engineering practice. Each scenario is intended to be buildable, testable, and smoke-verifiable, but the primary story is application scaling.

## Development Workflow

This project is being built with Codex as an AI development collaborator.

Codex is used to help convert planning discussions into issues, ADRs,
documentation, implementation branches, verification steps, commits, and pull
request summaries. Architectural direction and merge decisions remain
human-owned.

The workflow is intentionally shaped like a scalable engineering process even
though the project is maintained by one person:

- work starts from GitHub issues
- each meaningful change happens on an issue-specific branch
- pull requests explain the scaling story, demo steps, verification, and
  follow-up work
- ADRs capture architecture decisions before they become invisible assumptions
- Docker Compose provides a repeatable runtime for both human and Codex-assisted
  verification

Codex is not part of the Gridline application at runtime. It is part of the
engineering process used to build, document, and verify the case study.

Substantial AI-assisted architecture discussions may be summarized in
[`docs/decision-notes`](docs/decision-notes/README.md). ADRs remain the source
of truth for final architecture decisions.

## Container Baseline

The current runnable foundation is a Docker Compose simulation of the baseline
PaaS boundary for the initial Rails monolith.

The baseline includes:

- an `app` container that runs the Rails monolith with Puma
- a `db` container running Postgres as the managed database stand-in
- a bind mount from `./app` into the app container so local Rails file changes
  are visible without rebuilding the image
- environment-variable configuration
- app-to-database communication over the Compose network
- stdout logging from the app container
- Rails database preparation, test, and health smoke-check scripts
- a named Postgres volume for durable database state
- a named app storage volume for local Active Storage uploads

The Rails app currently implements the first operational baseline:

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
- RuboCop linting for Ruby and Rails code
- Stylelint linting for Rails CSS assets
- ERB linting for Rails templates
- custom dumb ERB linting for view-boundary rules
- Minitest controller/model/service coverage
- Playwright browser workflow coverage

Run the baseline checks with:

```bash
bin/ci
```

This lints CSS assets with Stylelint, builds the app image, prepares the
development and test databases, runs RuboCop, runs ERB lint, runs the Rails
test suite, enforces the dumb ERB template boundary, starts the app service,
and verifies the container health check.

Or run the services directly:

```bash
docker compose up --build
```

After the image has been built once, most Rails source changes do not require a
rebuild:

```bash
docker compose up app
```

Changes under `app/` are mounted into the running container. Restart the app
container for changes that Rails does not reload automatically, and rebuild only
when image-level inputs change, such as `app/Gemfile`, `app/Gemfile.lock`, or
`app/Dockerfile`.

The repository currently has paths such as `app/app/models` because the outer
`app/` directory is the Rails application root inside this portfolio repository,
while the inner `app/` directory is the normal Rails framework directory. The
project is expected to remain a single Rails monolith, so the outer directory is
planned to be renamed for clarity in
[#33](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/33).

Then visit:

```text
http://localhost:3000/health
```

To prepare the development database with presentation-friendly demo data:

```bash
docker compose run --rm -e SEED_DEMO_DATA=true app bin/rails db:prepare db:seed
```

Then start the app and visit:

```text
http://localhost:3000/login
```

The default stub password for seeded users is `gridline`.

Run headed browser smoke tests with:

```bash
npm run test:e2e:headed
```

Run the full browser workflow suite with:

```bash
npm run test:e2e
```

The E2E suite runs with one worker because the browser workflows intentionally
mutate shared demo data while exercising realistic user paths.

Additional browser test details live in [`e2e/README.md`](e2e/README.md).

## Rails Generator Tooling

Rails application files should be created with Rails generators instead of
being handwritten into place. This keeps generated framework structure aligned
with Rails itself while preserving the project's Docker-first development
boundary.

Generator tooling lives outside the application runtime:

- `generator/` defines the Ruby and Rails image used only for file generation
- `compose.generator.yml` mounts the repository into the generator container
- `bin/rails-new` creates the initial Rails application under `app/`
- `bin/rails-generate` runs future Rails generators inside the generated app
- `docs/rails-generator-history.md` records successful generator commands

The generator history is intentionally factual. Architectural context and
human/AI decision-making belong in ADRs, decision notes, commit messages, and
pull request descriptions.

The reasoning behind this tooling is captured in
[`docs/decision-notes/2026-07-09-rails-generator-tooling.md`](docs/decision-notes/2026-07-09-rails-generator-tooling.md).

## Scenario Roadmap

The architecture scenario roadmap is listed below. A broader product and
scaling roadmap lives in [`docs/roadmap`](docs/roadmap/README.md).

| Scenario | Focus | Status |
|---|---|---|
| 00 Vertical Scaling Limit | Pre-history: why vertical scaling is no longer enough | Planned |
| 01 Mature Monolith Baseline | Single-instance Rails operations platform | Baseline Complete |
| 02 Load-Balanced Web Tier | Multiple Rails web workers behind a load balancer | Planned |
| 03 Shared Redis Sessions | Stateless web containers and shared session state | Planned |
| 04 Persistent Postgres State | Shared durable database state | Planned |
| 05 Read Replica Split | Scaling read-heavy dashboard traffic | Planned |
| 06 Redis Cache Store | Reducing repeated expensive reads | Planned |
| 07 Background Jobs | Moving slow work out of the request path | Planned |
| 08 Backpressure And Rate Limiting | Protecting constrained resources during spikes | Planned |
| 09 Observability | Logs, metrics, and operational insight | Planned |
| 10 Orchestration Patterns | Health checks, replica operations, and deployment shape | Planned |

## Starting Point

The first runnable stage is a mature single-instance Rails monolith.

It represents Gridline after the product has already proven useful in one operating region. The monolith supports core dispatch workflows, but it has not yet been adapted for horizontal scaling.

The mature monolith baseline is now considered feature complete for the
purposes of this case study. It is not a complete facilities management
product, but it has enough operational depth to create believable reporting,
performance, and scaling pressure. Future work should generally shift from
adding domain features toward measuring vertical limits, tuning live queries,
and documenting optimization tradeoffs before introducing horizontal scaling.

The baseline application includes:

- Customers and customer sites
- Service requests
- Service feedback, ratings, and linked follow-up requests
- Service providers
- Dispatcher-owned request intake, triage, assignment, provider update capture,
  and completion verification
- Quote approval workflow with customer thresholds, facility-manager approval
  for above-threshold quotes, amendment language, and actual cost capture
- Scoped RBAC with role assignments that may be global or tied to customers,
  sites, or providers
- Role-specific dashboards for dispatchers, facility managers, customer
  contacts, service provider users, and admins
- Admin maintenance workflows for customers, sites, providers, users, role
  assignments, and the permission matrix
- Backend-driven operational tables with search, filters, sorting, pagination,
  and shareable query params
- Live authorization-scoped dashboard reporting for operational, financial,
  quality, and provider performance metrics
- Seeded development and demo data
- Health and identity endpoints
- Minitest and Playwright test coverage
- Docker Compose CI verification

Known limitations at this stage:

- One web process handles all traffic
- Deployments affect the only app instance
- No shared session store
- No external cache
- No background job processor
- No read replica
- Limited operational visibility
- Reporting is still live-query based and intentionally not cached or
  precomputed
- SLA policy reporting and richer management drilldowns are not yet implemented

These limitations motivate the later scenarios.

## Domain Model

The initial facilities operations domain is defined in
[`docs/domain`](docs/domain/README.md).

The current implementation is intentionally narrower than the original domain
sketch. The app currently centers on customers, sites, service providers,
service requests, users, scoped RBAC, service request quotes, actual service
costs, request notes, request evidence files, service feedback, ratings, and
linked follow-up requests. Lifecycle timing, provider performance summaries,
live dashboard reporting, note visibility rules, and local evidence-file
storage are implemented for the baseline workflow. SLA reporting and richer
management drilldowns remain future feature work.

## Repository Structure

```text
gridline-platform-evolution/
  app/
    # Rails monolith root; contains Rails' own app/, config/, db/, and Gemfile

  generator/
    # Container image for Rails file generation

  docs/
    adr/
      # Architecture Decision Records
    decision-notes/
      # Context for substantial planning discussions
    design/
      # Application interaction, table, and implementation rules
    domain/
      # Facilities operations domain model
    roadmap/
      # Product and scaling roadmap horizons
    user-stories/
      # Role-centered workflow stories for implemented and planned features

  e2e/
    # Playwright browser workflow tests

  scenarios/
    02-load-balanced-web-tier/
      # First future scaling scenario workspace

  bin/
    ci
    rails-new
    rails-generate
```
