import assert from "node:assert/strict";
import test from "node:test";

import { compareEvidence, evidenceAssessment, planDigest, resourceEnvelopeSnapshot } from "../lib/evidence.mjs";

const comparable = {
  profileHash: "profile", textureHash: "texture", seriesHash: "series", planDigest: "plan", seed: "seed",
  resourceEnvelopeSnapshotHash: "envelope", seedDataProfile: "demo", executionModel: "duration-based-sequential-users",
  application: { commit: "app", tag: null, branch: "main", dirty: false },
  workloadTooling: { commit: "tooling", tag: null, branch: "main", dirty: false }
};

test("plan digest is deterministic and seed-sensitive", () => {
  assert.equal(planDigest({ profileHash: "a", seriesHash: "b", seed: "c" }), planDigest({ profileHash: "a", seriesHash: "b", seed: "c" }));
  assert.notEqual(planDigest({ profileHash: "a", seriesHash: "b", seed: "c" }), planDigest({ profileHash: "a", seriesHash: "b", seed: "d" }));
});

test("resource envelope snapshot is stable", () => {
  assert.deepEqual(resourceEnvelopeSnapshot("small", {}), resourceEnvelopeSnapshot("small", {}));
});

test("classifies complete clean evidence as comparable", () => {
  assert.equal(evidenceAssessment(comparable).status, "comparable");
});

test("classifies tagged evidence as promoted-ready", () => {
  const tagged = { ...comparable, application: { ...comparable.application, tag: "app-v1" }, workloadTooling: { ...comparable.workloadTooling, tag: "workload-v1" } };
  assert.equal(evidenceAssessment(tagged).status, "promoted-ready");
});

test("classifies dirty evidence as exploratory", () => {
  assert.equal(evidenceAssessment({ ...comparable, workloadTooling: { ...comparable.workloadTooling, dirty: true } }).status, "exploratory");
});

test("compares required evidence dimensions", () => {
  assert.equal(compareEvidence(comparable, comparable).status, "comparable");
  assert.deepEqual(compareEvidence(comparable, { ...comparable, seed: "different" }), { status: "partial", differences: ["workload seed differs"] });
});
