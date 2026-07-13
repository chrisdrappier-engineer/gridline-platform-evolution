# Decision Note: Baseline Production Simulation

## Date

2026-07-07

## Related ADR

[ADR 0005: Simulate The Baseline Production Architecture](../adr/0005-simulate-the-baseline-production-architecture.md)

## Summary

This discussion refined how Gridline Platform Evolution should simulate the
fictional baseline production environment.

The final decision was to simulate the baseline locally with Docker Compose,
using a single Rails web/application container and a Postgres container
representing managed Postgres from the fictional PaaS environment.

The discussion also clarified what the baseline should not include yet: Redis,
background workers, load balancing, multiple web instances, Kubernetes, public
DNS/TLS simulation, or a target cloud platform.

## Why This Needed A Note

ADR 0005 captures the final decision, but the conversation leading to it
involved several important tradeoffs:

- whether to use a real hosted service or local simulation
- how much authenticity matters for a portfolio project
- how security should be handled without exposing a real public attack surface
- why Docker Compose fits better than VMs, Kubernetes, Dev Containers, or raw
  Docker containers
- when Redis and background workers should enter the architecture
- how the fictional product roadmap motivates proactive scaling
- which PaaS boundaries must still be preserved in a local simulation

Because those decisions were shaped through substantial AI-assisted discussion,
this note records the reasoning path without duplicating the full ADR.

## Context

ADR 0004 established Gridline as a reconstructed case study: a fictional
commercial facilities maintenance company with a mature Rails monolith that has
been in production for roughly three years.

The fictional application originally ran on a managed PaaS-style environment
with managed Postgres, environment-variable configuration, basic logs,
platform-managed restarts, CI-backed but manually promoted deploys,
DNS/custom-domain routing, TLS termination, and vertical scaling through larger
app/database plans.

The project needed to decide how to represent that baseline in the repository
before implementing the initial Rails skeleton.

## Hosted Deployment Versus Local Simulation

The user identified the core tradeoff as authenticity versus resource
allocation.

A real hosted deployment would make the portfolio story more externally
verifiable. A reviewer could inspect a public URL without cloning the repo,
building containers, or relying only on documentation.

Codex expanded that into related tradeoffs:

- lower review friction
- stronger public portfolio signal
- more realistic deployment behavior
- recurring cost
- ongoing maintenance
- public attack surface
- provider drift
- secrets and billing management
- abuse handling

The final position was that real hosting is not justified for this phase.
Gridline Platform Evolution is a non-revenue-generating portfolio case study
with an open-ended lifecycle, so recurring hosted infrastructure creates ongoing
cost and operational responsibility without materially advancing the baseline
scaling story.

## Security Discussion

The user observed that local simulation nearly eliminates real public attack
surface, but that the project should still assume a realistic production attack
surface when designing the application.

Codex suggested that CVE-backed dependency scanning, container image scanning,
secret scanning, Rails static analysis, and OWASP-guided checks could help
preserve security discipline without running a public target.

The discussion distinguished between:

- avoiding unnecessary operational exposure
- still designing as though the system would eventually face real production
  traffic

The project's fictional customer profile was also clarified. Gridline serves
procurement-light commercial facilities customers such as apartment complexes,
regional warehouses, property management groups, and maintenance contractors. It
is not yet serving heavily regulated or enterprise-scale customers such as large
manufacturing plants, airports, hospitals, or major national retailers.

That market position supports reasonable security hygiene without requiring
enterprise-grade compliance in the baseline.

## Simulation Options Considered

The conversation considered several local or repository-contained options:

- hardware-deployed development environment
- host-local Rails and Postgres
- Linux VM
- Docker containers
- Docker Compose
- Dev Container
- local Kubernetes
- lightweight local PaaS simulation
- CI-only simulation
- hybrid local plus CI simulation
- infrastructure-as-code dry-run simulation
- ephemeral preview environments
- single-node self-hosted server
- local process supervisor simulation

The list was narrowed based on a key requirement: the simulation must be
buildable, runnable, and demonstrable under controlled peak-scale pressure on
available hardware.

This ruled out or deferred options that were too machine-specific, too hosted,
too orchestration-heavy, or insufficient for live demonstration.

