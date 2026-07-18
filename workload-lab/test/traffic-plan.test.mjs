import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import { summaryFileNames } from "../lib/archive-names.mjs";
import { cadenceSleepSeconds } from "../lib/cadence.mjs";
import { profileRunContext } from "../lib/profile-summary.mjs";
import { pathForEvent, serviceRequestNotesPath, withQuery } from "../lib/requests.mjs";
import { selectSeries, stableJsonHash, workflowCompositionFromStep } from "../lib/series.mjs";
import { eventFor, generatePlan, MAX_SEED_LENGTH } from "../lib/traffic-plan.mjs";
import { validateProfile } from "../lib/profile.mjs";

const profile = JSON.parse(
  await readFile(new URL("fixtures/valid-profile.json", import.meta.url), "utf8")
);
const scenario00Profile = JSON.parse(
  await readFile(new URL("../profiles/scenario-00-normal-operations.json", import.meta.url), "utf8")
);
const mixedOperationsLargeProfile = JSON.parse(
  await readFile(new URL("../profiles/scenario-00-mixed-operations-large.json", import.meta.url), "utf8")
);
const fullEndpointProfile = JSON.parse(
  await readFile(new URL("../profiles/scenario-00-full-endpoint-exercise.json", import.meta.url), "utf8")
);
const workflowPaths = JSON.parse(
  await readFile(new URL("../config/workflow-paths.json", import.meta.url), "utf8")
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

test("events include the actor selected for the workflow role", () => {
  const events = generatePlan(scenario00Profile, { seed: seedA, vus: 2, iterations: 30 });
  const providerEvent = events.find((event) => event.actorRole === "serviceProviderUser");

  assert.ok(providerEvent, "expected at least one service provider event");
  assert.equal(providerEvent.actor.email, "provider.user@coastalcoldchain.test");
});

test("scenario 00 normal operations profile is valid and deterministic", () => {
  assert.deepEqual(validateProfile(scenario00Profile, { workflowPaths }), []);

  const first = generatePlan(scenario00Profile, { seed: seedA, vus: 3, iterations: 40 });
  const second = generatePlan(scenario00Profile, { seed: seedA, vus: 3, iterations: 40 });

  assert.deepEqual(second, first);
  assert.ok(first.some((event) => event.actorRole === "dispatcher"));
  assert.ok(first.some((event) => event.actorRole === "facilityManager"));
  assert.ok(first.some((event) => event.actorRole === "customerContact"));
  assert.ok(first.some((event) => event.actorRole === "serviceProviderUser"));
  assert.ok(first.some((event) => event.actorRole === "admin"));
});

test("large mixed-operations profile is valid and includes deterministic writes", () => {
  assert.deepEqual(validateProfile(mixedOperationsLargeProfile, { workflowPaths }), []);
  const events = generatePlan(mixedOperationsLargeProfile, { seed: seedA, vus: 4, iterations: 400 });
  const writes = events.filter((event) => event.type === "service-request-note-create");

  assert.ok(writes.length > 0);
  assert.deepEqual(events, generatePlan(mixedOperationsLargeProfile, { seed: seedA, vus: 4, iterations: 400 }));
  assert.deepEqual(new Set(writes.map((event) => event.actorRole)), new Set(["dispatcher", "facilityManager", "customerContact", "serviceProviderUser"]));
});

test("full endpoint profile is valid and is the largest series", () => {
  assert.deepEqual(validateProfile(fullEndpointProfile, { workflowPaths }), []);
  const series = fullEndpointProfile.series[0];

  assert.equal(series.steps.length, 5);
  assert.equal(series.steps.reduce((total, step) => total + Number.parseFloat(step.duration), 0), 10);
  assert.equal(Math.max(...series.steps.map((step) => step.vus)), 300);
  assert.equal(fullEndpointProfile.workflows.fullEndpointSequence.type, "full-endpoint-exercise");
});

test("profile validation accepts named duration-based series definitions", () => {
  assert.deepEqual(validateProfile(profile, { workflowPaths }), []);

  assert.deepEqual(
    profile.series.map((definition) => definition.name),
    ["fixture-ramp"]
  );
});

test("profile validation rejects invalid series cadence definitions", () => {
  const invalidProfile = JSON.parse(JSON.stringify(profile));
  invalidProfile.series[0].steps[0].cadence = {
    mode: "bounded-random",
    distribution: "normal",
    min: 0,
    max: 1,
    mean: 0.5,
    standardDeviation: 0
  };

  assert.deepEqual(
    validateProfile(invalidProfile, { workflowPaths }),
    ["series[0].steps[0].cadence.standardDeviation must be a positive number."]
  );
});

test("series selection runs all series when no series name is provided", () => {
  assert.deepEqual(selectSeries(profile).map((definition) => definition.name), ["fixture-ramp"]);
  assert.deepEqual(selectSeries(profile, "fixture-ramp").map((definition) => definition.name), ["fixture-ramp"]);
  assert.throws(
    () => selectSeries(profile, "missing-series"),
    /Unknown workload series: missing-series. Available series: fixture-ramp/
  );
});

test("duration-based series events cycle time buckets deterministically", () => {
  const event = eventFor(profile, { seed: seedA, vu: 1, iteration: 4, cycleTimeBuckets: true });

  assert.equal(event.timeBucket, "fixture");
});

test("cadence calculations are deterministic and bounded", () => {
  const uniformCadence = {
    mode: "bounded-random",
    distribution: "uniform",
    min: 0.25,
    max: 1.5
  };
  const normalCadence = {
    mode: "bounded-random",
    distribution: "normal",
    min: 0.1,
    max: 0.9,
    mean: 0.5,
    standardDeviation: 0.2
  };
  const args = { seed: seedA, seriesName: "fixture-ramp", stepName: "light", vu: 1, iteration: 2 };

  assert.equal(cadenceSleepSeconds({ mode: "static", seconds: 0.3 }, args), 0.3);
  assert.equal(cadenceSleepSeconds(uniformCadence, args), cadenceSleepSeconds(uniformCadence, args));
  assert.equal(cadenceSleepSeconds(normalCadence, args), cadenceSleepSeconds(normalCadence, args));
  assert.ok(cadenceSleepSeconds(uniformCadence, args) >= 0.25);
  assert.ok(cadenceSleepSeconds(uniformCadence, args) <= 1.5);
  assert.ok(cadenceSleepSeconds(normalCadence, args) >= 0.1);
  assert.ok(cadenceSleepSeconds(normalCadence, args) <= 0.9);
});

test("series helpers produce stable hashes and workflow composition", () => {
  assert.equal(stableJsonHash({ b: 2, a: 1 }), stableJsonHash({ a: 1, b: 2 }));

  assert.deepEqual(
    workflowCompositionFromStep({
      metadata: {
        workflows: {
          dashboard: { type: "dashboard", actorRole: "dispatcher" },
          siteIndex: { type: "site-index", actorRole: "dispatcher" }
        }
      },
      metrics: {
        workflows: {
          dashboard: { count: 3 },
          siteIndex: { count: 1 }
        }
      }
    }),
    {
      dashboard: {
        type: "dashboard",
        actorRole: "dispatcher",
        observedEvents: 3,
        observedShare: 0.75
      },
      siteIndex: {
        type: "site-index",
        actorRole: "dispatcher",
        observedEvents: 1,
        observedShare: 0.25
      }
    }
  );
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
    pathForEvent(event, workflowPaths),
    "/customer_sites?search=Palmetto&sort=site&direction=asc&limit=20&site_status=active"
  );
});

