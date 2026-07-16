# Workload Lab

The workload lab will measure how the Gridline monolith behaves under
production-like operational pressure.

This directory is intentionally small at the start. Workload lab directories are
created only when they contain real profiles, scenarios, promoted seeds,
scripts, evidence summaries, or archive documentation. Do not add stub folders
or placeholder files for planned work.

## Evidence Model

The workload lab is designed for recorded evidence first. Live demonstrations
may be derived from the same tooling later, but phase-one workload design
prioritizes reproducibility, metadata capture, and interpretation.

Workload profiles are defined by:

- texture: role mix, workflow mix, and action categories
- volume: virtual users, data size, active records, and work items
- frequency: wait times, refresh intervals, bursts, and lulls

Profiles may use bounded randomness. A promoted seed records a deterministic
path through a profile's boundaries over time so a meaningful pressure point can
be reproduced before and after an optimization.

## Repository Boundary

Git should contain:

- workload strategy documentation
- profile definitions when implemented
- promoted seed definitions when they support decisions
- small evidence summaries
- scripts required to reproduce or package runs

Git should not contain:

- raw k6 event streams
- large time-series output
- exploratory batch artifacts
- compressed archive bundles
- database dumps
- screenshots or videos of runs

Raw and bulky outputs belong under `workload_lab/archive/`, which is ignored by
Git except for its README.
