import http from "k6/http";
import { check, sleep } from "k6";
import { Counter } from "k6/metrics";

import { summaryFileNames } from "../lib/archive-names.mjs";
import { cadenceSleepSeconds } from "../lib/cadence.mjs";
import { profileRunContext } from "../lib/profile-summary.mjs";
import { pathForEvent, firstServiceRequestPath } from "../lib/requests.mjs";
import { eventFor } from "../lib/traffic-plan.mjs";

const profilePath = __ENV.PROFILE_PATH || "/workload-lab/profiles/baseline-smoke.json";
const profile = JSON.parse(open(profilePath));
const workflowPaths = JSON.parse(open(__ENV.WORKFLOW_PATHS_PATH || "/workload-lab/config/workflow-paths.json"));
const seed = __ENV.WORKLOAD_SEED || "018f3d5f-9f50-77b4-9f2a-4eec5b3f7d1a";
const targetBaseUrl = (__ENV.TARGET_BASE_URL || "http://host.docker.internal:3001").replace(/\/$/, "");
const executionMode = __ENV.WORKLOAD_EXECUTION_MODE || "single-run";
const seriesName = __ENV.WORKLOAD_SERIES_NAME || "";
const seriesStepName = __ENV.WORKLOAD_SERIES_STEP_NAME || "";
const seriesStepCadence = __ENV.WORKLOAD_STEP_CADENCE ? JSON.parse(__ENV.WORKLOAD_STEP_CADENCE) : null;
const workflowCounters = Object.fromEntries(
  Object.keys(profile.workflows).map((name) => [name, new Counter(`workload_workflow_${metricSlug(name)}_events`)])
);
const workloadEvents = new Counter("workload_events");

export const options = buildOptions();

let signedInActorEmail = null;

export default function runProfile() {
  const event = eventFor(profile, { seed, vu: __VU, iteration: __ITER });
  signInAs(event.actor);
  executeEvent(event);
  sleep(0.2);
}

export function runSeriesStep() {
  const event = eventFor(profile, { seed, vu: __VU, iteration: __ITER, cycleTimeBuckets: true });
  signInAs(event.actor);
  executeEvent(event);
  sleep(cadenceSleepSeconds(seriesStepCadence, { seed, seriesName, stepName: seriesStepName, vu: __VU, iteration: __ITER }));
}

export function handleSummary(data) {
  if (executionMode === "series-step") {
    return handleSeriesStepSummary(data);
  }

  const generatedAt = new Date().toISOString();
  const metadata = {
    scenarioId: profile.scenarioId,
    profileId: profile.profileId,
    seed,
    targetBaseUrl,
    appCommit: __ENV.APP_COMMIT || "unknown",
    resourceEnvelope: __ENV.RESOURCE_ENVELOPE || profile.resourceEnvelope,
    seedDataProfile: profile.seedDataProfile,
    vus: options.vus,
    iterations: options.iterations,
    generatedAt,
    ...profileRunContext(profile, { profilePath, thresholds: profile.k6.thresholds })
  };

  const summary = {
    metadata,
    metrics: {
      httpReqFailedRate: data.metrics.http_req_failed?.values?.rate,
      httpReqDurationP95: data.metrics.http_req_duration?.values?.["p(95)"],
      httpReqDurationAvg: data.metrics.http_req_duration?.values?.avg,
      checksRate: data.metrics.checks?.values?.rate
    }
  };
  const fileNames = summaryFileNames(metadata);

  return {
    [fileNames.json]: JSON.stringify(summary, null, 2),
    [fileNames.markdown]: markdownSummary(summary)
  };
}

function executeEvent(event) {
  const path = pathForEvent(event, workflowPaths);
  const response = http.get(`${targetBaseUrl}${path}`, tags(event));

  check(response, {
    [`${event.workflow} returned HTTP 200`]: (result) => result.status === 200
  });

  if (event.type === "service-request-detail") {
    const detailPath = firstServiceRequestPath(response.body);

    check(detailPath, {
      "service request detail path was discovered": (value) => Boolean(value)
    });

    if (detailPath) {
      const detailResponse = http.get(`${targetBaseUrl}${detailPath}`, tags(event, { detail: "true" }));
      check(detailResponse, {
        "service request detail returned HTTP 200": (result) => result.status === 200
      });
    }
  }

  workloadEvents.add(1, tags(event).tags);
  workflowCounters[event.workflow].add(1, tags(event).tags);
}

function handleSeriesStepSummary(data) {
  const generatedAt = new Date().toISOString();
  const summary = {
    metadata: {
      scenarioId: profile.scenarioId,
      profileId: profile.profileId,
      seriesName,
      stepName: seriesStepName,
      seed,
      targetBaseUrl,
      appCommit: __ENV.APP_COMMIT || "unknown",
      resourceEnvelope: __ENV.RESOURCE_ENVELOPE || profile.resourceEnvelope,
      seedDataProfile: profile.seedDataProfile,
      vus: Number(__ENV.WORKLOAD_STEP_VUS),
      duration: __ENV.WORKLOAD_STEP_DURATION,
      cadence: seriesStepCadence,
      generatedAt,
      ...profileRunContext(profile, { profilePath, thresholds: profile.k6.thresholds })
    },
    metrics: {
      httpReqFailedRate: data.metrics.http_req_failed?.values?.rate,
      httpReqDurationP95: data.metrics.http_req_duration?.values?.["p(95)"],
      httpReqDurationAvg: data.metrics.http_req_duration?.values?.avg,
      checksRate: data.metrics.checks?.values?.rate,
      workloadEvents: data.metrics.workload_events?.values?.count || 0,
      workflows: workflowMetrics(data)
    }
  };

  return {
    [__ENV.WORKLOAD_STEP_SUMMARY_PATH]: JSON.stringify(summary, null, 2)
  };
}

