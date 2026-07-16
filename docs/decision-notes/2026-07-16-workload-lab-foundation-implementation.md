# 2026-07-16: Workload Lab Foundation Implementation

## Related Issue

- [Issue 38: Build workload lab foundation and baseline smoke profile](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/38)

## Context

After the production-like runtime was hardened, the next step initially looked
like implementing the first Scenario 00 workload. During the design discussion,
that framing proved too broad. A real evidence-producing scenario should depend
on a trustworthy workload lab foundation rather than being built as a one-off
script.

The workload lab also needs to support architectural decisions later, so it
should be treated as a small application with its own quality gates instead of
as incidental scripting.

## Decision

Issue 38 will build the workload lab foundation and include only a tiny
baseline smoke profile. The full Scenario 00 normal-operations pressure run is
deferred until the lab can generate deterministic traffic, validate profiles,
execute k6 smoke runs, and capture metadata consistently.

The workload lab foundation includes:

- a generic deterministic traffic generator
- profile validation
- deterministic event-plan tests
- workflow request/path helpers
- a baseline smoke profile
- a k6 runner
- fast workload-specific CI checks
- a Docker-backed workload smoke command
- ignored archive output for generated run summaries

UUID-formatted strings are the preferred seed convention, but the generator
accepts any non-empty string up to 128 characters. This keeps promoted evidence
seeds easy to identify while preserving flexibility for human-readable
exploratory seeds.

## Rationale

The main project story depends on evidence credibility. If a seed is promoted
as evidence later, the team needs confidence that the same profile, seed, data
set, resource envelope, and application revision reproduce the same traffic
choices.

Testing the generator directly is cheaper and stronger than relying on logic
alone. It protects against accidental nondeterminism such as uncontrolled
randomness, wall-clock-dependent choices, or profile changes that silently move
traffic outside intended bounds.

Keeping the first profile small also separates two concerns:

- proving the workload lab can run
- using the workload lab to discover a scaling pressure point

Those are related, but they are not the same deliverable.

## Implementation Notes

The first profile is read-heavy and dispatcher-oriented. It covers login,
dashboard access, service request index/search/sort behavior, service request
detail discovery, and site index access. It intentionally avoids write
workflows, file uploads, quote approvals, and long-running pressure.

The workload lab uses the existing `workload-lab` directory convention and keeps
raw/generated summaries under `workload-lab/archive/`, which is ignored by Git
except for its README.

## AI Involvement

Codex initially framed the next step as implementing the first scenario. The
user clarified that the project was really building the workload lab
application first. Codex helped translate that into a narrower issue scope:
generic generator, profile contracts, determinism tests, k6 smoke execution,
metadata capture, and a small proof profile instead of a full evidence run.
