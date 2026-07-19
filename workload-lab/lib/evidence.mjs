import { spawnSync } from "node:child_process";

import { stableJsonHash } from "./series.mjs";
export { compareEvidence } from "./comparability.mjs";

export function gitContext({ commit, tag, branch, dirty } = {}) {
  const resolvedCommit = commit || gitValue(["rev-parse", "HEAD"]);

  return {
    commit: resolvedCommit,
    tag: tag ?? gitValue(["describe", "--tags", "--exact-match", resolvedCommit]),
    branch: branch ?? gitValue(["branch", "--show-current"]),
    dirty: dirty ?? gitDirty()
  };
}

export function resourceEnvelopeSnapshot(name, environment = process.env) {
  const snapshot = {
    name,
    app: {
      cpus: environment.PRODUCTION_APP_CPUS || "1.0",
      memory: environment.PRODUCTION_APP_MEMORY || "768m",
      maxThreads: environment.RAILS_MAX_THREADS || "5",
      webConcurrency: environment.WEB_CONCURRENCY || "1"
    },
    database: {
      cpus: environment.PRODUCTION_DB_CPUS || "1.0",
      memory: environment.PRODUCTION_DB_MEMORY || "768m"
    }
  };

  return { ...snapshot, hash: stableJsonHash(snapshot) };
}

export function planDigest({ profileHash, seriesHash, seed }) {
  return stableJsonHash({
    profileHash,
    seriesHash,
    seed,
    executionModel: "duration-based-sequential-users",
    cumulativeSteps: true
  });
}

export function evidenceAssessment(metadata) {
  const comparableRequirements = [
    "profileHash", "textureHash", "seriesHash", "planDigest", "seed",
    "resourceEnvelopeSnapshotHash", "seedDataProfile", "executionModel"
  ];
  const missing = comparableRequirements.filter((field) => !metadata[field]);
  const dirty = [metadata.application, metadata.workloadTooling].some((context) => context?.dirty !== false);
  const untagged = [metadata.application, metadata.workloadTooling].filter((context) => !context?.tag);

  if (missing.length > 0 || dirty) {
    return {
      status: "exploratory",
      reasons: [...missing.map((field) => `missing ${field}`), ...(dirty ? ["application or tooling worktree is dirty or unknown"] : [])]
    };
  }

  if (untagged.length > 0) {
    return { status: "comparable", reasons: ["exact application and tooling tags required for promotion"] };
  }

  return { status: "promoted-ready", reasons: [] };
}

function gitValue(args) {
  const result = spawnSync("git", args, { encoding: "utf8" });
  return result.status === 0 ? result.stdout.trim() || null : null;
}

function gitDirty() {
  const result = spawnSync("git", ["status", "--porcelain"], { encoding: "utf8" });
  return result.status === 0 ? result.stdout.trim().length > 0 : null;
}
