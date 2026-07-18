import http from "k6/http";
import { check, sleep } from "k6";
import { Counter } from "k6/metrics";

import { summaryFileNames } from "../lib/archive-names.mjs";
import { cadenceSleepSeconds } from "../lib/cadence.mjs";
import { profileRunContext } from "../lib/profile-summary.mjs";
import { pathForEvent, firstServiceRequestPath, serviceRequestNotesPath } from "../lib/requests.mjs";
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
const endpointDefinitions = buildEndpointDefinitions();
const endpointCounters = Object.fromEntries(
  endpointDefinitions.map((endpoint) => [endpoint.key, {
    requests: new Counter(`workload_endpoint_${metricSlug(endpoint.key)}_requests`),
    failures: new Counter(`workload_endpoint_${metricSlug(endpoint.key)}_failures`)
  }])
);
const workloadEvents = new Counter("workload_events");

export const options = buildOptions();

let signedInActorEmail = null;

export default function runProfile() {
  const event = selectedEvent({ cycleTimeBuckets: false });
  signInAs(event.actor);
  executeEvent(event);
  sleep(0.2);
}

export function runSeriesStep() {
  const event = selectedEvent({ cycleTimeBuckets: true });
  signInAs(event.actor);
  executeEvent(event);
  sleep(cadenceSleepSeconds(seriesStepCadence, { seed, seriesName, stepName: seriesStepName, vu: __VU, iteration: __ITER }));
}

function selectedEvent({ cycleTimeBuckets }) {
  const event = eventFor(profile, { seed, vu: __VU, iteration: __ITER, cycleTimeBuckets });
  const forcedWorkflowName = __ENV.WORKLOAD_FORCE_WORKFLOW;
  if (!forcedWorkflowName) return event;

  const workflow = profile.workflows[forcedWorkflowName];
  if (!workflow) throw new Error(`Unknown forced workflow: ${forcedWorkflowName}`);

  return {
    ...event,
    workflow: forcedWorkflowName,
    actorRole: workflow.actorRole || "dispatcher",
    actor: profile.actors[workflow.actorRole || "dispatcher"][0],
    type: workflow.type,
    params: {}
  };
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
    },
    coverage: coverageMetrics(data)
  };
  const fileNames = summaryFileNames(metadata);

  return {
    [fileNames.json]: JSON.stringify(summary, null, 2),
    [fileNames.markdown]: markdownSummary(summary)
  };
}

function executeEvent(event) {
  if (event.type === "full-endpoint-exercise") {
    executeFullEndpointExercise(event);
    workloadEvents.add(1, tags(event).tags);
    workflowCounters[event.workflow].add(1, tags(event).tags);
    return;
  }

  const path = pathForEvent(event, workflowPaths);
  const response = http.get(`${targetBaseUrl}${path}`, tags(event));
  recordEndpoint(`${event.workflow}:primary`, response, event);

  check(response, {
    [`${event.workflow} returned HTTP 200`]: (result) => result.status === 200
  });

  if (["service-request-detail", "service-request-note-create"].includes(event.type)) {
    const detailPath = firstServiceRequestPath(response.body);

    check(detailPath, {
      "service request detail path was discovered": (value) => Boolean(value)
    });

    if (detailPath) {
      const detailResponse = http.get(`${targetBaseUrl}${detailPath}`, tags(event, { detail: "true" }));
      recordEndpoint(`${event.workflow}:detail`, detailResponse, event);
      check(detailResponse, {
        "service request detail returned HTTP 200": (result) => result.status === 200
      });

      if (event.type === "service-request-note-create") {
        createServiceRequestNote(event, detailPath, detailResponse);
      }
    }
  }

  workloadEvents.add(1, tags(event).tags);
  workflowCounters[event.workflow].add(1, tags(event).tags);
}

