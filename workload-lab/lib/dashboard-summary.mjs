import { compareEvidence } from "./comparability.mjs";

const SUPPORTED_SCHEMA_VERSIONS = new Set([1, 2]);

export function parseSeriesSummary(text, sourceName = "selected file") {
  let summary;

  try {
    summary = JSON.parse(text);
  } catch {
    throw new Error(`${sourceName} is not valid JSON.`);
  }

  validateSeriesSummary(summary, sourceName);
  return summary;
}

export function validateSeriesSummary(summary, sourceName = "selected file") {
  if (!summary || typeof summary !== "object" || Array.isArray(summary)) {
    throw new Error(`${sourceName} must contain a JSON object.`);
  }

  if (summary.schemaVersion !== undefined && !SUPPORTED_SCHEMA_VERSIONS.has(summary.schemaVersion)) {
    throw new Error(`${sourceName} uses unsupported schema version ${summary.schemaVersion}.`);
  }

  const requiredMetadata = ["scenarioId", "profileId", "seriesName", "generatedAt", "resourceEnvelope"];
  const missingMetadata = requiredMetadata.filter((key) => !summary.metadata?.[key]);

  if (missingMetadata.length > 0) {
    throw new Error(`${sourceName} is missing metadata: ${missingMetadata.join(", ")}.`);
  }

  if (!Array.isArray(summary.steps) || summary.steps.length === 0) {
    throw new Error(`${sourceName} must contain at least one series step.`);
  }

  summary.steps.forEach((step, index) => {
    if (!step?.name || !Number.isFinite(Number(step.vus)) || !step.duration || !step.metrics) {
      throw new Error(`${sourceName} has an invalid step at position ${index + 1}.`);
    }
  });
}

export function runRecord(summary, sourceName) {
  return {
    id: `${summary.metadata.generatedAt}-${sourceName}`,
    sourceName,
    summary,
    generatedAt: new Date(summary.metadata.generatedAt),
    legacySchema: summary.schemaVersion === undefined
  };
}

export function durationSeconds(duration) {
  const match = String(duration).trim().match(/^(\d+(?:\.\d+)?)(ms|s|m|h)$/);

  if (!match) return null;

  const value = Number(match[1]);
  const multipliers = { ms: 0.001, s: 1, m: 60, h: 3600 };
  return value * multipliers[match[2]];
}

export function eventsPerSecond(step) {
  const seconds = durationSeconds(step.duration);
  return seconds ? Number(step.metrics.workloadEvents || 0) / seconds : null;
}

export function groupedComposition(step) {
  const roles = new Map();

  Object.entries(step.composition || {}).forEach(([name, workflow]) => {
    const role = workflow.actorRole || "unknown";
    const current = roles.get(role) || { role, events: 0, workflows: [] };
    const events = Number(workflow.observedEvents || 0);
    current.events += events;
    current.workflows.push({ name, type: workflow.type || "unknown", events });
    roles.set(role, current);
  });

  return [...roles.values()].sort((left, right) => right.events - left.events);
}

export function comparisonAgainst(selected, runs) {
  return runs
    .filter((run) => run.id !== selected.id)
    .map((run) => ({ run, ...compareEvidence(selected.summary.metadata, run.summary.metadata) }));
}

export const COMPARISON_METRICS = [
  { key: "httpReqDurationP95", label: "p95 latency", format: "ms", lowerIsBetter: true, value: (step) => numeric(step.metrics.httpReqDurationP95) },
  { key: "httpReqDurationAvg", label: "Average latency", format: "ms", lowerIsBetter: true, value: (step) => numeric(step.metrics.httpReqDurationAvg) },
  { key: "eventsPerSecond", label: "Throughput", format: "rate", lowerIsBetter: false, value: (step) => eventsPerSecond(step) || 0 },
  { key: "checksRate", label: "Check rate", format: "percent", lowerIsBetter: false, value: (step) => numeric(step.metrics.checksRate) },
  { key: "httpReqFailedRate", label: "HTTP failure rate", format: "percent", lowerIsBetter: true, value: (step) => numeric(step.metrics.httpReqFailedRate) }
];

