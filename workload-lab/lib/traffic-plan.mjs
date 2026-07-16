import {
  deterministicChoice,
  deterministicWeightedChoice
} from "./deterministic-random.mjs";
import { assertValidProfile } from "./profile.mjs";

export const MAX_SEED_LENGTH = 128;

export function generatePlan(profile, { seed, vus, iterations }) {
  assertValidProfile(profile);
  assertValidSeed(seed);

  const events = [];
  const vuCount = vus || profile.k6.vus;
  const iterationCount = iterations || profile.k6.iterations;

  for (let vu = 1; vu <= vuCount; vu += 1) {
    for (let iteration = 0; iteration < iterationCount; iteration += 1) {
      events.push(eventFor(profile, { seed, vu, iteration }));
    }
  }

  return events;
}

export function eventFor(profile, { seed, vu, iteration }) {
  assertValidProfile(profile);
  assertValidSeed(seed);

  const bucket = bucketForIteration(profile, iteration);
  const workflowName = deterministicWeightedChoice(bucket.workflowMix, seed, vu, iteration, "workflow");
  const workflow = profile.workflows[workflowName];

  return {
    scenarioId: profile.scenarioId,
    profileId: profile.profileId,
    seed,
    vu,
    iteration,
    timeBucket: bucket.name,
    workflow: workflowName,
    type: workflow.type,
    params: paramsForWorkflow(workflow, seed, vu, iteration, workflowName)
  };
}

export function assertValidSeed(seed) {
  if (typeof seed !== "string" || seed.trim().length === 0) {
    throw new Error("Workload seed must be a non-empty string.");
  }

  if (seed.length > MAX_SEED_LENGTH) {
    throw new Error(`Workload seed must be ${MAX_SEED_LENGTH} characters or fewer.`);
  }

  return seed;
}

export function bucketForIteration(profile, iteration) {
  let cursor = 0;

  for (const bucket of profile.timeBuckets) {
    cursor += bucket.iterations;
    if (iteration < cursor) {
      return bucket;
    }
  }

  return profile.timeBuckets.at(-1);
}

function paramsForWorkflow(workflow, seed, vu, iteration, workflowName) {
  const bounds = workflow.bounds || {};
  const params = {};

  for (const [key, values] of Object.entries(bounds)) {
    if (Array.isArray(values)) {
      params[key] = deterministicChoice(values, seed, vu, iteration, workflowName, key);
    }
  }

  return params;
}