function executeFullEndpointExercise(event) {
  const suffix = `${event.seed.slice(-8)}-${event.vu}-${event.iteration}`;
  const root = endpointRequest(event, "root", "GET", "/");
  endpointRequest(event, "health", "GET", "/health");
  endpointRequest(event, "up", "GET", "/up");
  endpointRequest(event, "dashboard", "GET", "/dashboard");

  const customers = endpointRequest(event, "customers-index", "GET", "/customers");
  const customerNew = endpointRequest(event, "customers-new", "GET", "/customers/new");
  endpointRequest(event, "customers-create", "POST", "/customers", { authenticity_token: csrfToken(customerNew.body), "customer[name]": `Coverage Customer ${suffix}`, "customer[account_status]": "active", "customer[industry]": "facilities", "customer[quote_approval_threshold_cents]": "500000" });
  const customerPath = firstResourcePath(customers.body, "customers");
  if (customerPath) {
    endpointRequest(event, "customers-show", "GET", customerPath);
    const edit = endpointRequest(event, "customers-edit", "GET", `${customerPath}/edit`);
    endpointRequest(event, "customers-patch", "PATCH", customerPath, { authenticity_token: csrfToken(edit.body), "customer[industry]": "endpoint_exercise" });
    endpointRequest(event, "customers-put", "PUT", customerPath, { authenticity_token: csrfToken(edit.body), "customer[industry]": "facilities" });
  }

  const sites = endpointRequest(event, "sites-index", "GET", "/customer_sites");
  const siteNew = endpointRequest(event, "sites-new", "GET", "/customer_sites/new");
  const sitePath = firstResourcePath(sites.body, "customer_sites");
  if (customerPath) endpointRequest(event, "sites-create", "POST", "/customer_sites", { authenticity_token: csrfToken(siteNew.body), "customer_site[customer_id]": resourceId(customerPath), "customer_site[facility_manager_id]": firstFormOption(siteNew.body, "customer_site[facility_manager_id]"), "customer_site[name]": `Coverage Site ${suffix}`, "customer_site[address_line_1]": "100 Coverage Way", "customer_site[city]": "Chicago", "customer_site[state]": "IL", "customer_site[postal_code]": "60601", "customer_site[site_status]": "active" });
  if (sitePath) {
    endpointRequest(event, "sites-show", "GET", sitePath);
    const edit = endpointRequest(event, "sites-edit", "GET", `${sitePath}/edit`);
    endpointRequest(event, "sites-patch", "PATCH", sitePath, { authenticity_token: csrfToken(edit.body), "customer_site[address_line_2]": `Coverage ${suffix}` });
    endpointRequest(event, "sites-put", "PUT", sitePath, { authenticity_token: csrfToken(edit.body), "customer_site[address_line_2]": "" });
  }

  const providers = endpointRequest(event, "providers-index", "GET", "/service_providers");
  const providerNew = endpointRequest(event, "providers-new", "GET", "/service_providers/new");
  endpointRequest(event, "providers-create", "POST", "/service_providers", { authenticity_token: csrfToken(providerNew.body), "service_provider[name]": `Coverage Provider ${suffix}`, "service_provider[provider_type]": "vendor_partner", "service_provider[status]": "active" });
  const providerPath = firstResourcePath(providers.body, "service_providers");
  if (providerPath) {
    endpointRequest(event, "providers-show", "GET", providerPath);
    const edit = endpointRequest(event, "providers-edit", "GET", `${providerPath}/edit`);
    endpointRequest(event, "providers-patch", "PATCH", providerPath, { authenticity_token: csrfToken(edit.body), "service_provider[status]": "active" });
    endpointRequest(event, "providers-put", "PUT", providerPath, { authenticity_token: csrfToken(edit.body), "service_provider[status]": "active" });
  }

  const requestIndex = endpointRequest(event, "requests-index", "GET", "/service_requests");
  endpointRequest(event, "requests-new", "GET", "/service_requests/new");
  const seededRequestPath = firstResourcePath(requestIndex.body, "service_requests");
  const seededRequest = seededRequestPath ? endpointRequest(event, "requests-show-seeded", "GET", seededRequestPath) : root;
  const requestPath = createCoverageRequest(event, sitePath, providerPath, suffix, root);
  if (requestPath) exerciseRequestEndpoints(event, requestPath, providerPath, suffix);

  const thumbnailPath = findEvidenceThumbnail(event, requestIndex.body, seededRequest);
  if (thumbnailPath) {
    endpointRequest(event, "evidence-show", "GET", thumbnailPath.replace(/\/thumbnail$/, ""));
    endpointRequest(event, "evidence-thumbnail", "GET", thumbnailPath);
  }

  const dispatcherId = firstFormOption(requestIndex.body, "service_requests[dispatcher_id]");
  if (dispatcherId) endpointRequest(event, "dispatchers-show", "GET", `/dispatchers/${dispatcherId}`);
  endpointRequest(event, "admin-permissions", "GET", "/admin/permission-matrix");
  endpointRequest(event, "admin-assignments", "GET", "/admin/role-assignments");
  endpointRequest(event, "admin-users", "GET", "/admin/users");

  const logoutToken = csrfToken(root.body);
  endpointRequest(event, "logout", "DELETE", "/logout", { authenticity_token: logoutToken });
  signedInActorEmail = null;
}

