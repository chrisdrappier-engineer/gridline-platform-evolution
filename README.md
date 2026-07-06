# Gridline Platform Evolution

Gridline is a fictional commercial facilities maintenance company whose internal Rails platform grows from a mature single-instance monolith into a horizontally scalable operations system.

This repository is a portfolio-oriented architecture case study. It demonstrates how a real business application can evolve as usage increases, operational risk grows, and scaling pressure appears.

The goal is not to showcase infrastructure for its own sake. Each scenario introduces a specific business or engineering pressure, then implements the smallest architecture change that addresses it.

## Company Context

Gridline provides facilities maintenance services for multi-location businesses: retail chains, clinics, warehouses, restaurants, and property managers.

When something breaks at a customer site, Gridline dispatchers create and triage service requests, assign technicians or vendor partners, track SLA deadlines, and keep customers informed until the work is complete.

The platform began as a single-region Rails monolith. As Gridline expanded, the system faced new pressures:

- More dispatchers using the system concurrently
- Technicians checking in from the field
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

## Scenario Roadmap

| Scenario | Focus | Status |
|---|---|---|
| 00 Vertical Scaling Limit | Pre-history: why vertical scaling is no longer enough | Planned |
| 01 Mature Monolith Baseline | Single-instance Rails operations platform | Planned |
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

The baseline application includes:

- Customers and customer sites
- Service requests
- Work orders
- Technician assignment
- SLA tracking
- Dispatch board views
- Basic reporting
- Health and identity endpoints
- Seeded demo data
- RSpec test coverage
- Local CI verification

Known limitations at this stage:

- One web process handles all traffic
- Deployments affect the only app instance
- Reports run synchronously
- Dispatch board reads are recomputed per request
- No shared session store
- No external cache
- No background job processor
- No read replica
- Limited operational visibility

These limitations motivate the later scenarios.

## Repository Structure

```text
gridline-platform-evolution/
  app/
    # Rails monolith shared by scenarios

  docs/
    adr/
      # Architecture Decision Records

  scenarios/
    00-vertical-scaling-limit/
    01-mature-monolith-baseline/
    02-load-balanced-web-tier/
    03-shared-redis-sessions/
    04-persistent-postgres-state/
    05-read-replica-split/
    06-redis-cache-store/
    07-background-jobs/
    08-backpressure-rate-limiting/
    09-observability/
    10-orchestration-patterns/

  bin/
    ci
