# Headed Browser Smoke Tests

These Playwright tests drive a real browser against the locally running
Gridline app.

They are intended for visual workflow verification while the UI is changing
quickly. They do not replace the Rails model, controller, and service tests.

## Definition Of Done

Tickets that change user-facing workflows should update this E2E suite as part
of their definition of done. If a ticket does not need browser coverage, the PR
or decision note should say why.

## Workflow Constraint

E2E tests should exercise features through visible user-facing controls rather
than direct internal URLs. Tests may start at `/login` as the public entry point,
but after authentication they should navigate through dashboards, the primary
navigation menu, links, buttons, forms, and table actions the same way a user
would.

Avoid direct `page.goto(...)` calls to authenticated feature routes unless the
test is explicitly covering routing or deep-link behavior.

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
