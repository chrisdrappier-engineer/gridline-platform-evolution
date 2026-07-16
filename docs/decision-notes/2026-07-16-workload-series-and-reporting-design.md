# 2026-07-16: Workload Series And Reporting Design

## Related Issue

- [Issue 42: Design workload run series and evidence reporting](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/42)

## Context

Scenario 00 can now run as a normal-operations workload profile against the
production-like Gridline runtime. The first runs showed that even larger local
values, such as 100 virtual users and 1000 iterations, did not immediately
produce HTTP failures. That shifted the design focus from single-run success or
failure toward trend evidence: where latency bends, throughput changes, checks
decline, or timeouts begin under increasing load.

The existing single-run output was also hard to reason about. A reader had to
join profile time buckets, workflow weights, workflow definitions, route config,
random parameter bounds, and k6 metrics to understand what traffic was actually
sent.

## Decisions

The primary evidence unit will be a workload run series, not an individual k6
run.

Profiles will own workload texture and named series definitions. Separate series
files are deferred. This keeps the first model easier to inspect while still
allowing separate texture and selected-series hashes for comparison.

Series steps will use fixed virtual users and fixed duration. The workload lab
will not use shared total iterations as the main evidence model. Each virtual
user should behave as an independent sequential user: perform a workflow, wait
for the response, apply cadence-derived think time, then continue until the step
duration ends.

Cadence is explicit and drives think time. The first design supports:

- static cadence
- bounded-random uniform cadence
- bounded-random normal cadence

For normal distributions, definitions remain numeric and explicit. The team
discussed shorthand presets such as tight, moderate, volatile, top-heavy, and
bottom-heavy. Presets were deferred because they can hide the statistical model
and make evidence harder to audit. Top-heavy and bottom-heavy are also skewed
ideas rather than normal distributions.

Warmup and cooldown are deferred. Production smoke confirms that the target is
booted, but does not count as workload warmup. E2E tests are not warmup because
they validate browser workflows, often mutate data, and do not run as part of
production workload evidence.

Steps are cumulative by default. The Rails app, database, caches, and runtime
state continue across steps. This more closely resembles real operational use.
Reset behavior should be explicit for future mutating workloads or controlled
diagnostic comparisons.

Timeout policy belongs to the application or production-like runtime. The
workload lab records timeouts and failures as observed evidence, but does not
define application timeout policy in profiles or series.

Reports should prioritize series-level presentation. Single-run summaries can
remain lean and mostly serve debugging/profile validation. The human-facing
series report should show load progression, line graphs, workload composition,
resource envelope, provenance, and comparability metadata.

The preferred reporting implementation is a generic local dashboard that reads
series JSON. The dashboard should not generate evidence; it visualizes archived
evidence. It may run in a small Docker service that mounts the archive read-only
and exposes a listing/search API for available series outputs.

Full generated plans do not need to be retained permanently. The team first
considered storing generated plans, then recognized that large plans can become
expensive quickly and may not be suitable for k6 `open()` if they grow very
large. The selected middle ground is to treat plans as reproducible artifacts:
record release/tooling tag, profile hash, series hash, seed, and plan hash or
plan digest. A full plan may be generated temporarily or kept externally for
debugging, but Git should store compact provenance and summaries.

## Rationale

Series evidence makes the scaling story more honest. A single run can say
whether the system survived one load point. A series can show whether latency,
checks, throughput, or failures change as load increases.

The sequential-user model better matches real-world interaction than shared
iterations. Users wait for pages to load before taking their next action. If the
application slows down, the result should be fewer completed actions or worse
latency, not work automatically reassigned to faster virtual users.

Keeping named series inside profiles reduces early indirection. A reviewer can
open one profile to see both the workload texture and recommended ways to apply
pressure. Separate hashes still allow later comparison of texture versus series
changes.

Explicit cadence avoids ambiguous workload definitions. Uniform and normal
bounded-random cadence provide realistic variation while remaining explainable
in reports.

Not retaining every full generated plan avoids archive bloat. Reproducibility is
preserved through tags, hashes, seeds, deterministic planner behavior, and plan
digests.

## Follow-Up Work

- [Issue 43: Implement duration-based workload series runner](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/43)
- [Issue 44: Build workload performance reporting dashboard](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/44)
- [Issue 45: Add workload evidence promotion and comparison metadata](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/45)

## AI Involvement

Codex initially framed the next step as collating individual run summaries into
series reports. The user pushed the design toward a stronger model: series as
the foundation, single runs as validation, deterministic per-user behavior,
duration-based execution, cumulative target state, explicit cadence, and
reproducibility through tags/hashes/seeds instead of permanently storing large
plans. Codex helped compare tradeoffs around shared iterations, generated plan
files, virtual plans, dashboard reporting, cadence distributions, warmup and
cooldown, resource envelope reporting, and evidence promotion.
