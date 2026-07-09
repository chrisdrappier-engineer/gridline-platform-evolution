# Rails Generator Tooling

Date: 2026-07-09

## Context

The project is ready to move from container infrastructure toward generating
the initial Rails application. Because Rails creates a large amount of
framework-owned structure, we want those files to come from Rails generators
rather than being manually reconstructed.

At the same time, the project has already chosen a Docker-first development
boundary. Running Rails generators directly on the host machine would reintroduce
local Ruby, Bundler, native gem, and operating system drift at the exact point
where the project is trying to make runtime behavior reproducible.

## Decision

Create a dedicated Rails generator toolchain that is separate from the
application runtime.

The repository will include:

- `generator/` for the generator container image and its pinned dependencies
- `compose.generator.yml` for running generation commands with the repository
  mounted into the container
- `bin/rails-new` for the initial Rails application generation
- `bin/rails-generate` for future Rails generator commands inside the generated
  app
- `docs/rails-generator-history.md` for a factual log of successful generator
  commands

The generator image uses Ruby `4.0.5` and Rails `8.1.3`, following the project
convention of choosing the latest stable release unless there is a compelling
reason not to.

## Rationale

Rails-generated structure should be produced by Rails itself. This avoids
hand-authoring framework files that are easy to get subtly wrong and makes the
initial application skeleton easier to compare against normal Rails
expectations.

The generator runs in Docker so file generation does not depend on the
maintainer's host Ruby installation, Bundler state, native gem environment, or
operating system. This keeps the project aligned with the Docker-first approach
already chosen for the baseline runtime.

The generator Compose file is separate from the runtime Compose file because
file generation is repository tooling, not part of the Gridline application's
production-like topology. The baseline runtime still models the fictional PaaS
boundary: an application service and a Postgres service.

The generator command history should stay clean and factual. It records what
commands were run, but not why they were chosen. Context and rationale belong
in commit messages, ADRs, decision notes, and pull request descriptions.

## Consequences

Rails file generation becomes repeatable and reviewable without requiring Rails
to be installed on the host machine.

The repository gains a small amount of tooling overhead before the Rails app
exists. That overhead is acceptable because Rails generation will happen more
than once as the application grows.

The generator image must be maintained when the project intentionally changes
Ruby or Rails versions.

The generator history is not a full architectural record. It is an audit trail
for generated files, while ADRs and decision notes remain responsible for
explaining decisions.

## AI Involvement

Codex helped identify the need for a separate generator layer after discussion
about avoiding manually authored Rails framework files and avoiding host runtime
drift.

The human maintainer established the preference for Docker-based generation,
clean generator command history, and repository-tracked generator scripts. Codex
proposed the concrete repository structure and scripts, then adjusted the
implementation when verification showed that mounting the repository over
`/workspace` hid the generator image's own Gemfile.

The decision remains human-owned.
