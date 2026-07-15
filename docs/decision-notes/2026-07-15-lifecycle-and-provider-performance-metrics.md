# Decision Note: Lifecycle And Provider Performance Metrics

## Date

2026-07-15

## Related Work

- [Issue 17: Add lifecycle timestamps and provider performance metrics](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/17)
- [Roadmap](../roadmap/README.md)
- [User Stories](../user-stories/README.md)

## Summary

Issue 17 adds lifecycle timing and provider performance metrics to the baseline
Rails monolith.

The selected design has two layers:

- lifecycle source timestamps that describe what happened
- persisted metric snapshots that store derived durations for reporting

This keeps individual request history understandable while avoiding repeated
on-the-fly duration calculations when provider performance summaries are shown.

## Decision

Persist lifecycle source timestamps directly on `ServiceRequest`.

The first lifecycle fields are:

- assigned time
- provider response time
- scheduled time
- provider work completion time
- completion verification time
- resolved time
- canceled time

Persist derived duration snapshots on `ServiceRequest` as integer seconds.

The first metric fields are:

- provider response seconds
- provider completion seconds
- resolution seconds
- verification lag seconds

These values are recalculated synchronously when the service request lifecycle
changes. Background aggregation, rollup tables, and percentile reporting are
deferred until reporting volume or latency pressure justifies them.

## Rationale

The user identified that future reports will need aggregate provider response
and completion metrics. Calculating every duration from raw timestamps each time
a provider or management report renders would work at the current size, but it
does not model the direction of the application well.

Persisted metric snapshots create a middle ground:

- timestamps remain the factual source of lifecycle truth
- common report durations are cheap to query
- later reporting work can build on stored values instead of introducing a
  larger aggregation system immediately
- the project gains realistic data for future vertical pressure and indexing
  work

This deliberately stops short of a separate lifecycle event table. The current
feature needs request-level lifecycle facts, not a full audit log of every
transition.

## UI Scope

Issue 17 exposes the metrics in places where they naturally support existing
workflows:

- service request detail pages show request lifecycle timestamps and duration
  snapshots
- service provider detail pages show provider-level performance summaries
- service provider dashboards show scoped provider performance summaries

Broader customer and management reporting remains deferred to later reporting
work.

## Demo Data

Demo seeds are updated as part of the feature. Seeded requests include lifecycle
timestamps and derived metrics so provider performance summaries are meaningful
immediately after rebuilding the demo database.

This follows the project rule that new structure on existing models should be
reflected in demo data during the same feature change.

## AI Involvement

Codex proposed separating lifecycle facts from reportable metric snapshots. The
user refined the direction by pointing out that aggregate provider reports
should not repeatedly calculate response times from timestamps on every render.

Codex implemented the first Rails slice, updated issue #17 to point at `main`
and reflect the selected two-layer design, and added tests and demo data updates
for the workflow.
