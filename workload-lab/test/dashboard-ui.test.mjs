import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdir, rm, writeFile } from "node:fs/promises";
import { get } from "node:http";
import path from "node:path";
import test from "node:test";

import { chromium } from "@playwright/test";

const archivePath = path.join("workload-lab", "archive");
const port = 4178;
const baseUrl = `http://127.0.0.1:${port}`;
const files = [
  "ui-baseline.series-summary.json",
  "ui-candidate.series-summary.json"
];

test("dashboard compares baseline and candidate series", async () => {
  await mkdir(archivePath, { recursive: true });
  await writeFile(path.join(archivePath, files[0]), JSON.stringify(summary({ generatedAt: "2026-07-22T00:00:00Z", appCommit: "baselinecommit", appTag: "app-v1", p95: 200, avg: 100, events: 120 })));
  await writeFile(path.join(archivePath, files[1]), JSON.stringify(summary({ generatedAt: "2026-07-22T01:00:00Z", appCommit: "candidatecommit", appTag: "app-v2", p95: 150, avg: 80, events: 180 })));

  const server = spawn(process.execPath, ["workload-lab/dashboard/server.mjs"], {
    env: { ...process.env, WORKLOAD_DASHBOARD_PORT: String(port) },
    stdio: "ignore"
  });
  const serverExited = new Promise((resolve) => server.once("exit", resolve));
  let browser;

  try {
    browser = await chromium.launch();
    await waitForDashboard();
    const page = await browser.newPage();
    await page.goto(`${baseUrl}/dashboard/`);
    await page.getByRole("heading", { name: "Compare application revisions" }).waitFor();

    const status = page.locator(".comparison-status");
    await assert.rejects(
      page.getByText("Comparison needs at least two runs").waitFor({ timeout: 500 }),
      /Timeout/
    );
    assert.match(await status.textContent(), /Clean comparison/);
    assert.match(await page.locator(".comparison-section table").textContent(), /p95 latency/);
    assert.match(await page.locator(".comparison-section table").textContent(), /-50.0 ms/);
  } finally {
    await browser?.close();
    server.kill("SIGTERM");
    await serverExited;
    await Promise.all(files.map((file) => rm(path.join(archivePath, file), { force: true })));
  }
});

async function waitForDashboard() {
  const startedAt = Date.now();
  while (Date.now() - startedAt < 5_000) {
    if (await dashboardIsReady()) return;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }

  throw new Error("Dashboard server did not start.");
}

function dashboardIsReady() {
  return new Promise((resolve) => {
    const request = get(`${baseUrl}/api/runs`, (response) => {
      response.resume();
      resolve(response.statusCode === 200);
    });
    request.on("error", () => resolve(false));
    request.setTimeout(500, () => {
      request.destroy();
      resolve(false);
    });
  });
}

function summary({ generatedAt, appCommit, appTag, p95, avg, events }) {
  return {
    schemaVersion: 2,
    metadata: {
      scenarioId: "00",
      profileId: "normal-operations",
      seriesName: "local-small-ramp",
      generatedAt,
      resourceEnvelope: "local-small",
      seed: "seed",
      seedDataProfile: "demo",
      profileHash: "profile",
      textureHash: "texture",
      seriesHash: "series",
      planDigest: "plan",
      resourceEnvelopeSnapshotHash: "envelope",
      executionModel: "duration-based-sequential-users",
      appCommit,
      application: { commit: appCommit, tag: appTag, branch: "main", dirty: false },
      workloadTooling: { commit: "toolingcommit", tag: "workload-lab-v1", branch: "main", dirty: false }
    },
    steps: [{
      name: "light",
      vus: 4,
      duration: "30s",
      metrics: {
        workloadEvents: events,
        httpReqDurationP95: p95,
        httpReqDurationAvg: avg,
        checksRate: 1,
        httpReqFailedRate: 0
      },
      composition: {}
    }]
  };
}
