# Gridline Rails App

This directory contains the Rails monolith used by the Gridline Platform
Evolution case study.

The app is intended to run through the repository-level Docker Compose setup
rather than directly on the host. See the top-level `README.md` for the primary
runtime and CI commands.

## Current Baseline

The app currently includes:

- customers and customer sites
- service providers
- service requests
- users, roles, permissions, and scoped role assignments
- role-specific dashboards
- admin maintenance screens
- dispatcher-owned service request mutation workflows
- scoped read-only lifecycle visibility for customer and provider users
- shared backend-driven table interactions
- Minitest coverage

## Seeds

RBAC definitions are always seeded. The app uses development seed data by
default:

```bash
bin/rails db:prepare db:seed
```

Set `SEED_DEMO_DATA=true` to load larger presentation-friendly demo data:

```bash
SEED_DEMO_DATA=true bin/rails db:prepare db:seed
```

Seeded users share the stub password `gridline`.

## Tests

From inside the app container:

```bash
bin/rails test
```

From the repository root, prefer:

```bash
bin/ci
```
