import { createReadStream, statSync } from "node:fs";
import { createServer } from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const port = Number(process.env.WORKLOAD_DASHBOARD_PORT || 4173);
const types = { ".css": "text/css; charset=utf-8", ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".mjs": "text/javascript; charset=utf-8" };

createServer((request, response) => {
  const pathname = new URL(request.url, "http://localhost").pathname;
  if (pathname === "/") {
    response.writeHead(302, { Location: "/dashboard/" });
    response.end();
    return;
  }

  const requested = pathname === "/dashboard/" ? "dashboard/index.html" : pathname.slice(1);
  const filePath = path.resolve(root, requested);

  if (!filePath.startsWith(`${root}${path.sep}`)) return respond(response, 403, "Forbidden");

  try {
    if (!statSync(filePath).isFile()) return respond(response, 404, "Not found");
    response.writeHead(200, { "Content-Type": types[path.extname(filePath)] || "application/octet-stream", "Cache-Control": "no-store" });
    createReadStream(filePath).pipe(response);
  } catch { respond(response, 404, "Not found"); }
}).listen(port, "127.0.0.1", () => console.log(`Workload dashboard: http://127.0.0.1:${port}`));

function respond(response, status, message) { response.writeHead(status, { "Content-Type": "text/plain; charset=utf-8" }); response.end(message); }
