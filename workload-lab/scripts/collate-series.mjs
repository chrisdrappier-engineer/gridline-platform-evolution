import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import { validateProfileFile } from "../lib/profile-file.mjs";
import { selectSeries, seriesStepSummaryPath, seriesSummaryPaths, stableJsonHash, workflowCompositionFromStep } from "../lib/series.mjs";

const [profilePath, seriesName, baseName] = process.argv.slice(2);

if (!profilePath || !seriesName || !baseName) {
  throw new Error("Usage: node workload-lab/scripts/collate-series.mjs <profile-path> <series-name> <run-base-name>");
}

const profile = await validateProfileFile(profilePath);
const series = selectSeries(profile, seriesName)[0];
const stepSummaries = [];

for (const step of series.steps) {
  const summaryPath = seriesStepSummaryPath({ baseName, stepName: step.name });
  stepSummaries.push(JSON.parse(await readFile(path.join("workload-lab", summaryPath), "utf8")));
}

const firstMetadata = stepSummaries[0].metadata;
const summary = {
  schemaVersion: 1,
  metadata: {
    scenarioId: profile.scenarioId,
    profileId: profile.profileId,
    seriesName: series.name,
    seriesDescription: series.description || "",
    seed: firstMetadata.seed,
    targetBaseUrl: firstMetadata.targetBaseUrl,
    appCommit: firstMetadata.appCommit,
    workloadToolingCommit: firstMetadata.appCommit,
    resourceEnvelope: firstMetadata.resourceEnvelope,
    seedDataProfile: profile.seedDataProfile,
    generatedAt: firstMetadata.generatedAt,
    profilePath,
    profileHash: stableJsonHash(profile),
    textureHash: stableJsonHash({ actors: profile.actors, timeBuckets: profile.timeBuckets, workflows: profile.workflows }),
    seriesHash: stableJsonHash(series),
    executionModel: "duration-based-sequential-users",
    cumulativeSteps: true,
    warmup: false,
    cooldown: false,
    status: "threshold-failed",
    failedStep: stepSummaries.at(-1).metadata.stepName
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

const output = seriesSummaryPaths({ baseName }).json;
await writeFile(output, `${JSON.stringify(summary, null, 2)}\n`);
console.log(`Series summary written: ${output}`);
