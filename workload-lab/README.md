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

## Current Foundation

The current workload lab contains the first framework pieces:

- a generic deterministic traffic generator in `lib/`
- profile validation in `lib/profile.mjs`
- reusable request/path helpers in `workflows/`
- a tiny read-heavy smoke profile in `profiles/baseline-smoke.json`
- a k6 entrypoint in `scenarios/run-profile.mjs`
- fast lint, profile-validation, and determinism tests

The baseline smoke profile is intentionally small. It proves that the workload
lab can generate deterministic business-shaped traffic and execute it through
k6. It is not a Scenario 00 scaling evidence run.

## Fast Checks

Run the workload lab's fast checks with:

```bash
bin/workload-ci
```

This command runs:

- JavaScript syntax and randomness linting
- profile validation
- Node tests for deterministic event generation and request-path construction

The normal repository CI also runs these fast workload checks through `bin/ci`.

## Docker Smoke

The Docker-backed smoke run expects the production-like app to be running on
`http://localhost:3001`.

Start the production-like runtime with demo data:

```bash
docker compose -f compose.production.yml build
docker compose -f compose.production.yml up -d db
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:prepare
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:seed
docker compose -f compose.production.yml up -d app
```

Then run the workload smoke profile:

```bash
bin/workload-smoke
```

The smoke runner uses:

- `TARGET_BASE_URL`, defaulting to `http://host.docker.internal:3001` from the
  k6 container
- `PROFILE_PATH`, defaulting to `/workload-lab/profiles/baseline-smoke.json`
- `WORKLOAD_SEED`, defaulting to `2026071601`
- `RESOURCE_ENVELOPE`, defaulting to `local-small`

Generated smoke summaries are written under `workload-lab/archive/`, which is
ignored by Git except for the archive README.

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

Raw and bulky outputs belong under `workload-lab/archive/`, which is ignored by
Git except for its README.
