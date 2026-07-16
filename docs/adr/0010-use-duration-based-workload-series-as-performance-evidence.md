# ADR 0010: Use Duration-Based Workload Series As Performance Evidence

## Status

Accepted

## Context

The workload lab can now execute Scenario 00 as a single k6 run with configurable
virtual users and iterations. That proved the production-like Rails monolith can
receive business-shaped workload traffic, but a single run is a weak evidence
unit for scaling decisions.

The project needs to explain how application behavior changes as load increases.
That requires a controlled series of workload steps, not isolated ad hoc runs.
The reporting artifact should help a reviewer see trends in latency, throughput,
checks, failures, resource envelope, and workload composition.

The first implementation used k6 shared iterations. That model is useful for
profile validation and bounded smoke checks, but it does not represent real
users particularly well. In a shared-iteration model, faster virtual users can
consume more of the global work pool while slower virtual users do less. Real
users do not hand their next action to another user when a page is slow.

The project also needs to avoid archive and repository bloat. Fully materialized
plans can grow quickly as virtual users, duration, and generated events
increase. Keeping every generated plan indefinitely is unnecessary if the plan is
reproducible from tagged code, profile content, selected series, and seed.

## Decision

Gridline will treat named workload series as the primary performance evidence
unit.

Profiles will own both workload texture and recommended named series
definitions. A profile describes actor roles, workflow mix, time buckets,
workflow bounds, and the named series that apply pressure to that texture. The
project will not create separate series files in the first implementation.

Single profile runs remain useful for smoke checks, profile validation, route
debugging, and k6 wiring. They are not the primary artifact for architecture
performance claims.

Series steps will use a time-bounded sequential-user model:

- each step defines a fixed number of virtual users
- each step defines a fixed duration
- each virtual user executes independently
- each virtual user waits for a workflow response before applying cadence-driven
  think time
- there is no shared global iteration pool for evidence series
- completed events, throughput, latency, failures, and timeouts are measured
  outcomes

Cadence will be explicit. The first pass will support:

- `static`
- `bounded-random` with `uniform`
- `bounded-random` with `normal`

Normal cadence definitions must use explicit numeric parameters such as `min`,
`max`, `mean`, and `standardDeviation`. Human-friendly cadence presets are
deferred.

Cadence defines user pacing. For the first implementation, cadence should drive
think time after a workflow response completes. If the application slows down,
the virtual user completes fewer events during the fixed duration. This is
intentional.

Series steps run sequentially against cumulative target runtime and data state
by default. The Rails application, database, process state, and caches remain
running across steps. k6/client sessions may reset per step. Reset-per-step
behavior must be explicit if added later.

Warmup and cooldown phases are deferred. Production smoke validates that the
target is booted, but is not treated as workload warmup. Warmup or cooldown
should be added only if evidence shows first-step noise, cache sensitivity,
queue drain, or step interference that justifies the extra protocol.

Timeout policy belongs to the target application/runtime, not the workload lab.
The workload lab records timeout and failure outcomes. Any client-side safety
timeout used by the runner must be recorded as runner metadata, not treated as
the application SLA.

The workload lab will not require permanently storing full generated plans.
Instead, promoted evidence should record enough provenance to regenerate and
verify plans:

- target application commit and tag when available
- workload tooling commit and tag when available
- profile hash
- texture hash
- selected series name
- selected series hash
- seed
- plan hash or deterministic plan digest
- resource envelope snapshot
- seed data profile

The same workload tooling tag, profile content, selected series, and seed should
produce the same deterministic plan or plan digest. Full plans may be generated
as temporary or external archive artifacts for debugging and audit, but they are
not required permanent Git artifacts.

Series reporting will be centered on a reusable reporting dashboard rather than
per-run markdown as the main human artifact. Series JSON is the source of truth.
A dashboard can render trend charts, tables, workload composition, resource
envelope, and provenance from any compatible series JSON.

## Consequences

Performance evidence will be based on trends across load levels rather than one
isolated k6 execution.

The workload lab will need a series runner that differs from the current
single-run shared-iterations path. Existing single-run commands can remain for
validation, but series execution will become the main evidence workflow.

Series output must include workload composition. Reports should show what
traffic was actually generated and completed: actor roles, workflows, routes,
weights, observed events, observed shares, and request counts.

Series output must include resource context. A result is meaningful only when the
target resource envelope and runtime settings are visible.

Comparisons between application versions require discipline. Reports should warn
or mark comparisons as partial when profile hash, series hash, seed, resource
envelope, seed data profile, or execution model differ.

Generated plans should be treated as reproducible execution artifacts rather
than permanent source-controlled artifacts. This reduces repository and archive
growth while preserving auditability through tags, hashes, seeds, and plan
digests.

The first implementation should remain small enough to validate the model:
duration-based series execution, explicit cadence, cumulative steps, collated
series JSON, and enough composition/provenance data for a later reporter.

Follow-up implementation is tracked in:

- [Issue 43: Implement duration-based workload series runner](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/43)
- [Issue 44: Build workload performance reporting dashboard](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/44)
- [Issue 45: Add workload evidence promotion and comparison metadata](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/45)

## Verification

This ADR is documentation-only. Verification for the design consists of:

- documenting the accepted workload series model
- splitting implementation into follow-up issues
- preserving ADR 0009's evidence-first direction while refining how evidence is
  generated and reported

Future implementation should verify:

- profile validation for named series
- deterministic cadence and event generation
- duration-based sequential-user execution
- series JSON collation
- dashboard rendering against fixture series data
- provenance and comparability metadata

## AI Involvement

The user identified that single-run reports do not tell the most useful
performance story, challenged shared iterations as unrealistic user modeling,
proposed deterministic plan reproducibility through tags, hashes, and seeds, and
emphasized series-level trend reporting. Codex helped evaluate alternatives such
as full plan storage, plan streaming, file-based reports, generic dashboard
reporting, cadence distributions, and evidence promotion boundaries.

More detail is captured in the
[Workload Series And Reporting Design](../decision-notes/2026-07-16-workload-series-and-reporting-design.md)
decision note.
