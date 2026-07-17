# Production-Like Runtime

The production-like local runtime is the target for workload-lab evidence and
deployment hardening. It is separate from the development Compose setup.

## Runtime Shape

The production-like runtime:

- builds the Rails app with the production Docker target
- runs Rails with `RAILS_ENV=production`
- does not bind-mount the Rails source tree into the app container
- precompiles assets during the image build
- serves static assets through the production app container
- applies the default `local-small` resource envelope
- allows `host.docker.internal` so Dockerized workload tools can reach the
  host-published production app
- uses named volumes for Postgres and local Active Storage files
- disables forced SSL by default for local HTTP access
- uses an explicit health check and smoke test path

## Resource Envelope

The default `local-small` resource envelope constrains the production-like
runtime so workload evidence is not based on unconstrained Docker Desktop
capacity:

| Service | CPU Limit | Memory Limit | Related Runtime Settings |
|---|---:|---:|---|
| Rails app | `1.0` CPU | `768m` | `WEB_CONCURRENCY=1`, `RAILS_MAX_THREADS=5` |
| Postgres | `1.0` CPU | `768m` | default Postgres settings |

These limits are diagnostic constraints for local evidence, not a claim that
the laptop faithfully emulates a production provider. Future workload runs
should record the resource envelope alongside the scenario, profile, seed,
target URL, data set, and application revision.

Override the envelope for experiments:

```bash
RESOURCE_ENVELOPE=local-app-constrained \
PRODUCTION_APP_CPUS=0.5 \
PRODUCTION_APP_MEMORY=512m \
docker compose -f compose.production.yml up --build
```

## Production Validation

Run the production runtime validation with:

```bash
bin/ci:production
```

This command uses a separate Compose project named `gridline-production-ci`,
builds the production image, starts Postgres, prepares and seeds a fresh local
production database with demo data, starts the app, and runs
`bin/production-smoke` against `http://localhost:3001`.

The production smoke script can also check an already-running target:

```bash
TARGET_BASE_URL=http://localhost:3001 bin/production-smoke
```

## Database Operation Modes

Production-like database operations are separated into three modes:

- **Provision**: first boot of a fresh local production-like environment; create
  or connect to an empty database, migrate, seed required data, optionally seed
  demo/workload data, and smoke-check the app.
- **Deploy**: non-destructive update of an existing production-like database;
  run migrations and idempotent required seeds only.
- **Evidence Reset**: explicit local/workload-lab reset used to recreate known
  data for repeatable workload evidence. This is not normal production deploy
  behavior.

Normal production deploy commands must be non-destructive. Any destructive
reset command should be separately named and documented as local or
workload-lab-only.

## Manual Provision

Provision a fresh local production-like environment:

```bash
docker compose -f compose.production.yml build
docker compose -f compose.production.yml up -d db
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:prepare
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:seed
docker compose -f compose.production.yml up -d app
TARGET_BASE_URL=http://localhost:3001 bin/production-smoke
```

## Manual Deploy

Deploy against an existing local production-like database:

```bash
docker compose -f compose.production.yml build
docker compose -f compose.production.yml up -d db
docker compose -f compose.production.yml run --rm app bin/rails db:migrate
docker compose -f compose.production.yml run --rm -e SEED_BASELINE_ONLY=true app bin/rails db:seed
docker compose -f compose.production.yml up -d app
TARGET_BASE_URL=http://localhost:3001 bin/production-smoke
```

## Evidence Reset

Reset local workload-lab evidence state explicitly:

```bash
docker compose -f compose.production.yml down --volumes --remove-orphans
docker compose -f compose.production.yml up -d db
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:prepare
docker compose -f compose.production.yml run --rm -e SEED_DEMO_DATA=true app bin/rails db:seed
docker compose -f compose.production.yml up -d app
TARGET_BASE_URL=http://localhost:3001 bin/production-smoke
```

## Active Storage Boundary

For this phase, production-like Active Storage uses local disk through a named
Docker volume. That is acceptable for a single local production target, but it
is not suitable for horizontally scaled containers or ephemeral hosted
deployments.

A later SaaS or multi-instance deployment should move uploads to durable object
storage.
