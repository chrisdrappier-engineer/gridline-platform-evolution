import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { generatePlan } from "../lib/traffic-plan.mjs";
import { validateProfile } from "../lib/profile.mjs";
import { pathForEvent, withQuery } from "../workflows/requests.mjs";

const profile = JSON.parse(
  await readFile(new URL("../profiles/baseline-smoke.json", import.meta.url), "utf8")
);

test("baseline smoke profile is valid", () => {
  assert.deepEqual(validateProfile(profile), []);
});

test("same seed and profile produce the same event plan", () => {
  const first = generatePlan(profile, { seed: "2026071601", vus: 2, iterations: 12 });
  const second = generatePlan(profile, { seed: "2026071601", vus: 2, iterations: 12 });

  assert.deepEqual(second, first);
});

test("different seeds produce different event plans", () => {
  const first = generatePlan(profile, { seed: "2026071601", vus: 2, iterations: 12 });
  const second = generatePlan(profile, { seed: "2026071602", vus: 2, iterations: 12 });

  assert.notDeepEqual(second, first);
});

test("generated events remain inside profile workflow bounds", () => {
  const events = generatePlan(profile, { seed: "2026071601", vus: 3, iterations: 20 });

  for (const event of events) {
    const workflow = profile.workflows[event.workflow];
    assert.ok(workflow, `Unknown workflow generated: ${event.workflow}`);
    assert.equal(event.type, workflow.type);

    for (const [key, value] of Object.entries(event.params)) {
      assert.ok(workflow.bounds[key].includes(value), `${key}=${value} is outside workflow bounds`);
    }
  }
});

test("workflow request paths use backend table query parameters", () => {
  assert.equal(withQuery("/dashboard", {}), "/dashboard");
  assert.equal(
    withQuery("/service_requests", { search: "HVAC", sort: "priority", direction: "desc", limit: 10 }),
    "/service_requests?search=HVAC&sort=priority&direction=desc&limit=10"
  );

  const event = {
    type: "site-index",
    params: { search: "Palmetto", sort: "site", direction: "asc", limit: 20, site_status: "active" }
  };

  assert.equal(
    pathForEvent(event),
    "/customer_sites?search=Palmetto&sort=site&direction=asc&limit=20&site_status=active"
  );
});
