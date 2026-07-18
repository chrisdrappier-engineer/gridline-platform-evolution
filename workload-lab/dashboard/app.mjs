import { eventsPerSecond, groupedComposition, parseSeriesSummary, runRecord } from "../lib/dashboard-summary.mjs";

const state = { runs: [], selectedId: null };
const elements = {
  filePicker: document.querySelector("#add-files"),
  search: document.querySelector("#run-search"), list: document.querySelector("#run-list"), detail: document.querySelector("#run-detail"),
  loadSummary: document.querySelector("#load-summary"), toast: document.querySelector("#toast")
};

elements.filePicker.addEventListener("change", () => loadFiles([...elements.filePicker.files]));
elements.search.addEventListener("input", renderRunList);

async function loadFiles(files) {
  const candidates = files.filter((file) => file.name.endsWith(".series-summary.json"));
  const loaded = [];
  const errors = [];

  await Promise.all(candidates.map(async (file) => {
    try { loaded.push(runRecord(parseSeriesSummary(await file.text(), file.name), file.name)); }
    catch (error) { errors.push(error.message); }
  }));

  const bySource = new Map(state.runs.map((run) => [run.sourceName, run]));
  loaded.forEach((run) => bySource.set(run.sourceName, run));
  state.runs = [...bySource.values()].sort((left, right) => right.generatedAt - left.generatedAt);
  state.selectedId ||= state.runs[0]?.id;
  elements.loadSummary.textContent = `${loaded.length} loaded${errors.length ? ` · ${errors.length} rejected` : ""}`;
  if (errors.length) showError(errors.join(" "));
  if (state.runs.length) {
    renderRunList(); renderDetail();
  } else if (candidates.length === 0) showError("No .series-summary.json files were selected.");
}

function renderRunList() {
  const query = elements.search.value.trim().toLowerCase();
  const visible = state.runs.filter((run) => JSON.stringify(run.summary.metadata).toLowerCase().includes(query));
  elements.list.replaceChildren(...visible.map((run) => {
    const item = document.createElement("li");
    const button = document.createElement("button");
    button.type = "button"; button.dataset.runId = run.id; button.ariaCurrent = run.id === state.selectedId ? "true" : "false";
    const title = document.createElement("strong"); title.textContent = run.summary.metadata.seriesName;
    const meta = document.createElement("span"); meta.textContent = `${run.summary.metadata.resourceEnvelope} · ${formatDate(run.generatedAt)}`;
    button.append(title, meta);
    if (run.legacySchema) { const flag = document.createElement("span"); flag.className = "schema-flag"; flag.textContent = "Legacy unversioned summary"; button.append(flag); }
    button.addEventListener("click", () => { state.selectedId = run.id; renderRunList(); renderDetail(); });
    item.append(button); return item;
  }));
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
    ${stepTable(steps)}${compositionSection(finalStep)}${provenanceSection(metadata, run)}
  `;
  drawChart(document.querySelector("#latency-chart"), steps.map((step) => ({ x: step.vus, values: [numeric(step.metrics.httpReqDurationP95), numeric(step.metrics.httpReqDurationAvg)] })), ["p95", "average"], ["#111111", "#888888"], "ms");
  drawChart(document.querySelector("#throughput-chart"), steps.map((step) => ({ x: step.vus, values: [eventsPerSecond(step) || 0] })), ["events/s"], ["#111111"], "");
}

function stepTable(steps) {
  return `<section class="data-section"><p class="eyebrow">Exact measurements</p><h2>Load progression</h2><div class="table-wrap"><table><thead><tr><th>Step</th><th>VUs</th><th>Duration</th><th>Events/s</th><th>Avg</th><th>p95</th><th>HTTP failures</th><th>Checks</th></tr></thead><tbody>${steps.map((step) => `<tr><td>${escapeHtml(step.name)}</td><td>${step.vus}</td><td>${escapeHtml(step.duration)}</td><td>${(eventsPerSecond(step) || 0).toFixed(1)}</td><td>${formatMs(step.metrics.httpReqDurationAvg)}</td><td>${formatMs(step.metrics.httpReqDurationP95)}</td><td>${formatPercent(step.metrics.httpReqFailedRate)}</td><td>${formatPercent(step.metrics.checksRate)}</td></tr>`).join("")}</tbody></table></div></section>`;
}

function compositionSection(step) {
  const roles = groupedComposition(step);
  return `<section class="data-section"><p class="eyebrow">Final step</p><h2>Observed workload composition</h2><div class="role-grid">${roles.map((role) => `<article class="role-card"><h3>${humanize(role.role)} · ${role.events}</h3>${role.workflows.sort((a,b) => b.events-a.events).slice(0,5).map((workflow) => `<p><span>${humanize(workflow.name)}</span><strong>${workflow.events}</strong></p>`).join("")}</article>`).join("")}</div></section>`;
}

function provenanceSection(metadata, run) {
  const fields = [["Source", run.sourceName], ["Schema", run.legacySchema ? "Legacy / unversioned" : `Version ${run.summary.schemaVersion}`], ["Seed", metadata.seed], ["App commit", metadata.appCommit], ["Tooling commit", metadata.workloadToolingCommit], ["Profile hash", metadata.profileHash], ["Texture hash", metadata.textureHash], ["Series hash", metadata.seriesHash], ["Seed data", metadata.seedDataProfile], ["Execution", metadata.executionModel]];
  return `<section class="data-section"><p class="eyebrow">Reproducibility</p><h2>Evidence provenance</h2><dl class="provenance">${fields.map(([label,value]) => `<div><dt>${label}</dt><dd>${escapeHtml(value || "unknown")}</dd></div>`).join("")}</dl></section>`;
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
function formatDate(value) { return new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short" }).format(value); }
function shortHash(value) { return escapeHtml(String(value || "unknown").slice(0, 10)); }
function humanize(value) { return escapeHtml(String(value).replace(/([a-z])([A-Z])/g, "$1 $2").replace(/[-_]/g, " ").replace(/^./, (letter) => letter.toUpperCase())); }
function escapeHtml(value) { const node = document.createElement("span"); node.textContent = String(value); return node.innerHTML; }
function showError(message) { elements.toast.textContent = message; elements.toast.hidden = false; window.setTimeout(() => { elements.toast.hidden = true; }, 7000); }
