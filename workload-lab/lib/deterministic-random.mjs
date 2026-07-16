const MAX_UINT32 = 0xffffffff;

export function stableHash(input) {
  const value = String(input);
  let hash = 2166136261;

  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }

  return hash >>> 0;
}

export function deterministicUnit(seed, ...parts) {
  return stableHash([seed, ...parts].join(":")) / (MAX_UINT32 + 1);
}

export function deterministicIndex(length, seed, ...parts) {
  if (!Number.isInteger(length) || length < 1) {
    throw new Error("deterministicIndex requires a positive integer length.");
  }

  return Math.floor(deterministicUnit(seed, ...parts) * length);
}

export function deterministicChoice(values, seed, ...parts) {
  if (!Array.isArray(values) || values.length === 0) {
    throw new Error("deterministicChoice requires a non-empty array.");
  }

  return values[deterministicIndex(values.length, seed, ...parts)];
}

export function deterministicWeightedChoice(weightMap, seed, ...parts) {
  const entries = Object.entries(weightMap || {}).filter(([, weight]) => Number(weight) > 0);
  const total = entries.reduce((sum, [, weight]) => sum + Number(weight), 0);

  if (entries.length === 0 || total <= 0) {
    throw new Error("deterministicWeightedChoice requires at least one positive weight.");
  }

  const target = deterministicUnit(seed, ...parts) * total;
  let cursor = 0;

  for (const [value, weight] of entries) {
    cursor += Number(weight);
    if (target < cursor) {
      return value;
    }
  }

  return entries.at(-1)[0];
}
