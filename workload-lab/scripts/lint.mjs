import { spawnSync } from "node:child_process";
import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

const ROOT = new URL("..", import.meta.url);
const CHECKED_DIRECTORIES = ["lib", "scenarios", "scripts", "test", "workflows"];

const files = [];

for (const directory of CHECKED_DIRECTORIES) {
  await collectMjsFiles(new URL(`${directory}/`, ROOT), files);
}

for (const file of files) {
  const source = await readFile(file, "utf8");

  const uncontrolledRandomCall = ["Math", "random("].join(".");

  if (source.includes(uncontrolledRandomCall)) {
    throw new Error(`Uncontrolled randomness is not allowed in workload-lab code: ${file.pathname}`);
  }

  const result = spawnSync(process.execPath, ["--check", file.pathname], { stdio: "inherit" });
  if (result.status !== 0) {
    process.exit(result.status);
  }
}

console.log(`Workload lint passed: ${files.length} JavaScript files inspected.`);

async function collectMjsFiles(directoryUrl, output) {
  let entries;

  try {
    entries = await readdir(directoryUrl, { withFileTypes: true });
  } catch (error) {
    if (error.code === "ENOENT") {
      return;
    }

    throw error;
  }

  for (const entry of entries) {
    const entryUrl = new URL(entry.name, ensureTrailingSlash(directoryUrl));

    if (entry.isDirectory()) {
      await collectMjsFiles(new URL(`${entry.name}/`, ensureTrailingSlash(directoryUrl)), output);
    } else if (entry.isFile() && path.extname(entry.name) === ".mjs") {
      output.push(entryUrl);
    }
  }
}

function ensureTrailingSlash(url) {
  return new URL(url.pathname.endsWith("/") ? url.pathname : `${url.pathname}/`, url);
}
