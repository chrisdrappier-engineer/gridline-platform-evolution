# Development Runtime

The current runnable foundation is a Docker Compose simulation of the baseline
PaaS boundary for the initial Rails monolith.

## Container Baseline

The baseline includes:

- an `app` container that runs the Rails monolith with Puma
- a `db` container running Postgres as the managed database stand-in
- a bind mount from `./monolith` into the app container so local Rails file
  changes are visible without rebuilding the image
- environment-variable configuration
- app-to-database communication over the Compose network
- stdout logging from the app container
- Rails database preparation, test, and health smoke-check scripts
- a named Postgres volume for durable database state
- a named app storage volume for local Active Storage uploads

## Verification

Run the baseline checks with:

```bash
bin/ci
```

This lints CSS assets with Stylelint, runs workload-lab fast checks, builds the
app image, prepares the development and test databases, runs RuboCop, runs ERB
lint, runs the Rails test suite, enforces the dumb ERB template boundary, starts
the app service, and verifies the container health check.

## Running The App

Start the services directly:

```bash
docker compose up --build
```

After the image has been built once, most Rails source changes do not require a
rebuild:

```bash
docker compose up app
```

Changes under `monolith/` are mounted into the running container. Restart the
app container for changes that Rails does not reload automatically, and rebuild
only when image-level inputs change, such as `monolith/Gemfile`,
`monolith/Gemfile.lock`, or `monolith/Dockerfile`.

The health endpoint is:

```text
http://localhost:3000/health
```

## Demo Data

Prepare the development database with presentation-friendly demo data:

```bash
docker compose run --rm -e SEED_DEMO_DATA=true app bin/rails db:prepare db:seed
```

Then start the app and visit:

```text
http://localhost:3000/login
```

The default stub password for seeded users is `gridline`.

## Browser Workflow Tests

Run headed browser smoke tests with:

```bash
npm run test:e2e:headed
```

Run the full browser workflow suite with:

```bash
npm run test:e2e
```

The E2E suite runs with one worker because the browser workflows intentionally
mutate shared demo data while exercising realistic user paths.

Additional browser test details live in [`e2e/README.md`](../../e2e/README.md).
