import { deterministicUnit } from "./deterministic-random.mjs";

export function cadenceSleepSeconds(cadence, { seed, seriesName, stepName, vu, iteration }) {
  if (cadence.mode === "static") {
    return cadence.seconds;
  }

  if (cadence.distribution === "uniform") {
    return boundedUniform(cadence, seed, seriesName, stepName, vu, iteration);
  }

  if (cadence.distribution === "normal") {
    return boundedNormal(cadence, seed, seriesName, stepName, vu, iteration);
  }

  throw new Error(`Unsupported cadence distribution: ${cadence.distribution}`);
}

function boundedUniform(cadence, seed, seriesName, stepName, vu, iteration) {
  const unit = deterministicUnit(seed, seriesName, stepName, vu, iteration, "cadence", "uniform");

  return cadence.min + unit * (cadence.max - cadence.min);
}

function boundedNormal(cadence, seed, seriesName, stepName, vu, iteration) {
  const first = nonZeroUnit(seed, seriesName, stepName, vu, iteration, "cadence", "normal", "first");
  const second = deterministicUnit(seed, seriesName, stepName, vu, iteration, "cadence", "normal", "second");
  const standardNormal = Math.sqrt(-2 * Math.log(first)) * Math.cos(2 * Math.PI * second);
  const value = cadence.mean + standardNormal * cadence.standardDeviation;

  return Math.min(cadence.max, Math.max(cadence.min, value));
}

function nonZeroUnit(seed, ...parts) {
  return Math.max(Number.EPSILON, deterministicUnit(seed, ...parts));
}
