import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

import { parseSeriesSummary } from "./dashboard-summary.mjs";

export const SERIES_SUMMARY_SUFFIX = ".series-summary.json";

export async function discoverArchive(archivePath) {
  const entries = await readdir(archivePath, { withFileTypes: true });
  const candidates = entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(SERIES_SUMMARY_SUFFIX))
    .map((entry) => entry.name)
    .sort();
  const settled = await Promise.all(candidates.map((filename) => readArchiveRun(archivePath, filename).then(
    (run) => ({ run }),
    (error) => ({ rejected: { filename, reason: error.message } })
  )));

  const runs = settled.flatMap((result) => result.run ? [result.run] : []);
  const rejected = settled.flatMap((result) => result.rejected ? [result.rejected] : []);
  runs.sort((left, right) => right.summary.metadata.generatedAt.localeCompare(left.summary.metadata.generatedAt));
  return { runs, rejected };
}

export async function readArchiveRun(archivePath, filename) {
  assertSeriesFilename(filename);
  const summary = parseSeriesSummary(await readFile(path.join(archivePath, filename), "utf8"), filename);
  const metadata = summary.metadata;

  return {
    id: filename,
    filename,
    displayName: `${humanize(metadata.profileId)} — ${humanize(metadata.seriesName)}`,
    summary
  };
}

export function assertSeriesFilename(filename) {
  if (path.basename(filename) !== filename || !filename.endsWith(SERIES_SUMMARY_SUFFIX)) {
    throw new Error("Run identifier must be a series-summary filename.");
  }
}

export function humanize(value) {
  return String(value || "")
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/[-_]+/g, " ")
    .trim()
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}
