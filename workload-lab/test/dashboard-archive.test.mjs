import assert from "node:assert/strict";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { assertSeriesFilename, discoverArchive, humanize } from "../lib/dashboard-archive.mjs";

const validSummary = {
  schemaVersion: 1,
  metadata: { scenarioId: "00", profileId: "full-endpoint-exercise", seriesName: "local-small-ramp", generatedAt: "2026-07-18T00:00:00Z", resourceEnvelope: "local-small" },
  steps: [{ name: "light", vus: 4, duration: "30s", metrics: {} }]
};

test("discovers valid runs and reports rejected summaries", async () => {
  const directory = await mkdtemp(path.join(tmpdir(), "gridline-dashboard-"));
  await writeFile(path.join(directory, "valid.series-summary.json"), JSON.stringify(validSummary));
  await writeFile(path.join(directory, "invalid.series-summary.json"), "not json");
  await writeFile(path.join(directory, "ignored.json"), "not json");

  const archive = await discoverArchive(directory);
  assert.equal(archive.runs.length, 1);
  assert.equal(archive.runs[0].displayName, "Full Endpoint Exercise — Local Small Ramp");
  assert.deepEqual(archive.rejected.map((item) => item.filename), ["invalid.series-summary.json"]);
});

test("archive run identifiers cannot escape the archive", () => {
  assert.doesNotThrow(() => assertSeriesFilename("run.series-summary.json"));
  assert.throws(() => assertSeriesFilename("../run.series-summary.json"), /series-summary filename/);
});

test("humanizes identifiers", () => assert.equal(humanize("local-small_fullRun"), "Local Small Full Run"));
