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
- workflow route mapping in `config/workflow-paths.json`
- Ajv-backed profile shape validation with JSON Schema in
  `schemas/profile.schema.json`
- workload-specific profile reference validation in `lib/profile.mjs`
- reusable request/path helpers in `lib/requests.mjs`
- a tiny read-heavy smoke profile in `profiles/baseline-smoke.json`
- a first normal-operations profile in
  `profiles/scenario-00-normal-operations.json`
- a k6 entrypoint in `scenarios/run-profile.mjs`
- a duration-based series runner in `scripts/run-series.mjs`
- fast lint, profile-validation, and determinism tests

The baseline smoke profile is intentionally small. It proves that the workload
lab can generate deterministic business-shaped traffic and execute it through
k6. It is not a Scenario 00 scaling evidence run.

The Scenario 00 normal-operations profile is the first business-texture profile
for evidence work. It mixes dispatcher, facility manager, customer contact,
service provider, and admin read traffic against the mature monolith baseline.
It is still a baseline profile, not an optimization claim or a bottleneck
finding.

Scenario 00 also defines the first named workload series,
`local-small-ramp`. The series applies the same normal-operations texture across
ordered duration-based steps against the `local-small` resource envelope.

## Fast Checks

Run the workload lab's fast checks with:

```bash
bin/workload-ci
```

This command runs:

- ESLint for workload-lab JavaScript
- a project-specific ESLint rule banning uncontrolled `Math.random()` calls
- Node tests for deterministic event generation, fixture profile validation,
  seed validation, and request-path construction

The normal repository CI also runs these fast workload checks through `bin/ci`.

Profile files are workload inputs, so the fast CI path does not validate every
tracked profile. Validate a selected profile when it is created, changed, or
used:

```bash
bin/workload-validate-profile workload-lab/profiles/baseline-smoke.json
```

Workflow HTTP paths are configured in `config/workflow-paths.json`. Add new
workflow types there before referencing them from a profile.

Profile validation has two layers. `schemas/profile.schema.json` validates JSON
structure, required fields, cadence shapes, duration strings, and numeric
bounds through Ajv. `lib/profile.mjs` keeps the project-specific checks that
depend on other profile content, such as workflow references, actor-role
references, and registered workflow path types.

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

The smoke command validates the selected profile before starting k6.

The smoke runner uses:

- `TARGET_BASE_URL`, defaulting to `http://host.docker.internal:3001` from the
  k6 container
- `PROFILE_PATH`, defaulting to `/workload-lab/profiles/baseline-smoke.json`
- `WORKLOAD_SEED`, defaulting to `018f3d5f-9f50-77b4-9f2a-4eec5b3f7d1a`
- `RESOURCE_ENVELOPE`, defaulting to `local-small`

Generated summaries are written under `workload-lab/archive/`, which is
ignored by Git except for the archive README. Summary filenames use the pattern
`<scenario-id>-<profile-id>-<timestamp>.summary.json` and
`<scenario-id>-<profile-id>-<timestamp>.summary.md` so runs do not overwrite
previous results.

Each summary records the effective run settings, including VUs, iterations,
thresholds, profile path, time buckets, workflow mix, actor roles, target URL,
application commit, resource envelope, seed data profile, and workload seed.

## Scenario 00 Normal Operations

Run the first normal-operations workload profile with:

```bash
bin/workload-scenario-00
```

This command uses:

- `PROFILE_PATH`, defaulting to
  `/workload-lab/profiles/scenario-00-normal-operations.json`
- `WORKLOAD_SEED`, defaulting to
  `01981f6d-89a0-7b2c-9c45-5d8df49f5e40`
- the same production-like target and `local-small` resource envelope defaults
  as the smoke runner

Validate the profile without running k6:

```bash
bin/workload-validate-profile workload-lab/profiles/scenario-00-normal-operations.json
```

Scenario 00 intentionally starts with normal operational texture instead of an
endpoint hammer. Later profiles can reuse the same shape and increase
frequency, virtual users, duration, or targeted workflow weights to discover
where the vertically constrained monolith first degrades.

### Larger Mixed Read/Write Profile

`profiles/scenario-00-mixed-operations-large.json` expands Scenario 00 to a
four-step, 12-to-160 VU ramp and adds role-valid service-request note writes.
Writes are cumulative: each step adds notes to the demo database, so later
request-detail reads operate against a larger data footprint. Run it against a
freshly seeded disposable production-like database with:

```bash
bin/workload-run-series workload-lab/profiles/scenario-00-mixed-operations-large.json local-small-large-ramp
```

This profile intentionally mutates the target database. Reseed the target
before reproducibility or before/after comparison runs.

### Full Application Endpoint Exercise

`profiles/scenario-00-full-endpoint-exercise.json` is the largest profile and
longest series. Its five two-minute steps ramp from 20 to 300 VUs while a
deterministic admin sequence exercises every application-owned route and HTTP
method alongside sustained multi-role reads and writes. Rails framework
transport routes are outside this profile's coverage boundary.

Run it only against a freshly seeded disposable target:

```bash
bin/workload-run-series workload-lab/profiles/scenario-00-full-endpoint-exercise.json local-small-full-endpoint-ramp
```

## Workload Series

Workload series are the primary evidence unit for scaling decisions. A profile
owns both its workload texture and its named series definitions. The texture
describes which roles and workflows are represented. A series describes how that
texture is applied across load steps.

Run every series defined in a profile:

```bash
bin/workload-run-series workload-lab/profiles/scenario-00-normal-operations.json
```

Run one named series:

```bash
bin/workload-run-series workload-lab/profiles/scenario-00-normal-operations.json local-small-ramp
```

If no series name is provided, the runner executes every series in profile
order. If a series name is provided, only that series runs. Profiles without a
`series` section fail clearly when used with `bin/workload-run-series`.

Each series step runs through k6 as a duration-based `constant-vus` execution.
Virtual users behave as sequential users: they sign in, execute a workflow,
wait for the response, apply cadence-derived think time, and continue until the
step duration ends. Steps run sequentially against the same target runtime and
data state.

The first cadence modes are:

- `static`
- `bounded-random` with `uniform`
- `bounded-random` with `normal`

Generated series summaries are written under `workload-lab/archive/`, which is
ignored by Git except for the archive README. Each series writes:

- per-step `.step-summary.json` files generated by k6
- one collated `.series-summary.json` file
- one collated `.series-summary.md` file for quick human review

Series summaries include profile hash, texture hash, series hash, seed, target
URL, application commit, workload tooling commit, resource envelope, step
settings, metrics, observed workflow composition, and request-level coverage.
Each step's `coverage` object records workflow stage, HTTP method, path template,
request count, failure count, and any stateful workflow-sequence definitions
declared by the profile.

## Local Evidence Dashboard

Start the static, read-only series viewer with:

```bash
bin/workload-dashboard
```

Open `http://127.0.0.1:4173`. The server discovers analyzable
`.series-summary.json` files in `workload-lab/archive`, and the dashboard updates
when files change. Use the refresh button if live updates disconnect. Archive
access is local and read-only; the dashboard does not modify or generate
evidence.

## Seed Convention

Workload seeds are strings. UUIDs are the preferred convention because they are
easy to generate, copy, and distinguish in evidence metadata. The workload lab
does not require UUID format, so human-readable seeds can still be used for
exploratory work.

Seeds must be non-empty and no more than 128 characters.

Generate a UUID seed with:

```bash
bin/workload-seed
```

Run the smoke profile with a generated seed:

```bash
WORKLOAD_SEED="$(bin/workload-seed)" bin/workload-smoke
```

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
