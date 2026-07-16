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
