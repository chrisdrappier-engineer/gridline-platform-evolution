# ADR 0002: Model Gridline As A Mature Single-Region Monolith

## Status

Accepted

## Context

The project could start from a blank MVP, but that would make later scaling work
feel premature. Gridline's architecture journey is stronger if the first
runnable stage already represents a useful internal operations system.

The fictional business has grown enough that dispatchers, technicians, and
managers rely on the platform for daily regional operations.

## Decision

Start with Gridline as a mature single-region Rails monolith.

The baseline application should include customers, sites, service requests, work
orders, technician assignment, SLA tracking, dispatch board views, basic
reporting, health and identity endpoints, seeded demo data, RSpec coverage, and
local CI verification.

## Consequences

This makes the first scenario feel operationally credible. Horizontal scaling is
introduced as a response to real pressure, not as an arbitrary infrastructure
exercise.

The baseline must still stay small enough to finish. Features such as invoicing,
contracts, inventory, vendor marketplaces, customer portals, and full enterprise
auth are intentionally out of scope for the initial monolith.

