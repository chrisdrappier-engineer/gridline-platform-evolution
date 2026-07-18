const SUPPORTED_SCHEMA_VERSIONS = new Set([1]);

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
