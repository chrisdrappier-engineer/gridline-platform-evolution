import { spawnSync } from "node:child_process";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import { validateProfileFile } from "../lib/profile-file.mjs";
import {
  selectSeries,
  seriesRunBaseName,
  seriesStepSummaryPath,
  seriesSummaryPaths,
  stableJsonHash,
  workflowCompositionFromStep
} from "../lib/series.mjs";
import { assertValidSeed } from "../lib/traffic-plan.mjs";

const DEFAULT_SEED = "01981f6d-89a0-7b2c-9c45-5d8df49f5e40";
const DEFAULT_TARGET_BASE_URL = "http://host.docker.internal:3001";
const DEFAULT_RESOURCE_ENVELOPE = "local-small";

let profilePath;
let seed;
let targetBaseUrl;
let resourceEnvelope;
let appCommit;
let workloadToolingCommit;
let profileHash;
let textureHash;
let profile;
let generatedAt;

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

async function main() {
  profilePath = process.argv[2];
  const requestedSeriesName = process.argv[3];

  if (!profilePath) {
    throw new Error("Usage: bin/workload-run-series <profile-path> [series-name]");
  }

  profile = await validateProfileFile(profilePath);
  seed = assertValidSeed(process.env.WORKLOAD_SEED || DEFAULT_SEED);
  const selectedSeries = selectSeries(profile, requestedSeriesName);
  generatedAt = new Date().toISOString();
  targetBaseUrl = process.env.TARGET_BASE_URL || DEFAULT_TARGET_BASE_URL;
  resourceEnvelope = process.env.RESOURCE_ENVELOPE || profile.resourceEnvelope || DEFAULT_RESOURCE_ENVELOPE;
  appCommit = process.env.APP_COMMIT || gitValue(["rev-parse", "HEAD"]);
  workloadToolingCommit = gitValue(["rev-parse", "HEAD"]);
  profileHash = stableJsonHash(profile);
  textureHash = stableJsonHash({
    actors: profile.actors,
    timeBuckets: profile.timeBuckets,
    workflows: profile.workflows
  });

  await mkdir("workload-lab/archive", { recursive: true });

  for (const series of selectedSeries) {
    await runSeries(series);
  }
}

async function runSeries(series) {
  const baseName = seriesRunBaseName({
    scenarioId: profile.scenarioId,
    profileId: profile.profileId,
    seriesName: series.name,
    resourceEnvelope,
    generatedAt
  });
  const stepSummaries = [];
  let failedStep = null;

  for (const step of series.steps) {
    const summaryPath = seriesStepSummaryPath({ baseName, stepName: step.name });
    const status = runStep({ series, step, summaryPath });

    stepSummaries.push(JSON.parse(await readFile(path.join("workload-lab", summaryPath), "utf8")));
    if (status !== 0) {
      failedStep = step.name;
      break;
    }
  }

  const summary = {
    schemaVersion: 1,
    metadata: {
      scenarioId: profile.scenarioId,
      profileId: profile.profileId,
      seriesName: series.name,
      seriesDescription: series.description || "",
      seed,
      targetBaseUrl,
      appCommit,
      workloadToolingCommit,
      resourceEnvelope,
      seedDataProfile: profile.seedDataProfile,
      generatedAt,
      profilePath,
      profileHash,
      textureHash,
      seriesHash: stableJsonHash(series),
      executionModel: "duration-based-sequential-users",
      cumulativeSteps: true,
      warmup: false,
      cooldown: false,
      status: failedStep ? "threshold-failed" : "completed",
      failedStep
    },
    steps: stepSummaries.map((stepSummary) => ({
      name: stepSummary.metadata.stepName,
      vus: stepSummary.metadata.vus,
      duration: stepSummary.metadata.duration,
      cadence: stepSummary.metadata.cadence,
      metrics: stepSummary.metrics,
      composition: workflowCompositionFromStep(stepSummary),
      coverage: stepSummary.coverage || { endpoints: [], workflowSequences: [] },
      stepSummaryPath: path.join("workload-lab", seriesStepSummaryPath({ baseName, stepName: stepSummary.metadata.stepName }))
    }))
  };

  const summaryPaths = seriesSummaryPaths({ baseName });
  await writeFile(summaryPaths.json, `${JSON.stringify(summary, null, 2)}\n`);
  await writeFile(summaryPaths.markdown, markdownSeriesSummary(summary));

  console.log(`Series summary written: ${summaryPaths.json}`);
  console.log(`Series summary written: ${summaryPaths.markdown}`);

  if (failedStep) {
    throw new Error(`Series threshold failed: ${series.name} / ${failedStep}. Partial series summary was preserved.`);
  }
}