test("service request note paths are derived from discovered request details", () => {
  assert.equal(
    serviceRequestNotesPath("/service_requests/018f3d5f-9f50-77b4-9f2a-4eec5b3f7d1a"),
    "/service_requests/018f3d5f-9f50-77b4-9f2a-4eec5b3f7d1a/service_request_notes"
  );
  assert.throws(() => serviceRequestNotesPath("/service_requests/not-a-uuid"), /Invalid service request detail path/);
});

test("scenario workflow paths support role-specific resource indexes", () => {
  assert.equal(
    pathForEvent(
      {
        type: "service-request-index",
        params: {
          "service_requests[search]": "HVAC",
          "service_requests[sort]": "priority",
          "service_requests[direction]": "desc",
          "service_requests[limit]": 10
        }
      },
      workflowPaths
    ),
    "/service_requests?service_requests%5Bsearch%5D=HVAC&service_requests%5Bsort%5D=priority&service_requests%5Bdirection%5D=desc&service_requests%5Blimit%5D=10"
  );
  assert.equal(pathForEvent({ type: "customer-index", params: {} }, workflowPaths), "/customers");
  assert.equal(pathForEvent({ type: "customer-site-index", params: {} }, workflowPaths), "/customer_sites");
  assert.equal(pathForEvent({ type: "service-provider-index", params: {} }, workflowPaths), "/service_providers");
  assert.equal(pathForEvent({ type: "admin-users", params: {} }, workflowPaths), "/admin/users");
  assert.equal(pathForEvent({ type: "admin-role-assignments", params: {} }, workflowPaths), "/admin/role-assignments");
  assert.equal(pathForEvent({ type: "admin-permission-matrix", params: {} }, workflowPaths), "/admin/permission-matrix");
});

test("profile validation rejects workflow types missing from the path config", () => {
  const invalidProfile = JSON.parse(JSON.stringify(profile));
  invalidProfile.workflows.dashboard.type = "unknown-index";

  assert.deepEqual(
    validateProfile(invalidProfile, { workflowPaths }),
    ["workflows.dashboard.type is not registered: unknown-index"]
  );
});

test("summary filenames include scenario profile and timestamp", () => {
  assert.deepEqual(
    summaryFileNames({
      scenarioId: "00-vertical-scaling-limit",
      profileId: "normal-operations-local-small",
      generatedAt: "2026-07-16T09:09:40.591Z"
    }),
    {
      json: "archive/00-vertical-scaling-limit-normal-operations-local-small-2026-07-16t09-09-40-591z.summary.json",
      markdown: "archive/00-vertical-scaling-limit-normal-operations-local-small-2026-07-16t09-09-40-591z.summary.md"
    }
  );
});

test("profile run context records thresholds and workload shape", () => {
  assert.deepEqual(
    profileRunContext(profile, {
      profilePath: "/workload-lab/profiles/baseline-smoke.json",
      thresholds: profile.k6.thresholds
    }),
    {
      profilePath: "/workload-lab/profiles/baseline-smoke.json",
      thresholds: {
        "http_req_failed": ["rate<0.01"]
      },
      timeBuckets: [
        {
          name: "fixture",
          iterations: 4,
          workflowMix: {
            dashboard: 1,
            serviceRequestIndex: 2,
            siteIndex: 1
          }
        }
      ],
      workflows: {
        dashboard: {
          type: "dashboard",
          actorRole: "dispatcher"
        },
        serviceRequestIndex: {
          type: "service-request-index",
          actorRole: "dispatcher"
        },
        siteIndex: {
          type: "site-index",
          actorRole: "dispatcher"
        }
      }
    }
  );
});
