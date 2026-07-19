export const COMPARABILITY_FIELDS = [
  ["profileHash", "profile hash"],
  ["seriesHash", "series hash"],
  ["seed", "workload seed"],
  ["resourceEnvelopeSnapshotHash", "resource envelope"],
  ["seedDataProfile", "seed data profile"],
  ["executionModel", "execution model"]
];

export function compareEvidence(left, right) {
  const differences = COMPARABILITY_FIELDS.flatMap(([field, label]) => {
    const leftValue = left?.[field];
    const rightValue = right?.[field];
    if (!leftValue || !rightValue) return [`${label} unavailable`];
    return leftValue === rightValue ? [] : [`${label} differs`];
  });

  return { status: differences.length === 0 ? "comparable" : "partial", differences };
}
