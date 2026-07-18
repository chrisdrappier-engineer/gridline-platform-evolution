import {
  deterministicChoice,
  deterministicWeightedChoice
} from "./deterministic-random.mjs";

export const MAX_SEED_LENGTH = 128;

export function generatePlan(profile, { seed, vus, iterations }) {
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

export function eventFor(profile, { seed, vu, iteration, cycleTimeBuckets = false }) {
  assertValidSeed(seed);

  const bucket = bucketForIteration(profile, iteration, { cycle: cycleTimeBuckets });
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
    actorRole: workflow.actorRole || "dispatcher",
    actor: actorForWorkflow(profile, workflow, seed, vu, iteration, workflowName),
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

export function bucketForIteration(profile, iteration, { cycle = false } = {}) {
  const effectiveIteration = cycle ? iteration % totalBucketIterations(profile) : iteration;
  let cursor = 0;

  for (const bucket of profile.timeBuckets) {
    cursor += bucket.iterations;
    if (effectiveIteration < cursor) {
      return bucket;
    }
  }

  return profile.timeBuckets.at(-1);
}

function totalBucketIterations(profile) {
  return profile.timeBuckets.reduce((sum, bucket) => sum + bucket.iterations, 0);
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

function actorForWorkflow(profile, workflow, seed, vu, iteration, workflowName) {
  const actorRole = workflow.actorRole || "dispatcher";
  const actors = profile.actors[actorRole];

  return deterministicChoice(actors, seed, vu, iteration, workflowName, "actor");
}
