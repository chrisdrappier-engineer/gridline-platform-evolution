import { validateProfileFile } from "../lib/profile-file.mjs";

const profilePath = process.argv[2];
const profile = await validateProfileFile(profilePath);

console.log(`Workload profile validation passed: ${profile.profileId} (${profilePath}).`);
