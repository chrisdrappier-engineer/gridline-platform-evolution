# Workload Lab Archive

This directory is the local mirror for raw workload-lab artifacts that should
not be committed to Git.

It is intended to mirror the eventual external archive structure, such as a
Google Drive folder named `Gridline Workload Lab`.

Generated run artifacts may include:

- raw k6 output
- planned traffic files
- metric time series
- exploratory seed batches
- compressed run bundles
- manifest files with run metadata

Each archived run should include enough metadata to understand and reproduce the
result:

- profile name
- seed identifier
- application git SHA
- seed data profile
- resource envelope
- Puma and database settings
- command used
- run timestamp
- compressed and uncompressed artifact sizes
- archive checksum when packaged

Curated summaries that support project decisions should be written outside this
ignored archive in a tracked evidence location once that location exists.

## Evidence Promotion

Raw runs begin here. A `promoted-ready` summary has complete provenance, clean
application and tooling worktrees, and exact tags for both revisions. Promotion
is still manual: review run completeness and threshold results, copy selected
artifacts into a tracked evidence location, verify checksums, and cite them from
the architecture decision they support.

Use immutable annotated tags for promoted evidence. Suggested namespaces are
`app-vN` for application baselines, `workload-vN` for workload tooling, and
`evidence-YYYY-MM-DD-description` for a reviewed evidence bundle.
