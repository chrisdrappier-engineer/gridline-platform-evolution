export function profileRunContext(profile, { profilePath, thresholds }) {
  return {
    profilePath,
    thresholds,
    timeBuckets: profile.timeBuckets.map((bucket) => ({
      name: bucket.name,
      iterations: bucket.iterations,
      workflowMix: bucket.workflowMix
    })),
    workflows: Object.fromEntries(
      Object.entries(profile.workflows).map(([name, workflow]) => [
        name,
        {
          type: workflow.type,
          actorRole: workflow.actorRole || "dispatcher"
        }
      ])
    )
  };
}
