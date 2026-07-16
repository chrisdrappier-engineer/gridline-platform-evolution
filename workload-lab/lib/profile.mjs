const REQUIRED_TOP_LEVEL_FIELDS = [
  "schemaVersion",
  "scenarioId",
  "profileId",
  "resourceEnvelope",
  "seedDataProfile",
  "actors",
  "k6",
  "timeBuckets",
  "workflows"
];

export const REGISTERED_WORKFLOW_TYPES = new Set([
  "dashboard",
  "service-request-index",
  "service-request-detail",
  "site-index"
]);

export function validateProfile(profile) {
  const errors = [];

  for (const field of REQUIRED_TOP_LEVEL_FIELDS) {
    if (profile[field] === undefined || profile[field] === null) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  if (profile.schemaVersion !== 1) {
    errors.push("schemaVersion must be 1.");
  }

  validateK6(profile.k6, errors);
  validateActors(profile.actors, errors);
  validateWorkflows(profile.workflows, errors);
  validateTimeBuckets(profile.timeBuckets, profile.workflows, errors);

  return errors;
}

export function assertValidProfile(profile) {
  const errors = validateProfile(profile);

  if (errors.length > 0) {
    throw new Error(`Invalid workload profile:\n- ${errors.join("\n- ")}`);
  }

  return profile;
}

function validateK6(k6, errors) {
  if (!isObject(k6)) {
    errors.push("k6 must be an object.");
    return;
  }

  if (!Number.isInteger(k6.vus) || k6.vus < 1) {
    errors.push("k6.vus must be a positive integer.");
  }

  if (!Number.isInteger(k6.iterations) || k6.iterations < 1) {
    errors.push("k6.iterations must be a positive integer.");
  }

  if (!isObject(k6.thresholds)) {
    errors.push("k6.thresholds must be an object.");
  }
}

function validateActors(actors, errors) {
  if (!isObject(actors)) {
    errors.push("actors must be an object.");
    return;
  }

  for (const [role, roleActors] of Object.entries(actors)) {
    if (!Array.isArray(roleActors) || roleActors.length === 0) {
      errors.push(`actors.${role} must be a non-empty array.`);
      continue;
    }

    roleActors.forEach((actor, index) => {
      if (!actor.email || !actor.password) {
        errors.push(`actors.${role}[${index}] must include email and password.`);
      }
    });
  }
}

function validateWorkflows(workflows, errors) {
  if (!isObject(workflows)) {
    errors.push("workflows must be an object.");
    return;
  }

  for (const [name, workflow] of Object.entries(workflows)) {
    if (!REGISTERED_WORKFLOW_TYPES.has(workflow.type)) {
      errors.push(`workflows.${name}.type is not registered: ${workflow.type}`);
    }

    if (workflow.bounds !== undefined && !isObject(workflow.bounds)) {
      errors.push(`workflows.${name}.bounds must be an object when present.`);
    }
  }
}

function validateTimeBuckets(timeBuckets, workflows, errors) {
  if (!Array.isArray(timeBuckets) || timeBuckets.length === 0) {
    errors.push("timeBuckets must be a non-empty array.");
    return;
  }

  timeBuckets.forEach((bucket, index) => {
    if (!bucket.name) {
      errors.push(`timeBuckets[${index}] must include a name.`);
    }

    if (!Number.isInteger(bucket.iterations) || bucket.iterations < 1) {
      errors.push(`timeBuckets[${index}].iterations must be a positive integer.`);
    }

    if (!isObject(bucket.workflowMix)) {
      errors.push(`timeBuckets[${index}].workflowMix must be an object.`);
      return;
    }

    for (const [workflowName, weight] of Object.entries(bucket.workflowMix)) {
      if (!workflows || !workflows[workflowName]) {
        errors.push(`timeBuckets[${index}] references unknown workflow: ${workflowName}`);
      }

      if (Number(weight) <= 0) {
        errors.push(`timeBuckets[${index}].workflowMix.${workflowName} must be positive.`);
      }
    }
  });
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
