import { createReadStream, statSync, watch } from "node:fs";
import { createServer } from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { discoverArchive, readArchiveRun, SERIES_SUMMARY_SUFFIX } from "../lib/dashboard-archive.mjs";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const archivePath = path.join(root, "archive");
const port = Number(process.env.WORKLOAD_DASHBOARD_PORT || 4173);
const types = { ".css": "text/css; charset=utf-8", ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".mjs": "text/javascript; charset=utf-8" };
const eventClients = new Set();
let watchTimer;
let pollTimer;
let archiveSignature = "";
let knownRunIds = new Set();

const server = createServer(async (request, response) => {
  const pathname = new URL(request.url, "http://localhost").pathname;
  if (pathname === "/") {
    response.writeHead(302, { Location: "/dashboard/" });
    response.end();
    return;
  }

  if (pathname === "/api/runs") {
    return json(response, 200, await discoverArchive(archivePath));
  }

  if (pathname.startsWith("/api/runs/")) {
    try {
      const filename = decodeURIComponent(pathname.slice("/api/runs/".length));
      return json(response, 200, await readArchiveRun(archivePath, filename));
    } catch (error) {
      return json(response, error.code === "ENOENT" ? 404 : 400, { error: error.message });
    }
  }

  if (pathname === "/api/events") {
    response.writeHead(200, { "Content-Type": "text/event-stream", "Cache-Control": "no-store", Connection: "keep-alive" });
    response.write("event: connected\ndata: {}\n\n");
    eventClients.add(response);
    request.on("close", () => eventClients.delete(response));
    return;
  }

  const requested = pathname === "/dashboard/" ? "dashboard/index.html" : pathname.slice(1);
  const filePath = path.resolve(root, requested);

  if (!allowedStaticPath(requested) || !filePath.startsWith(`${root}${path.sep}`)) return respond(response, 403, "Forbidden");

  try {
    if (!statSync(filePath).isFile()) return respond(response, 404, "Not found");
    response.writeHead(200, { "Content-Type": types[path.extname(filePath)] || "application/octet-stream", "Cache-Control": "no-store" });
    createReadStream(filePath).pipe(response);
  } catch { respond(response, 404, "Not found"); }
});

server.listen(port, "127.0.0.1", () => console.log(`Workload dashboard: http://127.0.0.1:${port}`));

const archiveWatcher = watch(archivePath, (_eventType, filename) => {
  if (!filename?.endsWith(SERIES_SUMMARY_SUFFIX)) return;
  clearTimeout(watchTimer);
  watchTimer = setTimeout(refreshArchiveSignature, 300);
});
archiveWatcher.on("error", (error) => {
  console.warn(`Archive watch unavailable (${error.code}); using polling.`);
  startArchivePolling();
});
refreshArchiveSignature(false);

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    archiveWatcher.close();
    clearInterval(pollTimer);
    server.close(() => process.exit(0));
  });
}

function respond(response, status, message) { response.writeHead(status, { "Content-Type": "text/plain; charset=utf-8" }); response.end(message); }
function json(response, status, value) { response.writeHead(status, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" }); response.end(JSON.stringify(value)); }
function allowedStaticPath(requested) { return requested.startsWith("dashboard/") || ["lib/dashboard-summary.mjs", "lib/comparability.mjs"].includes(requested); }
function broadcastArchiveChange() { for (const client of eventClients) client.write("event: archive-changed\ndata: {}\n\n"); }

async function refreshArchiveSignature(notify = true) {
  try {
    const archive = await discoverArchive(archivePath);
    if (archive.rejected.some((item) => knownRunIds.has(item.filename))) return;

    const nextSignature = JSON.stringify(archive.runs.map((run) => [run.id, run.summary.metadata.generatedAt]));
    const changed = archiveSignature && archiveSignature !== nextSignature;
    archiveSignature = nextSignature;
    knownRunIds = new Set(archive.runs.map((run) => run.id));
    if (notify && changed) broadcastArchiveChange();
  } catch (error) {
    console.warn(`Archive refresh failed: ${error.message}`);
  }
}

function startArchivePolling() {
  if (pollTimer) return;
  pollTimer = setInterval(refreshArchiveSignature, 2000);
}
