import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { generatePlan, MAX_SEED_LENGTH } from "../lib/traffic-plan.mjs";
import { validateProfile } from "../lib/profile.mjs";
import { pathForEvent, withQuery } from "../workflows/requests.mjs";

const profile = JSON.parse(
  await readFile(new URL("fixtures/valid-profile.json", import.meta.url), "utf8")
);
const seedA = "018f3d5f-9f50-77b4-9f2a-4eec5b3f7d1a";
const seedB = "018f3d5f-9f50-77b4-9f2a-4eec5b3f7d1b";

test("fixture profile is valid", () => {
  assert.deepEqual(validateProfile(profile), []);
});

test("same seed and profile produce the same event plan", () => {
  const first = generatePlan(profile, { seed: seedA, vus: 2, iterations: 12 });
  const second = generatePlan(profile, { seed: seedA, vus: 2, iterations: 12 });

  assert.deepEqual(second, first);
});

test("different seeds produce different event plans", () => {
  const first = generatePlan(profile, { seed: seedA, vus: 2, iterations: 12 });
  const second = generatePlan(profile, { seed: seedB, vus: 2, iterations: 12 });

  assert.notDeepEqual(second, first);
});

test("generated events remain inside profile workflow bounds", () => {
  const events = generatePlan(profile, { seed: seedA, vus: 3, iterations: 20 });

  for (const event of events) {
    const workflow = profile.workflows[event.workflow];
    assert.ok(workflow, `Unknown workflow generated: ${event.workflow}`);
    assert.equal(event.type, workflow.type);

    for (const [key, value] of Object.entries(event.params)) {
      assert.ok(workflow.bounds[key].includes(value), `${key}=${value} is outside workflow bounds`);
    }
  }
});

test("seeds may be any bounded non-empty string", () => {
  assert.doesNotThrow(() => generatePlan(profile, { seed: "human-readable-seed", vus: 1, iterations: 1 }));
  assert.throws(
    () => generatePlan(profile, { seed: "x".repeat(MAX_SEED_LENGTH + 1), vus: 1, iterations: 1 }),
    /128 characters or fewer/
  );
  assert.throws(
    () => generatePlan(profile, { seed: "", vus: 1, iterations: 1 }),
    /non-empty string/
  );
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
