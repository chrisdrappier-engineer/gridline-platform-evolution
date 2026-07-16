import { readFile } from "node:fs/promises";

import { validateProfile } from "./profile.mjs";

export async function validateProfileFile(profilePath) {
  if (!profilePath) {
    throw new Error("Usage: bin/workload-validate-profile <profile-path>");
  }

  const profile = JSON.parse(await readFile(profilePath, "utf8"));
  const errors = validateProfile(profile);

  if (errors.length > 0) {
    throw new Error(`${profilePath} failed validation:\n- ${errors.join("\n- ")}`);
  }

  return profile;
}
