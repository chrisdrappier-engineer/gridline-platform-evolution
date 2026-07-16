import { readdir, readFile } from "node:fs/promises";

import { validateProfile } from "../lib/profile.mjs";

const profilesDirectory = new URL("../profiles/", import.meta.url);
const entries = await readdir(profilesDirectory, { withFileTypes: true });
const profileFiles = entries
  .filter((entry) => entry.isFile() && entry.name.endsWith(".json"))
  .map((entry) => new URL(entry.name, profilesDirectory));

if (profileFiles.length === 0) {
  throw new Error("No workload profiles found.");
}

for (const profileFile of profileFiles) {
  const profile = JSON.parse(await readFile(profileFile, "utf8"));
  const errors = validateProfile(profile);

  if (errors.length > 0) {
    throw new Error(`${profileFile.pathname} failed validation:\n- ${errors.join("\n- ")}`);
  }
}

console.log(`Workload profile validation passed: ${profileFiles.length} profiles inspected.`);
