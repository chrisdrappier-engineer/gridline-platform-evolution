# 2026-07-16: Workload Lab Strategy

## Related Issue

- [Issue 34: Create workload lab foundation for evidence-based scaling pressure](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/34)

## Context

The mature monolith baseline is complete enough to begin measuring scaling
pressure. The next project phase needs workload evidence that can support
vertical optimization decisions before the project introduces horizontal
scaling infrastructure.

The initial question was how to create pressure in a way that supports the
case-study narrative without producing misleading results from a laptop-only
environment.

## Decision

The workload lab will prioritize evidence mode over live demo mode.

Evidence mode means workload runs are designed to produce recorded,
reproducible artifacts that can support later architecture decisions. Live demos
may be derived from the same tooling later, but the first phase will optimize
for repeatability, metadata capture, interpretation, and before/after
comparisons.

The workload lab will use k6 with business-workflow scenario design. Workload
profiles will be defined by operational texture and scaled by volume and
frequency. Profiles may use bounded randomization, but promoted evidence runs
must record deterministic seeds so the same traffic composition can be rerun
against later application or configuration changes.

Raw outputs will be kept out of Git. The repository will store the strategy,
profiles, promoted seeds, small evidence summaries, and scripts needed to
reproduce or package results. Bulky exploratory results and raw run artifacts
will live in an ignored local archive folder that mirrors the intended Google
Drive archive structure.

## Rationale

Live workload demonstrations can be useful, but they are fragile. Docker state,
laptop thermals, background processes, presentation timing, and random run
variance can all distort the story. Recorded evidence allows the project to
show the workload shape, result, interpretation, and resulting architecture
change more clearly.

k6 was chosen because its strengths align with measurement discipline:
thresholds, checks, latency percentiles, repeatable runs, compact metrics,
Docker-friendly execution, and structured output. Locust was considered because
its Python user/task model maps naturally to role-based workflows, but it would
require more local discipline to avoid leaning on the interactive web UI. A
custom Ruby runner was rejected because it would require building load-runner
behavior that k6 already provides. Playwright remains the right tool for
browser-visible workflow verification, not pressure generation.

The user introduced the distinction between workload texture, volume, and
frequency. Texture describes what kinds of work occur and in what proportions.
Volume describes the number of actors, records, and active work items.
Frequency describes how often actions occur. Keeping those concepts separate
will make workload profiles easier to explain and easier to scale.

Bounded randomization was selected over purely static scripts because normal
operations are not perfectly uniform. However, randomness must be controlled. A
seed should represent a deterministic traffic path through a profile's
boundaries over time, not merely a random number. Promoted seeds can then be
used as reproducible examples of meaningful pressure points.

## Boundaries

The workload lab will not claim that local Docker resource envelopes faithfully
emulate production hardware. Docker can constrain CPU allocation, memory
allocation, process settings, Puma worker/thread settings, database pools, and
PostgreSQL settings. It does not make the laptop behave like a different CPU,
slower RAM, or a real SaaS provider.

The value of local resource envelopes is diagnostic. They help show whether a
pressure point responds to more vertical headroom or instead points toward
query shape, database contention, caching, background work, or eventually
horizontal scaling.

The first scenario should model normal Gridline operational texture, then scale
frequency and load until the first meaningful boundary appears. Focused
endpoint pressure should come afterward as a diagnostic step, not as the first
source of truth.

## Follow-Up

Before implementing workload scenarios, the production-like runtime should be
hardened so evidence runs target a production-shaped environment instead of the
current development-oriented Docker setup. That work is captured in
[Issue 35: Harden production-like runtime before workload evidence runs](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/35).

## AI Involvement

Codex initially framed the workload lab around k6, resource envelopes, and
recorded evidence. The user challenged the design from several angles:
presentation usefulness, laptop hardware constraints, non-linear scaling,
Monte Carlo-style variation, repository bloat, Google Drive archival, and the
need to separate seed definitions from run results. Codex helped consolidate
those concerns into an evidence-first workload strategy with bounded
randomization, promoted seeds, ignored raw archives, and production-runtime
hardening as the next prerequisite.
