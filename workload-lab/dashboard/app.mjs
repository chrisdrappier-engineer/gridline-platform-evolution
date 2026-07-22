import { compareSeriesSummaries, comparisonAgainst, eventsPerSecond, groupedComposition, provenancePresentation } from "../lib/dashboard-summary.mjs";

const state = { runs: [], selectedId: null, baselineId: null, candidateId: null };
const elements = {
  refresh: document.querySelector("#refresh-runs"),
  search: document.querySelector("#run-search"), list: document.querySelector("#run-list"), detail: document.querySelector("#run-detail"),
  loadSummary: document.querySelector("#load-summary"), toast: document.querySelector("#toast")
};

elements.refresh.addEventListener("click", loadRuns);
elements.search.addEventListener("input", renderRunList);
loadRuns();
connectArchiveEvents();

async function loadRuns() {
  elements.refresh.disabled = true;
  try {
    const response = await fetch("/api/runs", { cache: "no-store" });
    if (!response.ok) throw new Error(`Archive request failed with HTTP ${response.status}.`);
    const archive = await response.json();
    state.runs = archive.runs.map((run) => ({ ...run, sourceName: run.filename, generatedAt: new Date(run.summary.metadata.generatedAt), legacySchema: run.summary.schemaVersion === undefined }));
    if (!state.runs.some((run) => run.id === state.selectedId)) state.selectedId = state.runs[0]?.id || null;
    if (!state.runs.some((run) => run.id === state.candidateId)) state.candidateId = state.selectedId;
    if (!state.runs.some((run) => run.id === state.baselineId)) state.baselineId = firstCandidateId(state.candidateId);
    elements.loadSummary.textContent = `${state.runs.length} runs${archive.rejected.length ? ` · ${archive.rejected.length} rejected` : ""}`;
    if (archive.rejected.length) showError(archive.rejected.map((item) => `${item.filename}: ${item.reason}`).join(" "));
    renderRunList();
    if (state.selectedId) renderDetail(); else renderEmptyDetail();
  } catch (error) {
    elements.loadSummary.textContent = "Archive unavailable";
    showError(error.message);
  } finally {
    elements.refresh.disabled = false;
  }
}

function connectArchiveEvents() {
  const events = new EventSource("/api/events");
  events.addEventListener("archive-changed", loadRuns);
}

function renderRunList() {
  const query = elements.search.value.trim().toLowerCase();
  const visible = state.runs.filter((run) => JSON.stringify(run.summary.metadata).toLowerCase().includes(query));
  elements.list.replaceChildren(...visible.map((run) => {
    const item = document.createElement("li");
    const button = document.createElement("button");
    button.type = "button"; button.dataset.runId = run.id; button.ariaCurrent = run.id === state.selectedId ? "true" : "false";
    const title = document.createElement("strong"); title.textContent = run.displayName;
    const status = humanize(run.summary.metadata.status || "completed");
    const meta = document.createElement("span"); meta.textContent = `${humanize(run.summary.metadata.resourceEnvelope)} · ${formatDate(run.generatedAt)} · ${status}`;
    button.append(title, meta);
    if (run.legacySchema) { const flag = document.createElement("span"); flag.className = "schema-flag"; flag.textContent = "Legacy unversioned summary"; button.append(flag); }
    button.addEventListener("click", () => { state.selectedId = run.id; state.candidateId = run.id; state.baselineId = firstCandidateId(run.id); renderRunList(); renderDetail(); });
    item.append(button); return item;
  }));
}

function renderEmptyDetail() {
  elements.detail.innerHTML = `<div class="detail-empty"><p class="eyebrow">No evidence found</p><h1>Run a workload series to add evidence.</h1></div>`;
}