Docker Compose became the selected option because it can represent separate
services while remaining local, repeatable, and low overhead.

## Docker Compose Versus Related Options

Raw Docker containers were considered too low-level by themselves because the
fictional PaaS baseline includes at least separate application and database
spaces.

Docker Compose was judged superior for the baseline because it can model:

- Rails app service
- Postgres service
- service networking
- environment variables
- ports
- volumes
- logs
- health checks
- future resource constraints

Dev Containers were discussed as a developer convenience, not a production
simulation mechanism. They could later standardize the contributor workspace,
but they do not add much value to the baseline architecture decision.

Local Kubernetes was deferred because it would introduce orchestration, replica
management, rollout behavior, and cluster-level concepts before the baseline
narrative requires them.

## Scaling Narrative

A major part of the discussion clarified that Gridline is not migrating because
the system is already collapsing.

The user framed the story as a company whose engineering team successfully
convinced leadership that architecture investment was needed before upcoming
product roadmap features created predictable failures.

This creates a proactive platform evolution story:

- the current system still works
- the team has used normal Rails/PaaS optimization options
- observed load trends show narrowing headroom
- upcoming reporting/dashboard features will add heavier queries and
  long-running work
- the team is investing before those predictable constraints become recurring
  incidents

This avoids a reactive "rescue a broken system" narrative.

## Redis And Workers

The conversation explored whether Redis and background workers should be part of
the baseline.

Codex initially suggested that a mature Rails PaaS app could plausibly already
have Redis and workers. The user pushed toward a cleaner story where adding
workers becomes the first meaningful horizontal scaling step.

The final position was:

- baseline does not include Redis
- baseline does not include background workers
- baseline assumes Rails-native and PaaS-native optimizations have been used
  first
- Redis and workers enter later when long-running reporting, notification, or
  dashboard generation work needs to leave the web request path

This supports a design philosophy of squeezing reasonable value from Rails and
the PaaS before adding new runtime technologies.

## PaaS Boundaries

The final pass added that Docker Compose is not automatically PaaS-like. The
simulation must intentionally preserve important PaaS boundaries:

- Rails and Postgres are separate services
- app-to-database communication happens over the network
- configuration comes from environment variables
- business data should not depend on durable app-container filesystem writes
- logs should go to stdout/stderr
- the app should tolerate process restarts
- secrets should not be committed
- the app should not depend on host-installed Ruby, Postgres, or OS libraries
- resource constraints can later simulate vertical headroom pressure

DNS and TLS were also acknowledged. The fictional PaaS would have provided
public DNS/custom-domain routing and TLS termination, but the local baseline
does not simulate those yet. Local browser access uses localhost, and Compose
service names handle inter-service communication.

## Decision Outcome

ADR 0005 was updated and accepted with the following baseline:

- simulate the baseline architecture with Docker Compose
- include one Rails web/application container
- include one Postgres container representing managed Postgres
- exclude Redis, workers, multiple web instances, load balancing, Kubernetes,
  public DNS/TLS simulation, and target cloud selection
- defer Redis/workers to the first horizontal scaling step
- defer target platform selection to a later ADR
- preserve key PaaS-style runtime boundaries in the simulation

## AI Involvement

Codex participated as an architectural discussion partner and documentation
assistant.

The user supplied core project direction, corrected narrative framing,
identified the authenticity-versus-resource-allocation tradeoff, pushed for a
proactive roadmap-driven scaling story, challenged premature inclusion of
Redis/workers, and clarified the intended fictional market position.

Codex contributed option framing, tradeoff expansion, terminology, security
posture considerations, topology alternatives, and draft ADR language. Codex
also updated and committed ADR 0005 locally after the user approved the final
direction.

## Related Commit

`fbf0f40 Accept Docker Compose baseline simulation ADR`

## Follow-Up Questions

Future ADRs or implementation work should decide:

- how the Rails skeleton will be generated inside the containerized baseline
- exact Dockerfile and Compose structure
- baseline health check behavior
- local setup commands and README updates
- CI verification for build, test, and boot behavior
- when Redis and background workers are introduced
- how to demonstrate scale pressure under controlled local constraints
- whether a separate decision note should be linked directly from ADR 0005
