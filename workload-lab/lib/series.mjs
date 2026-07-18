import { createHash } from "node:crypto";

export { cadenceSleepSeconds } from "./cadence.mjs";

export function selectSeries(profile, requestedName) {
  const series = profile.series || [];

  if (series.length === 0) {
    throw new Error(`${profile.profileId} does not define any workload series.`);
  }

  if (!requestedName) {
    return series;
  }

  const selected = series.find((definition) => definition.name === requestedName);

  if (!selected) {
    throw new Error(
      `Unknown workload series: ${requestedName}. Available series: ${series.map((definition) => definition.name).join(", ")}`
    );
  }

  return [selected];
}

export function stableJsonHash(value) {
  return createHash("sha256").update(stableStringify(value)).digest("hex");
}

export function seriesRunBaseName({ scenarioId, profileId, seriesName, resourceEnvelope, generatedAt }) {
  return [scenarioId, profileId, seriesName, resourceEnvelope, generatedAt].map(slug).join("-");
}

export function seriesStepSummaryPath({ baseName, stepName }) {
  return `archive/${baseName}-${slug(stepName)}.step-summary.json`;
}

export function seriesSummaryPaths({ baseName }) {
  return {
    json: `workload-lab/archive/${baseName}.series-summary.json`,
    markdown: `workload-lab/archive/${baseName}.series-summary.md`
  };
}

export function workflowCompositionFromStep(stepSummary) {
  const workflows = stepSummary.metadata.workflows || {};
  const workflowMetrics = stepSummary.metrics.workflows || {};
  const totalEvents = Object.values(workflowMetrics).reduce((sum, metric) => sum + Number(metric.count || 0), 0);

  return Object.fromEntries(
    Object.entries(workflows).map(([name, workflow]) => {
      const count = Number(workflowMetrics[name]?.count || 0);

      return [
        name,
        {
          ...workflow,
          observedEvents: count,
          observedShare: totalEvents > 0 ? count / totalEvents : 0
        }
      ];
    })
  );
}

function stableStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map((entry) => stableStringify(entry)).join(",")}]`;
  }

  if (value && typeof value === "object") {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
      .join(",")}}`;
  }

  return JSON.stringify(value);
}

function slug(value) {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