function renderDetail() {
  const run = state.runs.find((candidate) => candidate.id === state.selectedId);
  if (!run) return;
  const { metadata, steps } = run.summary;
  const finalStep = steps.at(-1);
  const peakP95 = Math.max(...steps.map((step) => numeric(step.metrics.httpReqDurationP95)));
  const peakThroughput = Math.max(...steps.map((step) => eventsPerSecond(step) || 0));
  const lowestChecks = Math.min(...steps.map((step) => numeric(step.metrics.checksRate, 1)));
  elements.detail.innerHTML = `
    <header class="detail-header"><div><p class="eyebrow">${escapeHtml(metadata.scenarioId)}</p><h1>${escapeHtml(metadata.seriesName)}</h1><p class="description">${escapeHtml(metadata.seriesDescription || "Duration-based workload series")}</p></div><p class="run-stamp">${escapeHtml(metadata.resourceEnvelope)}<br>${formatDate(run.generatedAt)}<br>${shortHash(metadata.appCommit)}</p></header>
    <section class="metric-strip" aria-label="Series summary"><div class="metric"><span>Peak p95 latency</span><strong>${formatMs(peakP95)}</strong><small>Across all steps</small></div><div class="metric"><span>Peak throughput</span><strong>${peakThroughput.toFixed(1)}/s</strong><small>Workload events</small></div><div class="metric"><span>Lowest checks</span><strong>${formatPercent(lowestChecks)}</strong><small>Correctness, not HTTP status</small></div><div class="metric"><span>Final load</span><strong>${finalStep.vus} VUs</strong><small>${escapeHtml(finalStep.duration)}</small></div></section>
    <section class="chart-grid"><div class="panel"><h2>Latency under load</h2><p>p95 and average response time by virtual users</p><canvas id="latency-chart" role="img" aria-label="Latency line chart"></canvas></div><div class="panel"><h2>Throughput under load</h2><p>Completed workload events per second</p><canvas id="throughput-chart" role="img" aria-label="Throughput line chart"></canvas></div></section>
    ${evidenceSection(metadata, run)}${comparisonSection()}${stepTable(steps)}${compositionSection(finalStep)}${provenanceSection(run)}
  `;
  wireComparisonControls();
  drawChart(document.querySelector("#latency-chart"), steps.map((step) => ({ x: step.vus, values: [numeric(step.metrics.httpReqDurationP95), numeric(step.metrics.httpReqDurationAvg)] })), ["p95", "average"], ["#111111", "#888888"], "ms");
  drawChart(document.querySelector("#throughput-chart"), steps.map((step) => ({ x: step.vus, values: [eventsPerSecond(step) || 0] })), ["events/s"], ["#111111"], "");
  drawComparisonChart();
}

function evidenceSection(metadata, run) {
  const comparisons = comparisonAgainst(run, state.runs);
  const comparable = comparisons.filter((comparison) => comparison.status === "comparable").length;
  const warnings = [...(metadata.evidenceStatusReasons || []), ...comparisons.flatMap((comparison) => comparison.differences).filter((value, index, values) => values.indexOf(value) === index)];
  return `<section class="data-section"><p class="eyebrow">Evidence quality</p><h2>${humanize(metadata.evidenceStatus || "legacy unknown")}</h2><p>${comparable} archived run${comparable === 1 ? "" : "s"} fully comparable.</p>${warnings.length ? `<ul>${warnings.map((warning) => `<li>${escapeHtml(warning)}</li>`).join("")}</ul>` : "<p>No provenance warnings.</p>"}</section>`;
}

function comparisonSection() {
  if (state.runs.length < 2) return `<section class="data-section"><p class="eyebrow">Before / after</p><h2>Comparison needs at least two runs</h2><p class="note">Run another series summary to compare application versions.</p></section>`;

  const baseline = runById(state.baselineId) || state.runs[0];
  const candidate = runById(state.candidateId) || state.runs.find((run) => run.id !== baseline.id);
  if (!baseline || !candidate) return "";

  state.baselineId = baseline.id;
  state.candidateId = candidate.id;
  const comparison = compareSeriesSummaries(baseline.summary, candidate.summary);
  const statusText = comparison.status === "comparable" ? "Clean comparison" : "Exploratory comparison";
  const warnings = comparison.differences.length ? comparison.differences : ["All required comparison dimensions match."];

  return `<section class="data-section comparison-section"><p class="eyebrow">Before / after</p><h2>Compare application revisions</h2><div class="comparison-controls"><label>Baseline<select id="baseline-run">${runOptions(baseline.id)}</select></label><label>Candidate<select id="candidate-run">${runOptions(candidate.id)}</select></label></div><div class="comparison-status comparison-status-${comparison.status}"><strong>${statusText}</strong><ul>${warnings.map((warning) => `<li>${escapeHtml(warning)}</li>`).join("")}</ul></div><div class="chart-grid comparison-charts"><div class="panel"><h2>p95 latency comparison</h2><p>Baseline and candidate by series step</p><canvas id="comparison-latency-chart" role="img" aria-label="Baseline and candidate p95 latency chart"></canvas></div><div class="panel"><h2>Metric deltas</h2><p>Candidate minus baseline; percentages are relative to baseline.</p>${comparisonTable(comparison)}</div></div></section>`;
}