function createCoverageRequest(event, sitePath, providerPath, suffix, fallbackResponse) {
  if (!sitePath) return null;
  const form = endpointRequest(event, "requests-new-context", "GET", `/service_requests/new?customer_site_id=${resourceId(sitePath)}`);
  const response = endpointRequest(event, "requests-create", "POST", "/service_requests", {
    authenticity_token: csrfToken(form.body || fallbackResponse.body),
    "service_request[customer_site_id]": resourceId(sitePath),
    "service_request[service_provider_id]": resourceId(providerPath),
    "service_request[title]": `Endpoint coverage request ${suffix}`,
    "service_request[description]": "Deterministic full endpoint exercise.",
    "service_request[priority]": "normal"
  }, { redirects: 0 });
  return locationPath(response);
}

function exerciseRequestEndpoints(event, requestPath, providerPath, suffix) {
  let show = endpointRequest(event, "requests-show", "GET", requestPath);
  endpointRequest(event, "requests-edit", "GET", `${requestPath}/edit`);
  endpointRequest(event, "requests-patch", "PATCH", requestPath, { authenticity_token: csrfToken(show.body), "service_request[priority]": "high" });
  endpointRequest(event, "requests-put", "PUT", requestPath, { authenticity_token: csrfToken(show.body), "service_request[priority]": "normal" });
  endpointRequest(event, "requests-follow-up", "GET", `${requestPath}/new_follow_up`);
  endpointRequest(event, "requests-triage", "PATCH", `${requestPath}/triage`, { authenticity_token: csrfToken(show.body) });
  endpointRequest(event, "requests-assign", "PATCH", `${requestPath}/assign`, { authenticity_token: csrfToken(show.body), "service_request[service_provider_id]": resourceId(providerPath) });

  show = endpointRequest(event, "requests-show-after-assign", "GET", requestPath);
  endpointRequest(event, "quotes-create", "POST", `${requestPath}/service_request_quote`, { authenticity_token: csrfToken(show.body), "service_request_quote[amount_dollars]": "9999.00", "service_request_quote[description]": "Endpoint coverage quote" });
  show = endpointRequest(event, "requests-show-after-quote", "GET", requestPath);
  endpointRequest(event, "quotes-approve", "PATCH", `${requestPath}/service_request_quote/approve`, { authenticity_token: csrfToken(show.body), "service_request_quote[approval_notes]": "Coverage approval" });
  endpointRequest(event, "quotes-patch", "PATCH", `${requestPath}/service_request_quote`, { authenticity_token: csrfToken(show.body), "service_request_quote[amount_dollars]": "10001.00", "service_request_quote[description]": "Amended coverage quote", "service_request_quote[amendment_reason]": "Endpoint method coverage" });
  endpointRequest(event, "quotes-put", "PUT", `${requestPath}/service_request_quote`, { authenticity_token: csrfToken(show.body), "service_request_quote[amount_dollars]": "10002.00", "service_request_quote[description]": "PUT coverage quote", "service_request_quote[amendment_reason]": "Endpoint PUT coverage" });
  endpointRequest(event, "quotes-reject", "PATCH", `${requestPath}/service_request_quote/reject`, { authenticity_token: csrfToken(show.body), "service_request_quote[approval_notes]": "Coverage rejection" });

  endpointRequest(event, "costs-create", "POST", `${requestPath}/service_request_costs`, { authenticity_token: csrfToken(show.body), "service_request_cost[category]": "labor", "service_request_cost[amount_dollars]": "125.00", "service_request_cost[currency]": "USD", "service_request_cost[incurred_on]": "2026-07-18", "service_request_cost[description]": `Coverage cost ${suffix}` });
  show = endpointRequest(event, "requests-show-after-cost", "GET", requestPath);
  const costEditPath = firstMatchingPath(show.body, new RegExp(`${requestPath}/service_request_costs/[0-9a-f-]+/edit`));
  if (costEditPath) {
    const costPath = costEditPath.replace(/\/edit$/, "");
    const costEdit = endpointRequest(event, "costs-edit", "GET", costEditPath);
    endpointRequest(event, "costs-patch", "PATCH", costPath, { authenticity_token: csrfToken(costEdit.body), "service_request_cost[description]": "PATCH coverage" });
    endpointRequest(event, "costs-put", "PUT", costPath, { authenticity_token: csrfToken(costEdit.body), "service_request_cost[description]": "PUT coverage" });
  }

  endpointRequest(event, "notes-create", "POST", `${requestPath}/service_request_notes`, { authenticity_token: csrfToken(show.body), "service_request_note[note_type]": "general", "service_request_note[visibility]": "internal", "service_request_note[body]": `Full endpoint exercise ${suffix}` });
  endpointRequest(event, "requests-respond", "PATCH", `${requestPath}/respond`, { authenticity_token: csrfToken(show.body), "service_request[provider_response_summary]": "Coverage response", "service_request[mark_provider_work_complete]": "1" });
  endpointRequest(event, "requests-verify", "PATCH", `${requestPath}/verify_completion`, { authenticity_token: csrfToken(show.body) });
  endpointRequest(event, "feedback-create", "POST", `${requestPath}/service_request_feedback`, { authenticity_token: csrfToken(show.body), "service_request_feedback[rating]": "4", "service_request_feedback[feedback]": "Coverage feedback", "service_request_feedback[follow_up_needed]": "0" });
  endpointRequest(event, "feedback-patch", "PATCH", `${requestPath}/service_request_feedback`, { authenticity_token: csrfToken(show.body), "service_request_feedback[rating]": "5", "service_request_feedback[feedback]": "PATCH coverage", "service_request_feedback[follow_up_needed]": "0" });
  endpointRequest(event, "feedback-put", "PUT", `${requestPath}/service_request_feedback`, { authenticity_token: csrfToken(show.body), "service_request_feedback[rating]": "5", "service_request_feedback[feedback]": "PUT coverage", "service_request_feedback[follow_up_needed]": "0" });
}