function workflowMetrics(data) {
  return Object.fromEntries(
    Object.keys(profile.workflows).map((name) => [
      name,
      {
        count: data.metrics[`workload_workflow_${metricSlug(name)}_events`]?.values?.count || 0
      }
    ])
  );
}

function buildOptions() {
  if (executionMode === "series-step") {
    return {
      scenarios: {
        series_step: {
          executor: "constant-vus",
          vus: Number(__ENV.WORKLOAD_STEP_VUS),
          duration: __ENV.WORKLOAD_STEP_DURATION,
          exec: "runSeriesStep"
        }
      },
      thresholds: profile.k6.thresholds
    };
  }

  return {
    vus: Number(__ENV.WORKLOAD_VUS || profile.k6.vus),
    iterations: Number(__ENV.WORKLOAD_ITERATIONS || profile.k6.iterations),
    thresholds: profile.k6.thresholds
  };
}

function signInAs(actor) {
  if (signedInActorEmail === actor.email) {
    return;
  }

  const loginResponse = http.get(`${targetBaseUrl}/login`, { tags: { workflow: "login" } });
  const token = csrfToken(loginResponse.body);

  check(loginResponse, {
    "login page returned HTTP 200": (result) => result.status === 200,
    "login page included CSRF token": () => Boolean(token)
  });

  const response = http.post(
    `${targetBaseUrl}/login`,
    {
      authenticity_token: token,
      "session[email]": actor.email,
      "session[password]": actor.password
    },
    { tags: { workflow: "login", actor_email: actor.email } }
  );

  check(response, {
    "login POST succeeded": (result) => result.status === 200,
    "login reached dashboard": (result) => result.body.includes("Dashboard")
  });

  signedInActorEmail = actor.email;
}

function csrfToken(html) {
  const match = String(html).match(/<meta name="csrf-token" content="([^"]+)"/);
  return match ? match[1] : "";
}

function tags(event, extra = {}) {
  return {
    tags: {
      scenario_id: profile.scenarioId,
      profile_id: profile.profileId,
      resource_envelope: __ENV.RESOURCE_ENVELOPE || profile.resourceEnvelope,
      workflow: event.workflow,
      workflow_type: event.type,
      actor_role: event.actorRole,
      time_bucket: event.timeBucket,
      ...extra
    }
  };
}

function markdownSummary(summary) {
  return `# Workload Summary

This generated summary is written to the ignored local archive. It is a raw
workload artifact unless it is later promoted into tracked evidence.

## Metadata

- Scenario: ${summary.metadata.scenarioId}
- Profile: ${summary.metadata.profileId}
- Seed: ${summary.metadata.seed}
- Target: ${summary.metadata.targetBaseUrl}
- Resource envelope: ${summary.metadata.resourceEnvelope}
- App commit: ${summary.metadata.appCommit}
- VUs: ${summary.metadata.vus}
- Iterations: ${summary.metadata.iterations}
- Generated at: ${summary.metadata.generatedAt}
- Profile path: ${summary.metadata.profilePath}

## Thresholds

${markdownThresholds(summary.metadata.thresholds)}

## Workload Shape

### Time Buckets

${markdownTimeBuckets(summary.metadata.timeBuckets)}

### Workflows

${markdownWorkflows(summary.metadata.workflows)}

## Metrics

- HTTP failure rate: ${summary.metrics.httpReqFailedRate}
- HTTP duration p95: ${summary.metrics.httpReqDurationP95}
- HTTP duration avg: ${summary.metrics.httpReqDurationAvg}
- Check pass rate: ${summary.metrics.checksRate}
`;
}

function markdownThresholds(thresholds) {
  return Object.entries(thresholds || {})
    .map(([metric, rules]) => `- ${metric}: ${formatThresholdRules(rules)}`)
    .join("\n");
}

function formatThresholdRules(rules) {
  if (Array.isArray(rules)) {
    return rules.join(", ");
  }

  if (rules && typeof rules === "object") {
    return Object.values(rules).join(", ");
  }

  return String(rules);
}

function markdownTimeBuckets(timeBuckets) {
  return timeBuckets
    .map((bucket) => {
      const mix = Object.entries(bucket.workflowMix)
        .map(([workflow, weight]) => `${workflow}=${weight}`)
        .join(", ");

      return `- ${bucket.name}: ${bucket.iterations} iterations; ${mix}`;
    })
    .join("\n");
}

function markdownWorkflows(workflows) {
  return Object.entries(workflows)
    .map(([name, workflow]) => `- ${name}: ${workflow.type} as ${workflow.actorRole}`)
    .join("\n");
}

function metricSlug(value) {
  return String(value)
    .trim()
    .replace(/[^A-Za-z0-9_]/g, "_")
    .replace(/^_+|_+$/g, "");
}