function comparisonTable(comparison) {
  return `<div class="table-wrap"><table><thead><tr><th>Step</th><th>Metric</th><th>Baseline</th><th>Candidate</th><th>Delta</th><th>Delta %</th></tr></thead><tbody>${comparison.rows.flatMap((row) => row.metrics.map((metric) => `<tr><td>${escapeHtml(row.step)}</td><td>${escapeHtml(metric.label)}</td><td>${formatMetric(metric.baseline, metric.format)}</td><td>${metric.candidate === null ? "Missing" : formatMetric(metric.candidate, metric.format)}</td><td class="${deltaClass(metric)}">${formatSignedMetric(metric.absoluteDelta, metric.format)}</td><td class="${deltaClass(metric)}">${formatSignedPercent(metric.percentDelta)}</td></tr>`)).join("")}</tbody></table></div>`;
}

function wireComparisonControls() {
  const baseline = document.querySelector("#baseline-run");
  const candidate = document.querySelector("#candidate-run");
  if (!baseline || !candidate) return;

  baseline.addEventListener("change", () => {
    state.baselineId = baseline.value;
    if (state.candidateId === state.baselineId) state.candidateId = firstCandidateId(state.baselineId);
    renderDetail();
  });
  candidate.addEventListener("change", () => {
    state.candidateId = candidate.value;
    renderDetail();
  });
}

function drawComparisonChart() {
  const canvas = document.querySelector("#comparison-latency-chart");
  const baseline = runById(state.baselineId);
  const candidate = runById(state.candidateId);
  if (!canvas || !baseline || !candidate) return;

  const candidateSteps = new Map(candidate.summary.steps.map((step, index) => [step.name || `step-${index}`, step]));
  const points = baseline.summary.steps.map((step, index) => {
    const candidateStep = candidateSteps.get(step.name || `step-${index}`) || candidate.summary.steps[index];
    return { x: step.vus, values: [numeric(step.metrics.httpReqDurationP95), numeric(candidateStep?.metrics?.httpReqDurationP95)] };
  });
  drawChart(canvas, points, ["baseline", "candidate"], ["#111111", "#777777"], "ms");
}

function stepTable(steps) {
  return `<section class="data-section"><p class="eyebrow">Exact measurements</p><h2>Load progression</h2><div class="table-wrap"><table><thead><tr><th>Step</th><th>VUs</th><th>Duration</th><th>Events/s</th><th>Avg</th><th>p95</th><th>HTTP failures</th><th>Checks</th></tr></thead><tbody>${steps.map((step) => `<tr><td>${escapeHtml(step.name)}</td><td>${step.vus}</td><td>${escapeHtml(step.duration)}</td><td>${(eventsPerSecond(step) || 0).toFixed(1)}</td><td>${formatMs(step.metrics.httpReqDurationAvg)}</td><td>${formatMs(step.metrics.httpReqDurationP95)}</td><td>${formatPercent(step.metrics.httpReqFailedRate)}</td><td>${formatPercent(step.metrics.checksRate)}</td></tr>`).join("")}</tbody></table></div></section>`;
}

function compositionSection(step) {
  const roles = groupedComposition(step);
  return `<section class="data-section"><p class="eyebrow">Final step</p><h2>Observed workload composition</h2><div class="role-grid">${roles.map((role) => `<article class="role-card"><h3>${humanize(role.role)} · ${role.events}</h3>${role.workflows.sort((a,b) => b.events-a.events).slice(0,5).map((workflow) => `<p><span>${humanize(workflow.name)}</span><strong>${workflow.events}</strong></p>`).join("")}</article>`).join("")}</div></section>`;
}

function provenanceSection(run) {
  const presentation = provenancePresentation(run.summary, run.sourceName);
  return `<section class="data-section"><p class="eyebrow">Reproducibility</p><h2>Evidence provenance</h2>${presentation.legacyNotice ? `<p class="provenance-note">${escapeHtml(presentation.legacyNotice)}</p>` : ""}<h3 class="provenance-heading">Run definition</h3>${fieldList(presentation.definition)}${presentation.revisions.length ? `<h3 class="provenance-heading">Revisions</h3><dl class="provenance">${presentation.revisions.map((field) => `<div><dt>${escapeHtml(field.label)}</dt><dd>${escapeHtml(field.value)}${field.commit ? `<small title="${escapeHtml(field.commit)}">commit ${escapeHtml(field.shortCommit)}</small>` : ""}</dd></div>`).join("")}</dl>` : ""}${presentation.fingerprints.length ? `<details class="fingerprints"><summary>Integrity fingerprints (${presentation.fingerprints.length})</summary>${fieldList(presentation.fingerprints)}</details>` : ""}<dl class="provenance provenance-source"><div><dt>Source</dt><dd>${escapeHtml(presentation.source)}</dd></div><div><dt>Schema</dt><dd>${escapeHtml(presentation.schema)}</dd></div></dl></section>`;
}