export function compareSeriesSummaries(baseline, candidate) {
  const compatibility = compareEvidence(baseline.metadata, candidate.metadata);
  const candidateSteps = new Map(candidate.steps.map((step, index) => [step.name || `step-${index}`, step]));
  const rows = baseline.steps.map((baselineStep, index) => {
    const stepKey = baselineStep.name || `step-${index}`;
    const candidateStep = candidateSteps.get(stepKey) || candidate.steps[index];

    return {
      step: stepKey,
      baselineVus: baselineStep.vus,
      candidateVus: candidateStep?.vus,
      metrics: COMPARISON_METRICS.map((metric) => comparisonMetric(metric, baselineStep, candidateStep))
    };
  });
  const missingCandidateSteps = candidate.steps
    .filter((step, index) => !baseline.steps.some((baselineStep) => (baselineStep.name || `step-${index}`) === (step.name || `step-${index}`)))
    .map((step, index) => step.name || `extra-step-${index}`);

  return {
    status: compatibility.status,
    differences: [...compatibility.differences, ...missingCandidateSteps.map((step) => `candidate has unmatched step ${step}`)],
    rows
  };
}

export function provenancePresentation(summary, sourceName) {
  const metadata = summary.metadata;
  const envelope = metadata.resourceEnvelopeSnapshot;

  return {
    legacyNotice: summary.schemaVersion === 2 ? null : "Legacy summary: revision context, plan digest, and effective resource settings were not recorded.",
    definition: [
      { label: "Scenario", value: metadata.scenarioId },
      { label: "Profile", value: metadata.profileId, description: metadata.profileDescription },
      { label: "Series", value: metadata.seriesName, description: metadata.seriesDescription },
      { label: "Resource envelope", value: metadata.resourceEnvelope, description: envelopeDescription(envelope) },
      { label: "Seed data", value: metadata.seedDataProfile },
      { label: "Execution", value: metadata.executionModel },
      { label: "Workload seed", value: metadata.seed }
    ].filter((field) => field.value !== undefined && field.value !== null && field.value !== ""),
    revisions: [
      revisionField("Application", metadata.application, metadata.appCommit),
      revisionField("Workload tooling", metadata.workloadTooling, metadata.workloadToolingCommit)
    ].filter(Boolean),
    fingerprints: [
      { label: "Profile hash", value: metadata.profileHash },
      { label: "Texture hash", value: metadata.textureHash },
      { label: "Series hash", value: metadata.seriesHash },
      { label: "Plan digest", value: metadata.planDigest },
      { label: "Envelope hash", value: metadata.resourceEnvelopeSnapshotHash }
    ].filter((field) => field.value),
    source: sourceName,
    schema: summary.schemaVersion ? `Version ${summary.schemaVersion}` : "Legacy / unversioned"
  };
}

function revisionField(label, context, fallbackCommit) {
  if (!context && !fallbackCommit) return null;
  const commit = context?.commit || fallbackCommit;
  const labels = [context?.tag && `tag ${context.tag}`, context?.branch && `branch ${context.branch}`, context?.dirty === true ? "dirty" : context?.dirty === false ? "clean" : null].filter(Boolean);

  return { label, value: labels.join(" · ") || "Commit only; branch, tag, and clean state not recorded", commit, shortCommit: commit?.slice(0, 10) };
}

function envelopeDescription(envelope) {
  if (!envelope) return null;
  return `App ${envelope.app.cpus} CPU / ${envelope.app.memory}, ${envelope.app.webConcurrency} process / ${envelope.app.maxThreads} threads; DB ${envelope.database.cpus} CPU / ${envelope.database.memory}`;
}

function comparisonMetric(metric, baselineStep, candidateStep) {
  const baseline = metric.value(baselineStep);
  const candidate = candidateStep ? metric.value(candidateStep) : null;
  const absoluteDelta = candidate === null ? null : candidate - baseline;
  const percentDelta = absoluteDelta === null || baseline === 0 ? null : absoluteDelta / baseline;
  const improvement = absoluteDelta === null ? null : metric.lowerIsBetter ? absoluteDelta < 0 : absoluteDelta > 0;

  return { key: metric.key, label: metric.label, format: metric.format, baseline, candidate, absoluteDelta, percentDelta, improvement };
}

function numeric(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}
