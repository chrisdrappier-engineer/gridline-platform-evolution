# Quick Start

This guide gives a reviewer the shortest useful path through the project:
verify the repository, start the production-like target, run the first workload
profile, and inspect the generated results.

For detailed runtime behavior, see [Development Runtime](development.md) and
[Production-Like Runtime](production-like.md).

## 1. Verify The Repository

Run the full development verification suite:

```bash
bin/ci
```

This checks workload-lab JavaScript, builds the development app image, prepares
databases, runs Rails linting, runs Rails tests, enforces the dumb ERB boundary,
starts the app service, and verifies the health check.

## 2. Start The Production-Like Target

The workload lab should run against the production-like runtime, not the
development bind-mounted app.

Provision a fresh local production-like environment with demo data:

```bash
docker compose -f compose.production.yml build
docker compose -f compose.production.yml up -d db
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:prepare
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:seed
docker compose -f compose.production.yml up -d app
TARGET_BASE_URL=http://localhost:3001 bin/production-smoke
```

The production-like app is available at:

```text
http://localhost:3001
```

## 3. Run The First Workload Series

Run Scenario 00 normal operations as a duration-based workload series:

```bash
bin/workload-run-series workload-lab/profiles/scenario-00-normal-operations.json local-small-ramp
```

This sends deterministic, business-shaped traffic to the production-like app.
The profile uses dispatcher, facility manager, customer contact, service
provider, and admin read workflows against the mature monolith baseline.

To run every series defined in the profile, omit the series name:

```bash
bin/workload-run-series workload-lab/profiles/scenario-00-normal-operations.json
```

## 4. Read The Results

Workload summaries are written under:

```text
workload-lab/archive/
```

Each run produces:

- a `.summary.md` file for human review
- a `.summary.json` file for machine-readable data

Summary filenames include the scenario, profile, resource envelope, and
timestamp so runs do not overwrite one another.

Start with the markdown summary. It is the fastest way to inspect:

- effective run settings
- target URL
- application commit
- resource envelope
- seed data profile
- workload seed
- virtual users and iterations
- workload shape
- check rates and request metrics

Use the JSON summary when a later tool or dashboard needs structured data.

## 5. Interpret The First Run

The first Scenario 00 series proves that the workload lab can send realistic
duration-based traffic through the production-like runtime and record repeatable
series artifacts.

It does not yet prove a bottleneck, scaling limit, or optimization need. Those
claims require comparing behavior across load steps, resource envelopes, seeds,
and application versions.

The workload series model is documented in
[ADR 0010](../adr/0010-use-duration-based-workload-series-as-performance-evidence.md).

## 6. Optional Development App

Start the development app when you want to browse or modify the Rails
application with bind-mounted source files:

```bash
docker compose up --build
```

Prepare the development database with demo data:

```bash
docker compose run --rm -e SEED_DEMO_DATA=true app bin/rails db:prepare db:seed
```

Then visit:

```text
http://localhost:3000/login
```

The default stub password for seeded users is:

```text
gridline
```
