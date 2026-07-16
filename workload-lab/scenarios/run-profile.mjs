import http from "k6/http";
import { check, sleep } from "k6";

import { eventFor } from "../lib/traffic-plan.mjs";
import { pathForEvent, firstServiceRequestPath } from "../workflows/requests.mjs";

const profile = JSON.parse(open(__ENV.PROFILE_PATH || "/workload-lab/profiles/baseline-smoke.json"));
const seed = __ENV.WORKLOAD_SEED || "2026071601";
const targetBaseUrl = (__ENV.TARGET_BASE_URL || "http://host.docker.internal:3001").replace(/\/$/, "");
const actor = profile.actors.dispatcher[0];

export const options = {
  vus: Number(__ENV.WORKLOAD_VUS || profile.k6.vus),
  iterations: Number(__ENV.WORKLOAD_ITERATIONS || profile.k6.iterations),
  thresholds: profile.k6.thresholds
};

let signedIn = false;

export default function runProfile() {
  if (!signedIn) {
    signIn();
    signedIn = true;
  }

  const event = eventFor(profile, { seed, vu: __VU, iteration: __ITER });
  executeEvent(event);
  sleep(0.2);
}

export function handleSummary(data) {
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
    generatedAt: new Date().toISOString()
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

  return {
    "archive/latest-summary.json": JSON.stringify(summary, null, 2),
    "archive/latest-summary.md": markdownSummary(summary)
  };
}

function executeEvent(event) {
  const path = pathForEvent(event);
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
}

function signIn() {
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
    { tags: { workflow: "login" } }
  );

  check(response, {
    "login POST succeeded": (result) => result.status === 200,
    "login reached dashboard": (result) => result.body.includes("Dashboard")
  });
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
      time_bucket: event.timeBucket,
      ...extra
    }
  };
}

function markdownSummary(summary) {
  return `# Workload Smoke Summary

This generated summary is written to the ignored local archive. It is a smoke
artifact, not promoted workload evidence.

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

## Metrics

- HTTP failure rate: ${summary.metrics.httpReqFailedRate}
- HTTP duration p95: ${summary.metrics.httpReqDurationP95}
- HTTP duration avg: ${summary.metrics.httpReqDurationAvg}
- Check pass rate: ${summary.metrics.checksRate}
`;
}
