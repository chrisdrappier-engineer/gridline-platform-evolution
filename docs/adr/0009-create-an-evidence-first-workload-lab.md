# ADR 0009: Create An Evidence-First Workload Lab

## Status

Accepted

## Context

Gridline has completed the mature Rails monolith baseline for the first
scenario. The next phase should measure how the application behaves under
increasing operational pressure before introducing optimization or horizontal
scaling infrastructure.

The project needs workload evidence that supports architectural decisions. A
live demo can show that the system runs, but live pressure tests are vulnerable
to laptop state, Docker state, thermals, background processes, and presentation
timing. Recorded evidence is a stronger foundation for explaining why a scaling
or optimization change makes sense.

The workload lab must also avoid repository bloat. Exploratory runs may produce
many raw artifacts, time-series files, and repeated metric outputs. Those files
are useful while investigating behavior, but most do not belong in Git.

## Decision

Gridline will create a workload lab optimized for recorded evidence rather than
live demonstration.

The workload lab will use k6 as its initial pressure tool. k6 scenarios should
be designed around business workflows instead of raw endpoint hammering. Focused
endpoint pressure may still be used after a workflow run identifies a likely
bottleneck.

Several alternatives were considered:

- Locust maps naturally to role-based workflow modeling through Python user and
  task classes, but it would require more project discipline around thresholds,
  repeatable CLI evidence, and avoiding reliance on the interactive web UI for
  interpretation.
- A custom Ruby runner using Typhoeus or Async::HTTP would keep workload code
  closer to the Rails application, but would require building runner behavior
  that k6 already provides, including concurrency, ramping, thresholds, metrics,
  result capture, and summaries.
- Playwright remains appropriate for browser-visible workflow verification, but
  browser automation is too expensive for high-concurrency pressure testing.
- JMeter or Ruby JMeter would provide mature load-testing capabilities, but the
  toolchain is heavier than needed for the first workload-lab foundation.

k6 is selected because the workload lab's first responsibility is evidence
quality: repeatable pressure, threshold-based interpretation, compact metrics,
Docker-friendly execution, and before/after comparisons. Business-workflow
scenario design will be used to keep the workload narrative readable.

Workload profiles will be defined by operational texture and scaled by volume
and frequency:

- texture describes the mix of roles, workflows, and action categories
- volume describes the number of users, records, active work items, and data
  breadth involved
- frequency describes how often actions occur, including wait times, refresh
  intervals, bursts, and lulls

The first major scenario should model normal Gridline operations, then increase
frequency and load until the first meaningful boundary appears. Follow-up
diagnostic profiles should be based on the behavior that actually degrades.

The workload lab will use bounded randomized evidence with deterministic seed
tracking. A profile defines allowed boundaries. A seed chooses a reproducible
path through those boundaries over time. The same profile, seed, duration, data
set, resource envelope, and application revision should reproduce the same
traffic composition.

Seeds are not all committed. Exploratory seeds may stay in ignored archive
outputs. Seeds are committed only when promoted because they demonstrate a
recurring or architecturally meaningful pressure point.

The workload lab will distinguish four artifact types:

- profiles: tracked definitions of workload boundaries
- seeds: tracked only after promotion into canonical evidence
- evidence summaries: tracked markdown or compact structured summaries that
  support decisions
- raw archives: ignored local outputs that may later be mirrored to Google
  Drive or another external archive

The repository will include only directories and files that contain real current
artifacts. It will not include stub profile, seed, scenario, script, or evidence
directories before they are needed.

## Consequences

Recorded runs become the basis for scaling and optimization claims. A future ADR
may cite a promoted seed and evidence summary rather than relying on a live
observation.

Bounded randomization makes the workload more realistic than a fixed sequence
while preserving reproducibility through seed metadata. It also allows
exploratory batches to discover interaction effects before promoting a clean
example into the project narrative.

The project must avoid dishonest cherry-picking. Promoted seeds are acceptable
when their discovery context is documented and the before/after comparison uses
the same profile, seed, resource envelope, data set, and runtime settings.

Resource envelopes describe runtime capacity limits, not different hardware
classes. Docker can constrain CPU and memory allocation, process settings,
Puma worker/thread counts, database pool sizes, and PostgreSQL settings. It does
not faithfully emulate slower RAM, a different CPU architecture, or a production
provider.

Local archive outputs are ignored by Git. Git stores the narrative index and
small evidence summaries; bulky raw results stay in a local archive mirror that
can later be uploaded to Google Drive.

## Verification

Initial verification for the workload lab foundation is documentation-based:

- the ADR captures the workload evidence strategy
- workload lab documentation explains the directory creation rule
- archive documentation explains what belongs in the ignored local mirror
- Git ignore rules prevent raw workload archives from being committed

Future implementation should add verification for generated workload artifacts,
including repeatable profile execution, seed reproducibility, metadata capture,
result packaging, and summary generation.

## AI Involvement

The user identified the need to prioritize evidence over live demo behavior,
separate workload texture from load scaling, use bounded randomization with
deterministic seed tracking, and avoid repository bloat. Codex recommended k6
with business-workflow scenario design, promoted seeds for reproducible
architectural examples, and a Git-tracked narrative layer backed by ignored
local raw archives.

More detail about the discussion is captured in the
[Workload Lab Strategy](../decision-notes/2026-07-16-workload-lab-strategy.md)
decision note.