function endpointRequest(event, stage, method, requestPath, body = null, extraOptions = {}) {
  const key = `${event.workflow}:${stage}`;
  const options = { ...tags(event, { endpoint_stage: stage }), ...extraOptions };
  const response = http.request(method, `${targetBaseUrl}${requestPath}`, body, options);
  recordEndpoint(key, response, event);
  check(response, { [`${method} ${requestPath} returned below 400`]: (result) => result.status < 400 });
  return response;
}

function firstResourcePath(html, resource) { return firstMatchingPath(html, new RegExp(`/${resource}/[0-9a-f-]+`)); }
function firstMatchingPath(html, pattern) { const match = String(html).match(pattern); return match ? match[0] : null; }
function findEvidenceThumbnail(event, requestIndexHtml, firstResponse) {
  const pattern = /\/service_request_evidence_files\/[0-9a-f-]+\/thumbnail/;
  const first = firstMatchingPath(firstResponse.body, pattern);
  if (first) return first;

  const requestPaths = [...new Set(String(requestIndexHtml).match(/\/service_requests\/[0-9a-f-]+/g) || [])].slice(0, 20);
  for (const requestPath of requestPaths) {
    const response = http.get(`${targetBaseUrl}${requestPath}`, tags(event, { endpoint_stage: "evidence-discovery" }));
    const thumbnail = firstMatchingPath(response.body, pattern);
    if (thumbnail) return thumbnail;
  }

  return null;
}
function firstFormOption(html, fieldName) {
  const escapedName = fieldName.replace(/[\[\]]/g, "\\$&");
  const select = String(html).match(new RegExp(`<select[^>]+name="${escapedName}"[\\s\\S]*?</select>`));
  const option = select?.[0].match(/<option value="([0-9a-f-]+)"/);
  return option ? option[1] : "";
}
function resourceId(resourcePath) { return String(resourcePath || "").split("/").filter(Boolean).at(-1); }
function locationPath(response) { const location = response.headers.Location || response.headers.location || ""; return location.startsWith(targetBaseUrl) ? location.slice(targetBaseUrl.length) : location; }

