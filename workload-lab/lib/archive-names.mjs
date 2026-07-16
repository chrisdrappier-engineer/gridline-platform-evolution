export function summaryBaseName({ scenarioId, profileId, generatedAt }) {
  return [scenarioId, profileId, timestampSlug(generatedAt)].map(slug).join("-");
}

export function summaryFileNames(metadata) {
  const baseName = summaryBaseName(metadata);

  return {
    json: `archive/${baseName}.summary.json`,
    markdown: `archive/${baseName}.summary.md`
  };
}

function timestampSlug(value) {
  return String(value);
}

function slug(value) {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