function runStep({ series, step, summaryPath }) {
  console.log(`Running ${series.name} / ${step.name}: ${step.vus} VUs for ${step.duration}`);

  const result = spawnSync("docker", ["compose", "-f", "compose.workload.yml", "run", "--rm", "k6"], {
    stdio: "inherit",
    env: {
      ...process.env,
      TARGET_BASE_URL: targetBaseUrl,
      PROFILE_PATH: containerProfilePath(profilePath),
      WORKLOAD_SEED: seed,
      WORKLOAD_EXECUTION_MODE: "series-step",
      WORKLOAD_SERIES_NAME: series.name,
      WORKLOAD_SERIES_STEP_NAME: step.name,
      WORKLOAD_STEP_VUS: String(step.vus),
      WORKLOAD_STEP_DURATION: step.duration,
      WORKLOAD_STEP_CADENCE: JSON.stringify(step.cadence),
      WORKLOAD_STEP_SUMMARY_PATH: summaryPath,
      RESOURCE_ENVELOPE: resourceEnvelope,
      APP_COMMIT: appCommit
    }
  });

  return result.status;
}

function containerProfilePath(value) {
  const normalized = value.replace(/^\.\//, "");

  if (normalized.startsWith("/workload-lab/")) {
    return normalized;
  }

  if (normalized.startsWith("workload-lab/")) {
    return `/${normalized}`;
  }

  throw new Error("Profile path must be under workload-lab/ so it can be mounted into the k6 container.");
}

function gitValue(args) {
  const result = spawnSync("git", args, { encoding: "utf8" });

  if (result.status !== 0) {
    return "unknown";
  }

  return result.stdout.trim() || "unknown";
}

function markdownSeriesSummary(summary) {
  return `# Workload Series Summary

This generated summary is written to the ignored local archive. It is raw
workload evidence unless it is later promoted into tracked evidence.

## Metadata

- Scenario: ${summary.metadata.scenarioId}
- Profile: ${summary.metadata.profileId}
- Series: ${summary.metadata.seriesName}
- Seed: ${summary.metadata.seed}
- Target: ${summary.metadata.targetBaseUrl}
- Resource envelope: ${summary.metadata.resourceEnvelope}
- App commit: ${summary.metadata.appCommit}
- Workload tooling commit: ${summary.metadata.workloadToolingCommit}
- Execution model: ${summary.metadata.executionModel}
- Cumulative steps: ${summary.metadata.cumulativeSteps}
- Generated at: ${summary.metadata.generatedAt}
- Profile hash: ${summary.metadata.profileHash}
- Texture hash: ${summary.metadata.textureHash}
- Series hash: ${summary.metadata.seriesHash}

## Steps

${summary.steps.map(markdownStep).join("\n\n")}
`;
}

function markdownStep(step) {
  return `### ${step.name}

- VUs: ${step.vus}
- Duration: ${step.duration}
- Cadence: ${JSON.stringify(step.cadence)}
- HTTP failure rate: ${step.metrics.httpReqFailedRate}
- HTTP duration p95: ${step.metrics.httpReqDurationP95}
- HTTP duration avg: ${step.metrics.httpReqDurationAvg}
- Check pass rate: ${step.metrics.checksRate}
- Observed workload events: ${step.metrics.workloadEvents}
`;
}
