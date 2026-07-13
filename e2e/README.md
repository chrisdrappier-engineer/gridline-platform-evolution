# Headed Browser Smoke Tests

These Playwright tests drive a real browser against the locally running
Gridline app.

They are intended for visual workflow verification while the UI is changing
quickly. They do not replace the Rails model, controller, and service tests.

## Prerequisites

Start the app with demo data:

```bash
docker compose build app
docker compose up -d db
docker compose run --rm -e SEED_DEMO_DATA=true app bin/rails db:drop db:create db:migrate db:seed
docker compose up app
```

In another terminal, install Playwright dependencies once:

```bash
npm install
npx playwright install chromium
```

Playwright requires a modern Node runtime. Use Node 18 or newer.

## Run Headed

```bash
npm run test:e2e:headed
```

The browser opens visibly and walks through the workflows.

To slow browser operations down when you want to watch the flow:

```bash
E2E_SLOW_MO=750 npm run test:e2e:headed
```

To point at a different app port:

```bash
E2E_BASE_URL=http://localhost:3001 npm run test:e2e:headed
```
