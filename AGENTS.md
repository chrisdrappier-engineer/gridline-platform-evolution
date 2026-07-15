# Codex Operating Agreement

This repository is built with Codex as an AI development collaborator. These
instructions keep future sessions efficient, consistent, and grounded in the
project's documented decisions.

## Start From Local Context

Before re-discussing project direction, read the existing docs in this order:

1. `README.md`
2. `docs/roadmap/README.md`
3. relevant ADRs in `docs/adr/`
4. relevant decision notes in `docs/decision-notes/`
5. relevant design rules in `docs/design/`
6. relevant user stories in `docs/user-stories/`

Do not ask the user to restate settled context that is already captured in
these documents.

## Treat Settled Decisions As Context

Treat documented ADRs and decision notes as project context unless the user
explicitly asks to revisit them.

Settled direction includes:

- Docker-first runtime and Rails monolith baseline
- simulated PaaS-style local baseline
- UUID primary keys
- database-backed scoped RBAC
- backend-driven filtering, sorting, and pagination
- workflow-realistic E2E tests that use visible navigation instead of direct
  URL jumps
- vertical optimization and measurement before horizontal scaling

## Prefer Existing Patterns

When implementing code, look for and follow existing project patterns before
proposing alternatives.

Common patterns include:

- Rails generators through the tracked generator tooling
- table objects for index data
- the authorization service for permission checks and scoped records
- role-scoped controller access
- shared data table controls
- Minitest for Rails model/controller/service coverage
- Playwright for browser-visible workflow coverage
- decision notes only for substantial reasoning paths

Discuss alternatives only when the current pattern does not fit the task.

## Keep Planning And Coding Separate

If the user asks to discuss, reason about the design without reading broad
code context unless local docs are needed.

If the user asks to implement, inspect the relevant files and make the change
end to end. For code changes, read targeted files first, then expand outward
only as needed.

Typical implementation context:

- routes
- controller
- model
- relevant service or table object
- relevant view
- seeds or permissions when behavior depends on them
- tests covering the changed behavior

Avoid broad repository scans unless the task is unclear.

## Batch Coherent Changes

When a change predictably touches several files, make the complete coherent
edit in one pass rather than pausing after every file.

For example, a new user-facing resource may require:

- migration/model
- controller
- views
- table object
- permissions
- seeds
- Rails tests
- Playwright workflow coverage
- README or design-doc updates when behavior becomes a reusable rule

Still provide short progress updates during longer work.

## Be Concise With Progress And Verification

During implementation, keep updates short:

- what context is being gathered
- what is being changed
- what is being verified
- what is blocked, if anything

In final responses, summarize verification instead of pasting logs. For
example:

`bin/ci passed: 121 tests, 585 assertions.`

Include failure details only when they help diagnose a problem.

## Use Documentation Intentionally

Use documentation layers for their specific purpose:

- ADRs: final architecture decisions
- decision notes: substantial reasoning paths and AI-assisted design context
- roadmap: broader product/scaling direction and deferred ideas
- user stories: role-centered workflow needs
- design rules: repeatable UI, interaction, and implementation rules
- GitHub issues: near-term executable work
- PR descriptions: what changed, why it matters, demo steps, verification, and
  follow-up work

Do not create new issues for every plausible idea. Keep GitHub focused on work
that is likely to be implemented soon.

## Current Phase

The baseline Rails monolith has been merged. The project is now between the
baseline foundation and the next implementation phase.

Near-term work should generally fall into one of two tracks:

- operational richness from issues `#16` through `#21`
- vertical pressure and measurement work that prepares for responsible
  optimization before horizontal scaling

Avoid jumping directly to horizontal scaling infrastructure unless the user
explicitly chooses that direction or the measured application behavior justifies
it.
