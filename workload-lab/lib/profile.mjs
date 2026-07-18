import { readFileSync } from "node:fs";

import Ajv from "ajv";

const PROFILE_SCHEMA_URL = new URL("../schemas/profile.schema.json", import.meta.url);
const profileSchema = JSON.parse(readFileSync(PROFILE_SCHEMA_URL, "utf8"));
const ajv = new Ajv({ allErrors: true, allowUnionTypes: true, strict: true, strictRequired: false });
const validateProfileShape = ajv.compile(profileSchema);

export function validateProfile(profile, { workflowPaths } = {}) {
  const errors = validateProfileSchema(profile);

  if (errors.length > 0) {
    return errors;
  }

  return [
    ...validateWorkflows(profile.workflows, profile.actors, workflowPaths),
    ...validateTimeBuckets(profile.timeBuckets, profile.workflows),
    ...validateSeries(profile.series)
  ];
}

export function assertValidProfile(profile) {
  const errors = validateProfile(profile);

  if (errors.length > 0) {
    throw new Error(`Invalid workload profile:\n- ${errors.join("\n- ")}`);
  }

  return profile;
}

function validateProfileSchema(profile) {
  if (validateProfileShape(profile)) {
    return [];
  }

  return validateProfileShape.errors.map(formatAjvError);
}

function validateWorkflows(workflows, actors, workflowPaths) {
  const errors = [];

  for (const [name, workflow] of Object.entries(workflows)) {
    if (workflowPaths && !workflowPaths[workflow.type]) {
      errors.push(`workflows.${name}.type is not registered: ${workflow.type}`);
    }

    const actorRole = workflow.actorRole || "dispatcher";
    if (!actors[actorRole]) {
      errors.push(`workflows.${name}.actorRole is not registered in actors: ${actorRole}`);
    }
  }

  return errors;
}

function validateTimeBuckets(timeBuckets, workflows) {
  const errors = [];

  timeBuckets.forEach((bucket, index) => {
    for (const workflowName of Object.keys(bucket.workflowMix)) {
      if (!workflows[workflowName]) {
        errors.push(`timeBuckets[${index}] references unknown workflow: ${workflowName}`);
      }
    }
  });

  return errors;
}

function validateSeries(series = []) {
  const errors = [];
  const names = new Set();

  series.forEach((definition, index) => {
    if (names.has(definition.name)) {
      errors.push(`series[${index}].name is duplicated: ${definition.name}`);
    } else {
      names.add(definition.name);
    }

    definition.steps.forEach((step, stepIndex) => {
      validateCadenceBounds(step.cadence, `series[${index}].steps[${stepIndex}].cadence`, errors);
    });
  });

  return errors;
}

function validateCadenceBounds(cadence, path, errors) {
  if (cadence.mode !== "bounded-random") {
    return;
  }

  if (cadence.max < cadence.min) {
    errors.push(`${path}.min and ${path}.max must be non-negative numbers with max >= min.`);
  }
}

function formatAjvError(error) {
  const path = jsonPointerToPath(error.instancePath);

  if (error.keyword === "required") {
    return path
      ? `${path} must include ${error.params.missingProperty}.`
      : `Missing required field: ${error.params.missingProperty}`;
  }

  if (error.keyword === "const" && path === "schemaVersion") {
    return "schemaVersion must be 1.";
  }

  if (error.keyword === "minimum" && error.params.limit === 1) {
    return `${path} must be a positive integer.`;
  }

  if (error.keyword === "minimum" && error.params.limit === 0) {
    return `${path} must be a non-negative number.`;
  }

  if (error.keyword === "exclusiveMinimum" && error.params.limit === 0) {
    return `${path} must be a positive number.`;
  }

  if (error.keyword === "minItems") {
    return `${path} must be a non-empty array.`;
  }

  if (error.keyword === "minProperties") {
    return `${path} must be a non-empty object.`;
  }

  if (error.keyword === "pattern" && path.endsWith(".duration")) {
    return `${path} must be a duration string like 30s, 2m, or 1h.`;
  }

  return `${path || "profile"} ${error.message}.`;
}

function jsonPointerToPath(pointer) {
  if (!pointer) {
    return "";
  }

  return pointer
    .split("/")
    .slice(1)
    .map((part) => part.replace(/~1/g, "/").replace(/~0/g, "~"))
    .reduce((path, part) => {
      if (/^\d+$/.test(part)) {
        return `${path}[${part}]`;
      }

      return path ? `${path}.${part}` : part;
    }, "");
}
