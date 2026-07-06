# ADR 0001: Use Rails As The Scaling Demonstration Workload

## Status

Accepted

## Context

Gridline Platform Evolution is a portfolio-oriented architecture case study. The
repository needs a realistic application workload that can start simply, support
business workflows, and then expose meaningful scaling pressures as usage grows.

The workload should be familiar enough that the architecture decisions are easy
to understand, but substantial enough to demonstrate more than a toy service.

## Decision

Use Ruby on Rails as the primary application framework for the Gridline
operations platform.

The app will begin as a single Rails monolith and evolve through scenarios that
demonstrate horizontal scaling, shared state, persistence, caching, background
jobs, observability, and deployment-oriented patterns.

## Consequences

Rails provides a credible business application shape with routing, controllers,
models, database migrations, background job conventions, test tooling, and
production deployment concerns.

This makes it possible to demonstrate scaling decisions against a recognizable
web application instead of a synthetic HTTP server.

The tradeoff is that Rails adds framework complexity. The project should keep
the domain focused and avoid letting framework features distract from the
architecture story.

