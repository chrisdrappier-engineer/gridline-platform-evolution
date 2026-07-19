import assert from "node:assert/strict";
import test from "node:test";

import { comparisonAgainst, durationSeconds, eventsPerSecond, groupedComposition, parseSeriesSummary, provenancePresentation } from "../lib/dashboard-summary.mjs";

const summary = { schemaVersion: 1, metadata: { scenarioId: "00", profileId: "normal", seriesName: "ramp", generatedAt: "2026-07-18T00:00:00Z", resourceEnvelope: "local-small" }, steps: [{ name: "light", vus: 4, duration: "30s", metrics: { workloadEvents: 150 }, composition: { queue: { actorRole: "dispatcher", type: "index", observedEvents: 150 } } }] };

test("parses a supported series summary", () => assert.equal(parseSeriesSummary(JSON.stringify(summary)).schemaVersion, 1));
test("rejects unsupported schema versions", () => assert.throws(() => parseSeriesSummary(JSON.stringify({ ...summary, schemaVersion: 3 })), /unsupported schema version 3/));
test("supports existing unversioned summaries", () => assert.equal(parseSeriesSummary(JSON.stringify({ metadata: summary.metadata, steps: summary.steps })).schemaVersion, undefined));
test("derives duration and throughput", () => { assert.equal(durationSeconds("1.5m"), 90); assert.equal(eventsPerSecond(summary.steps[0]), 5); });
test("groups composition by role", () => assert.deepEqual(groupedComposition(summary.steps[0]), [{ role: "dispatcher", events: 150, workflows: [{ name: "queue", type: "index", events: 150 }] }]));
test("reports comparison differences", () => {
  const selected = { id: "one", summary: { metadata: { ...summary.metadata, profileHash: "a" } } };
  const other = { id: "two", summary: { metadata: { ...summary.metadata, profileHash: "b" } } };
  assert.match(comparisonAgainst(selected, [selected, other])[0].differences.join(","), /profile hash differs/);
});
test("presents legacy provenance without unsupported fields", () => {
  const presentation = provenancePresentation(summary, "legacy.json");
  assert.match(presentation.legacyNotice, /Legacy summary/);
  assert.equal(presentation.fingerprints.length, 0);
  assert.deepEqual(presentation.revisions.map((revision) => revision.label), []);
});
test("presents human context before exact fingerprints", () => {
  const versioned = { ...summary, schemaVersion: 2, metadata: { ...summary.metadata, profileDescription: "Everyday traffic", seriesDescription: "Increasing load", seedDataProfile: "demo", executionModel: "duration-based-sequential-users", profileHash: "profile-hash", resourceEnvelopeSnapshot: { app: { cpus: "1", memory: "768m", webConcurrency: "1", maxThreads: "5" }, database: { cpus: "1", memory: "768m" } }, application: { commit: "1234567890abcdef", tag: "app-v1", branch: "main", dirty: false } } };
  const presentation = provenancePresentation(versioned, "run.json");
  assert.equal(presentation.legacyNotice, null);
  assert.match(presentation.definition.find((field) => field.label === "Resource envelope").description, /App 1 CPU/);
  assert.equal(presentation.revisions[0].value, "tag app-v1 · branch main · clean");
  assert.equal(presentation.revisions[0].shortCommit, "1234567890");
  assert.deepEqual(presentation.fingerprints, [{ label: "Profile hash", value: "profile-hash" }]);
});