function createServiceRequestNote(event, detailPath, detailResponse) {
  const token = csrfToken(detailResponse.body);
  const attributes = noteAttributes(event);

  check(token, {
    "service request note form included CSRF token": (value) => Boolean(value)
  });

  if (!token) return;

  const response = http.post(
    `${targetBaseUrl}${serviceRequestNotesPath(detailPath)}`,
    {
      authenticity_token: token,
      "service_request_note[note_type]": attributes.noteType,
      "service_request_note[visibility]": attributes.visibility,
      "service_request_note[body]": `Workload ${event.workflow} update ${event.seed}-${event.vu}-${event.iteration}.`
    },
    tags(event, { write: "true" })
  );
  recordEndpoint(`${event.workflow}:write`, response, event);

  check(response, {
    "service request note POST succeeded": (result) => result.status === 200,
    "service request note was persisted": (result) => result.body.includes("Service request note added.")
  });
}

function noteAttributes(event) {
  const attributesByRole = {
    dispatcher: { noteType: "general", visibility: "internal" },
    facilityManager: { noteType: "customer_update", visibility: "customer_visible" },
    customerContact: { noteType: "customer_update", visibility: "customer_visible" },
    serviceProviderUser: { noteType: "provider_update", visibility: "provider_visible" }
  };

  return attributesByRole[event.actorRole];
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
    },
    coverage: coverageMetrics(data)
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
  recordEndpoint("authentication:login-page", loginResponse);
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
  recordEndpoint("authentication:login", response);

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

function buildEndpointDefinitions() {
  const definitions = [
    { key: "authentication:login-page", workflow: "authentication", stage: "login-page", method: "GET", pathTemplate: "/login" },
    { key: "authentication:login", workflow: "authentication", stage: "login", method: "POST", pathTemplate: "/login" }
  ];

  for (const [workflow, definition] of Object.entries(profile.workflows)) {
    if (definition.type === "full-endpoint-exercise") {
      definitions.push(...fullEndpointDefinitions(workflow));
      continue;
    }

    definitions.push({
      key: `${workflow}:primary`,
      workflow,
      stage: "primary",
      method: "GET",
      pathTemplate: workflowPaths[definition.type]
    });

    if (["service-request-detail", "service-request-note-create"].includes(definition.type)) {
      definitions.push({ key: `${workflow}:detail`, workflow, stage: "detail", method: "GET", pathTemplate: "/service_requests/:id" });
    }

    if (definition.type === "service-request-note-create") {
      definitions.push({ key: `${workflow}:write`, workflow, stage: "write", method: "POST", pathTemplate: "/service_requests/:id/service_request_notes" });
    }
  }

  return definitions;
}

