# 2026-07-16: Live Reporting Dashboard Metrics

## Related Issue

- [Issue 21: Add customer and management reporting dashboards](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/21)

## Context

After service request costs, provider metrics, evidence, ratings, and follow-up
requests were added, Gridline had enough operational data to expose real
dashboard reporting.

The discussion centered on whether reporting metrics should be live, cached, or
stored as calculated data.

## Decision

Initial reporting dashboards use live, authorization-scoped queries against
transactional data.

Obvious database indexes are included because they support known access paths.
Persistent dashboard caching, stored metrics, denormalized read models, and
asynchronous refresh jobs are deferred.

## Rationale

Live metrics keep SLA-sensitive and deadline-sensitive workflows honest. A user
checking operational status should not have to wonder whether a dashboard value
was refreshed before or after the latest request update.

At the same time, live aggregate reporting is expected to create measurable
query pressure as data grows. That pressure is useful for the project because it
creates a truthful reason to measure, index, and optimize before introducing
horizontal scaling or more complex reporting architecture.

Caching was deliberately deferred because persistent caches introduce freshness
and invalidation responsibilities. Rails provides useful caching primitives, but
it does not remove the need to decide when cached dashboard values expire and
how users should be told that a value may be stale.

## Implementation Shape

- Add an ADR for live reporting freshness and accepted pressure.
- Add a `ReportingSummary` object for scoped aggregate calculations.
- Add a dashboard reporting view model that prepares visible metric cards.
- Show a freshness note explaining that metrics are calculated live at page
  load.
- Add composite indexes for predictable reporting filters and joins.
- Keep ERB templates focused on rendering prepared reporting sections.

## AI Involvement

Codex initially framed dashboard reporting as likely decision-note material.
The user identified freshness as an architectural concern and pushed the
conversation toward an ADR. Codex then helped articulate the boundary:
start with live scoped metrics and obvious indexes, accept the visible pressure,
and defer stored or cached metrics until measurement justifies the invalidation
work.
