# ADR 0003: Keep Scaling Stages As Scenario Folders On Main

## Status

Accepted

## Context

The repository demonstrates a sequence of architecture stages. Each stage should
be understandable, runnable, and reviewable without requiring a reader to jump
across long-lived branches or reconstruct historical commits.

The project also needs a structure that works well for documentation, demos, and
CI smoke verification.

## Decision

Keep scaling stages as scenario folders on the main branch.

Each scenario should contain the documentation and runtime artifacts needed to
explain and verify that stage, such as a `README.md`, Compose configuration,
demo script, and smoke verification script where appropriate.

## Consequences

Readers can inspect the whole architecture journey from the current main branch.
CI can discover and verify scenarios without special branch handling.

The tradeoff is that some shared application code may need to support multiple
scenario configurations. The project should keep scenario-specific runtime
configuration isolated and avoid unnecessary duplication.

