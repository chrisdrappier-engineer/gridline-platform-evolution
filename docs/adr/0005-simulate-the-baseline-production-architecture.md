# ADR 0005: Simulate The Baseline Production Architecture

## Status

Accepted

## Context

ADR 0004 defines Gridline's mature monolith baseline as a reconstructed case
study.

The fictional production history assumes that Gridline's Rails application has
been in production for roughly three years and originally ran in a managed
PaaS-style environment. That environment included a Rails application service,
managed Postgres, environment-variable configuration, basic logs,
platform-managed process restarts, CI-backed but manually promoted deploys,
public DNS/custom-domain routing through the platform, TLS termination, and
vertical scaling through larger app/database plans.

Gridline is not migrating because the current system is already
catastrophically failing. The fictional engineering team has identified that
observed load trends and the near-term product roadmap will make the current
architecture risky. Upcoming reporting and dashboard features would introduce
heavier queries, longer-running work, and more contention between operational
workflows and analytical/reporting workflows.

Engineering has successfully made the case to leadership that platform
investment is needed before these predictable constraints become recurring
incidents.

This ADR decides how the repository will simulate the current baseline
architecture. It does not choose the eventual target platform for horizontal
scaling.

## Decision Drivers

- The simulation must be buildable, runnable, and demonstrable on available
  local hardware.
- The baseline should represent a mature but still vertically scaled Rails/PaaS
  monolith.
- The simulation should preserve the distinction between the fictional
  production environment and the repository's local implementation.
- The project should avoid recurring paid infrastructure for this phase.
- The project should avoid adding a public attack surface that does not
  materially advance the scaling story.
- The baseline should not introduce new runtime technologies before the
  narrative needs them.
- The simulation should preserve important PaaS-style runtime boundaries even
  though it runs locally.
- The simulation should leave room for later scaling stages such as Redis,
  background workers, multiple web instances, load balancing, DNS/routing
  changes, and cloud/platform selection.

## Options Considered

### Actual Hosted PaaS Or PaaS-Like Deployment

A real hosted deployment would improve authenticity and reduce review friction.
Reviewers could inspect a running public application without cloning the
repository or building the project locally.

This option is ruled out for this phase. Gridline Platform Evolution is a
non-revenue-generating portfolio case study with an open-ended lifecycle. Even
modest hosting costs create a recurring obligation, and public deployment
introduces ongoing maintenance, billing, secrets management, provider drift,
abuse handling, and attack surface management.

### Hardware-Deployed Or Host-Local Environment

A machine-specific environment would be familiar and direct, but it would weaken
reproducibility. It would also make it harder to model service boundaries,
runtime isolation, and controlled resource constraints consistently.

This option is ruled out for the baseline.

### Linux VM

A VM could provide stronger OS-level isolation and a more server-like
environment, but it adds operational overhead without improving the core
baseline story enough to justify that complexity.

This option is deferred.

### Local Kubernetes

Local Kubernetes would support resource limits, orchestration, health checks,
and future horizontal scaling concepts. However, Kubernetes introduces
orchestration concerns before the baseline narrative needs them.

This option is deferred until the story reaches orchestration, multiple
replicas, rollout strategy, or cluster-level concerns.

### Dev Container

A Dev Container could improve contributor setup by standardizing the development
workspace, but it does not itself simulate the baseline production architecture.

This option is deferred as optional developer convenience.

### Docker Compose

Docker Compose can represent the baseline as separate services while remaining
local, repeatable, and low overhead. It supports a Rails application container
and a Postgres container, with environment variables, networked service
communication, ports, volumes, health checks, logs, and later resource
constraints.

This option is selected.

## Decision

The baseline production architecture will be simulated locally using Docker
Compose.

The baseline simulation will include:

- a single Rails web/application container
- a Postgres container representing the managed Postgres database from the
  fictional PaaS environment

The baseline will assume Gridline has made full use of Rails-native and
PaaS-native optimizations before adopting horizontal scaling. This includes
normal Rails performance work, database indexes, query cleanup, Rails-native
caching where appropriate, Puma/Rails tuning, and vertical PaaS plan upgrades.