function fieldList(fields) {
  return `<dl class="provenance">${fields.map((field) => `<div><dt>${escapeHtml(field.label)}</dt><dd>${escapeHtml(field.value)}${field.description ? `<small>${escapeHtml(field.description)}</small>` : ""}</dd></div>`).join("")}</dl>`;
}

function drawChart(canvas, points, labels, colors, suffix) {
  const ratio = window.devicePixelRatio || 1; const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * ratio; canvas.height = 190 * ratio;
  const context = canvas.getContext("2d"); context.scale(ratio, ratio);
  const width = rect.width; const height = 190; const pad = { top: 24, right: 18, bottom: 35, left: 48 };
  const max = Math.max(1, ...points.flatMap((point) => point.values)) * 1.12;
  context.font = "11px system-ui"; context.fillStyle = "#637069"; context.strokeStyle = "#d8d5ca"; context.lineWidth = 1;
  for (let index = 0; index <= 4; index += 1) { const y = pad.top + ((height-pad.top-pad.bottom)*index/4); const value = max*(1-index/4); context.beginPath(); context.moveTo(pad.left,y); context.lineTo(width-pad.right,y); context.stroke(); context.fillText(`${Math.round(value)}${suffix}`, 2, y+4); }
  const xAt = (index) => points.length === 1 ? pad.left : pad.left + ((width-pad.left-pad.right)*index/(points.length-1));
  labels.forEach((label, seriesIndex) => { context.strokeStyle = colors[seriesIndex]; context.fillStyle = colors[seriesIndex]; context.lineWidth = 2.5; context.beginPath(); points.forEach((point,index) => { const x=xAt(index); const y=pad.top+(height-pad.top-pad.bottom)*(1-point.values[seriesIndex]/max); if(index===0) context.moveTo(x,y); else context.lineTo(x,y); }); context.stroke(); context.fillText(label, pad.left + seriesIndex*72, 11); });
  points.forEach((point,index) => { context.fillStyle="#637069"; context.textAlign="center"; context.fillText(`${point.x} VUs`, xAt(index), height-10); }); context.textAlign="left";
}

function numeric(value, fallback = 0) { const number = Number(value); return Number.isFinite(number) ? number : fallback; }
function formatMs(value) { return `${numeric(value).toFixed(numeric(value) >= 100 ? 0 : 1)} ms`; }
function formatPercent(value) { return `${(numeric(value) * 100).toFixed(2)}%`; }
function formatRate(value) { return `${numeric(value).toFixed(1)}/s`; }
function formatMetric(value, format) {
  if (format === "ms") return formatMs(value);
  if (format === "percent") return formatPercent(value);
  if (format === "rate") return formatRate(value);
  return String(value);
}
function formatSignedMetric(value, format) {
  if (value === null) return "n/a";
  const sign = value > 0 ? "+" : "";
  if (format === "ms") return `${sign}${numeric(value).toFixed(Math.abs(value) >= 100 ? 0 : 1)} ms`;
  if (format === "percent") return `${sign}${(numeric(value) * 100).toFixed(2)} pts`;
  if (format === "rate") return `${sign}${numeric(value).toFixed(1)}/s`;
  return `${sign}${value}`;
}
function formatSignedPercent(value) {
  if (value === null) return "n/a";
  return `${value > 0 ? "+" : ""}${(value * 100).toFixed(2)}%`;
}
function formatDate(value) { return new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short" }).format(value); }
function shortHash(value) { return escapeHtml(String(value || "unknown").slice(0, 10)); }
function humanize(value) { return escapeHtml(String(value).replace(/([a-z])([A-Z])/g, "$1 $2").replace(/[-_]/g, " ").replace(/^./, (letter) => letter.toUpperCase())); }
function escapeHtml(value) { const node = document.createElement("span"); node.textContent = String(value); return node.innerHTML; }
function showError(message) { elements.toast.textContent = message; elements.toast.hidden = false; window.setTimeout(() => { elements.toast.hidden = true; }, 7000); }
function runById(id) { return state.runs.find((run) => run.id === id); }
function firstCandidateId(baselineId) { return state.runs.find((run) => run.id !== baselineId)?.id || null; }
function runOptions(selectedId) {
  return state.runs.map((run) => `<option value="${escapeHtml(run.id)}"${run.id === selectedId ? " selected" : ""}>${escapeHtml(run.displayName)} · ${formatDate(run.generatedAt)} · ${shortHash(run.summary.metadata.appCommit)}</option>`).join("");
}
function deltaClass(metric) {
  if (metric.improvement === null) return "";
  return metric.improvement ? "delta-good" : "delta-bad";
}
