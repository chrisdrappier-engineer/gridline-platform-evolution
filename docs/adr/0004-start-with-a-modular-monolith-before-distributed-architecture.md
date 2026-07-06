# ADR 0004: Start With A Modular Monolith Before Distributed Architecture

## Status

Accepted

## Context

Gridline's first scaling pressure is not a need for microservices. The business
needs more capacity, safer deployments, shared state, and operational visibility
while preserving a coherent application model.

Premature service decomposition would add distributed-system complexity before
the project has demonstrated the simpler scaling path.

## Decision

Start with a modular Rails monolith and scale it horizontally before considering
distributed service boundaries.

The application should use clear internal organization, such as service objects,
query objects, and response presenters, while remaining one deployable Rails
application.

## Consequences

This keeps the architecture realistic and restrained. The project can show that
a monolith can be structured, tested, containerized, and horizontally scaled
before being decomposed.

The tradeoff is that some later concerns remain inside one application boundary.
That is intentional for this case study: the central story is evolving a useful
Rails monolith under scaling pressure, not rushing into microservices.