The baseline will not include Redis, background workers, load balancing,
multiple web instances, Kubernetes, public DNS simulation, TLS simulation, or a
target cloud platform.

Redis and worker processes are intentionally deferred. They are expected to
become part of the first horizontal scaling step when Gridline moves
long-running reporting, notification, or dashboard generation work out of the
web request path.

The eventual target production platform is also deferred. A later ADR should
decide whether Gridline's horizontal scaling target is a container platform,
Kubernetes, a cloud-managed service model, another PaaS-like environment, or
something else.

## PaaS Boundaries Preserved In Simulation

Docker Compose does not automatically behave like a managed PaaS. The repository
simulation should intentionally preserve the PaaS-style boundaries that matter
to the scaling story.

The Rails application and Postgres database should run as separate services. The
app should reach Postgres over a network connection, not through an in-process
or host-local shortcut.

Runtime configuration should come from environment variables and documented
local examples, not hardcoded machine-specific files.

The Rails container should not rely on durable local filesystem writes for
business data. Durable state should live in Postgres or in explicitly modeled
external services.

The application should log to stdout/stderr so logs can be collected by Docker
Compose, CI, or a future runtime platform.

The application should tolerate process restarts. Boot behavior, health checks,
migrations, and failure modes should be explicit enough to support local
demonstration and CI verification.

The Postgres container represents managed Postgres, but it does not fully
simulate provider behavior such as automated backups, failover, maintenance
windows, storage limits, or database plan changes.

The fictional PaaS baseline would have included public DNS, custom-domain
routing, and TLS termination through the platform. These are acknowledged but
not simulated in the baseline. Local browser access should use localhost, and
inter-service communication should use Docker Compose service names. DNS,
routing, and TLS concerns are deferred until a later deployment, multi-instance
routing, or target-platform decision requires them.

Secrets should not be committed. The repository should provide examples and
local development defaults where appropriate, while treating real credentials as
runtime configuration.

The baseline should not depend on host-installed Ruby, Postgres, or operating
system libraries in order to run.

Resource constraints should be added when needed to demonstrate scale pressure.
The goal is not to match the vertical capacity of a real PaaS plan, but to
reproduce the kinds of architectural pressure that appear when a vertically
scaled monolith has limited remaining headroom.

## Simulation Boundary

Docker Compose is the repository's simulation mechanism. It is not a claim that
the fictional production system literally ran on Docker Compose.

The fictional production baseline is a managed PaaS-style Rails deployment with
managed Postgres. The repository uses Docker Compose to make that topology
concrete, inspectable, and runnable without paid infrastructure.

If local substitute services are added later, such as a mail sink, they should
be documented as simulation stand-ins for external production dependencies
rather than as part of the fictional production topology.

## Consequences

This keeps the baseline small and understandable.

It gives the project a clean starting point: a mature single-instance Rails
monolith backed by Postgres.

It avoids prematurely adding Redis, workers, orchestration, routing, TLS, or
cloud-specific infrastructure before the scaling narrative requires those
decisions.

It makes the first future scaling step clearer: introduce asynchronous work and
runtime role separation when upcoming reporting and notification features would
otherwise compete with interactive web traffic.

It also means the simulation is less authentic than a public hosted deployment.
Reviewers may need to run the project locally or rely on repository artifacts,
CI results, documentation, and future demo material.

The simulation will need implementation discipline. Docker Compose alone does
not enforce all PaaS assumptions, so the app and supporting documentation must
avoid host-local shortcuts that would weaken the baseline story.

## AI Involvement

This decision was developed through substantial AI-assisted discussion with
Codex. The discussion explored hosted versus local simulation, security
tradeoffs, Docker Compose versus other local options, topology boundaries, Redis
and worker timing, PaaS-style runtime boundaries, DNS/routing/TLS scope, and how
the fictional product roadmap motivates proactive scaling before catastrophic
failure.

A decision note should summarize that discussion and link back to this ADR.