function fullEndpointDefinitions(workflow) {
  const definitions = [
    ["root", "GET", "/"], ["health", "GET", "/health"], ["up", "GET", "/up"], ["dashboard", "GET", "/dashboard"],
    ["customers-index", "GET", "/customers"], ["customers-new", "GET", "/customers/new"], ["customers-create", "POST", "/customers"], ["customers-show", "GET", "/customers/:id"], ["customers-edit", "GET", "/customers/:id/edit"], ["customers-patch", "PATCH", "/customers/:id"], ["customers-put", "PUT", "/customers/:id"],
    ["sites-index", "GET", "/customer_sites"], ["sites-new", "GET", "/customer_sites/new"], ["sites-create", "POST", "/customer_sites"], ["sites-show", "GET", "/customer_sites/:id"], ["sites-edit", "GET", "/customer_sites/:id/edit"], ["sites-patch", "PATCH", "/customer_sites/:id"], ["sites-put", "PUT", "/customer_sites/:id"],
    ["providers-index", "GET", "/service_providers"], ["providers-new", "GET", "/service_providers/new"], ["providers-create", "POST", "/service_providers"], ["providers-show", "GET", "/service_providers/:id"], ["providers-edit", "GET", "/service_providers/:id/edit"], ["providers-patch", "PATCH", "/service_providers/:id"], ["providers-put", "PUT", "/service_providers/:id"],
    ["requests-index", "GET", "/service_requests"], ["requests-new", "GET", "/service_requests/new"], ["requests-show-seeded", "GET", "/service_requests/:id"], ["requests-new-context", "GET", "/service_requests/new?customer_site_id=:id"], ["requests-create", "POST", "/service_requests"], ["requests-show", "GET", "/service_requests/:id"], ["requests-edit", "GET", "/service_requests/:id/edit"], ["requests-patch", "PATCH", "/service_requests/:id"], ["requests-put", "PUT", "/service_requests/:id"], ["requests-follow-up", "GET", "/service_requests/:id/new_follow_up"], ["requests-triage", "PATCH", "/service_requests/:id/triage"], ["requests-assign", "PATCH", "/service_requests/:id/assign"], ["requests-respond", "PATCH", "/service_requests/:id/respond"], ["requests-verify", "PATCH", "/service_requests/:id/verify_completion"],
    ["quotes-create", "POST", "/service_requests/:id/service_request_quote"], ["quotes-approve", "PATCH", "/service_requests/:id/service_request_quote/approve"], ["quotes-patch", "PATCH", "/service_requests/:id/service_request_quote"], ["quotes-put", "PUT", "/service_requests/:id/service_request_quote"], ["quotes-reject", "PATCH", "/service_requests/:id/service_request_quote/reject"],
    ["costs-create", "POST", "/service_requests/:id/service_request_costs"], ["costs-edit", "GET", "/service_requests/:id/service_request_costs/:cost_id/edit"], ["costs-patch", "PATCH", "/service_requests/:id/service_request_costs/:cost_id"], ["costs-put", "PUT", "/service_requests/:id/service_request_costs/:cost_id"],
    ["notes-create", "POST", "/service_requests/:id/service_request_notes"], ["feedback-create", "POST", "/service_requests/:id/service_request_feedback"], ["feedback-patch", "PATCH", "/service_requests/:id/service_request_feedback"], ["feedback-put", "PUT", "/service_requests/:id/service_request_feedback"],
    ["evidence-show", "GET", "/service_request_evidence_files/:id"], ["evidence-thumbnail", "GET", "/service_request_evidence_files/:id/thumbnail"], ["dispatchers-show", "GET", "/dispatchers/:id"], ["admin-permissions", "GET", "/admin/permission-matrix"], ["admin-assignments", "GET", "/admin/role-assignments"], ["admin-users", "GET", "/admin/users"], ["logout", "DELETE", "/logout"]
  ];
  return definitions.map(([stage, method, pathTemplate]) => ({ key: `${workflow}:${stage}`, workflow, stage, method, pathTemplate }));
}

function recordEndpoint(key, response, event = null) {
  const counters = endpointCounters[key];
  if (!counters) return;

  const endpointTags = event ? tags(event).tags : { workflow: "authentication" };
  counters.requests.add(1, endpointTags);
  if (response.status < 200 || response.status >= 400) counters.failures.add(1, endpointTags);
}

function coverageMetrics(data) {
  return {
    endpoints: endpointDefinitions.map((endpoint) => ({
      ...endpoint,
      requests: data.metrics[`workload_endpoint_${metricSlug(endpoint.key)}_requests`]?.values?.count || 0,
      failures: data.metrics[`workload_endpoint_${metricSlug(endpoint.key)}_failures`]?.values?.count || 0
    })),
    workflowSequences: profile.workflowSequences || []
  };
}
