# ADR 0008: Use Live Queries For Initial Reporting Metrics

## Status

Accepted

## Context

Gridline now tracks enough operational data to expose reporting dashboards:
request status, priority, quote approval, actual costs, provider lifecycle
metrics, ratings, and linked follow-up requests.

Reporting metrics create a freshness tradeoff. A facility manager checking
whether work is complete before an approval deadline needs current operational
data. A management user reviewing general trends may tolerate older numbers if
the interface makes that staleness clear.

Reporting dashboards are also expected to become a performance pressure point
as seeded data volume grows. Live aggregate queries can repeatedly scan, join,
group, sort, and filter transactional records inside authorization scopes. That
pressure may appear at the database/query layer before horizontal Rails web
scaling is useful.

## Decision

Gridline reporting dashboards will initially calculate metrics live from
authorization-scoped transactional records.

The first reporting implementation may add obvious relational indexes that
support known filters, joins, and sorts. Those indexes are considered baseline
schema design, not a cached reporting strategy.

Persistent dashboard caching, stored calculated metrics, denormalized reporting
tables, and asynchronous metric refresh jobs are deferred until measurement
shows which dashboards or metrics need that added complexity.

Any future non-live reporting metric must expose freshness behavior in the UI,
including when the value was last updated or how frequently it refreshes.

## Consequences

This preserves operational freshness for workflows where stale metrics could
mislead users.

It also creates a deliberate vertical pressure point. As data volume grows,
dashboard latency and database load should be measured before introducing
caching or precomputed reporting structures.

The accepted pressure is useful for the platform-evolution story. It allows the
project to show responsible progression from live queries, to indexing and
query tuning, to cached or stored reporting only when the need is visible.

This decision does not imply intentionally naive queries. Reporting should still
avoid avoidable N+1 access, use authorization scopes correctly, and include
indexes for predictable access paths.

## Verification

Reporting work should be verified with:

- Rails tests for authorization-scoped dashboard metrics
- browser workflow coverage for visible dashboard reporting sections
- schema review for supporting indexes
- future query measurement when larger seed profiles are introduced

## AI Involvement

The user raised the distinction between SLA-sensitive freshness and general
trend awareness, then argued for live queries because they create a clear
optimization pressure point. Codex recommended pairing live metrics with
obvious indexes while deferring persistent caching because cache invalidation
and freshness disclosure would add architectural work before measurement shows
where it is needed.
