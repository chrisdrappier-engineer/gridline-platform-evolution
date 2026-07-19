import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import { validateProfileFile } from "../lib/profile-file.mjs";
import { selectSeries, seriesStepSummaryPath, seriesSummaryPaths, stableJsonHash, workflowCompositionFromStep } from "../lib/series.mjs";
import { evidenceAssessment, gitContext, planDigest, resourceEnvelopeSnapshot } from "../lib/evidence.mjs";

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
const profileHash = stableJsonHash(profile);
const textureHash = stableJsonHash({ actors: profile.actors, timeBuckets: profile.timeBuckets, workflows: profile.workflows });
const seriesHash = stableJsonHash(series);
const digest = planDigest({ profileHash, seriesHash, seed: firstMetadata.seed });
const envelopeSnapshot = resourceEnvelopeSnapshot(firstMetadata.resourceEnvelope);
const application = gitContext({ commit: firstMetadata.appCommit });
const workloadTooling = gitContext();
const evidence = evidenceAssessment({
  profileHash,
  textureHash,
  seriesHash,
  planDigest: digest,
  seed: firstMetadata.seed,
  resourceEnvelopeSnapshotHash: envelopeSnapshot.hash,
  seedDataProfile: profile.seedDataProfile,
  executionModel: "duration-based-sequential-users",
  application,
  workloadTooling
});
const summary = {
  schemaVersion: 2,
  metadata: {
    scenarioId: profile.scenarioId,
    profileId: profile.profileId,
    profileDescription: profile.description || "",
    seriesName: series.name,
    seriesDescription: series.description || "",
    seed: firstMetadata.seed,
    targetBaseUrl: firstMetadata.targetBaseUrl,
    appCommit: firstMetadata.appCommit,
    workloadToolingCommit: workloadTooling.commit || "unknown",
    application,
    workloadTooling,
    resourceEnvelope: firstMetadata.resourceEnvelope,
    resourceEnvelopeSnapshot: envelopeSnapshot,
    resourceEnvelopeSnapshotHash: envelopeSnapshot.hash,
    seedDataProfile: profile.seedDataProfile,
    generatedAt: firstMetadata.generatedAt,
    profilePath,
    profileHash,
    textureHash,
    seriesHash,
    planDigest: digest,
    evidenceStatus: evidence.status,
    evidenceStatusReasons: evidence.reasons,
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
