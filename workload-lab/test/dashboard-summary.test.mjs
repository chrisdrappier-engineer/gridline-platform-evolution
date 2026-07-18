import assert from "node:assert/strict";
import test from "node:test";

import { durationSeconds, eventsPerSecond, groupedComposition, parseSeriesSummary } from "../lib/dashboard-summary.mjs";

const summary = { schemaVersion: 1, metadata: { scenarioId: "00", profileId: "normal", seriesName: "ramp", generatedAt: "2026-07-18T00:00:00Z", resourceEnvelope: "local-small" }, steps: [{ name: "light", vus: 4, duration: "30s", metrics: { workloadEvents: 150 }, composition: { queue: { actorRole: "dispatcher", type: "index", observedEvents: 150 } } }] };

test("parses a supported series summary", () => assert.equal(parseSeriesSummary(JSON.stringify(summary)).schemaVersion, 1));
test("rejects unsupported schema versions", () => assert.throws(() => parseSeriesSummary(JSON.stringify({ ...summary, schemaVersion: 2 })), /unsupported schema version 2/));
test("supports existing unversioned summaries", () => assert.equal(parseSeriesSummary(JSON.stringify({ metadata: summary.metadata, steps: summary.steps })).schemaVersion, undefined));
test("derives duration and throughput", () => { assert.equal(durationSeconds("1.5m"), 90); assert.equal(eventsPerSecond(summary.steps[0]), 5); });
test("groups composition by role", () => assert.deepEqual(groupedComposition(summary.steps[0]), [{ role: "dispatcher", events: 150, workflows: [{ name: "queue", type: "index", events: 150 }] }]));
