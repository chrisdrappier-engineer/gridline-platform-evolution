# Decision Note: Local Linting Toolchain

## Date

2026-07-15

## Related Work

- [Issue 25: Add Ruby, CSS, and ERB linting to local CI verification](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/25)
- [Application Interaction Rules](../design/application-interaction-rules.md)

## Summary

Issue 25 adds linting to the local verification path for Ruby, Rails ERB
templates, and CSS assets.

The selected linting stack is:

- RuboCop through the Rails app bundle for Ruby and Rails code
- Stylelint through the root Node toolchain for Rails CSS assets
- `erb_lint` through the Rails app bundle for ERB template safety and structure

All three checks run through the repository-level `bin/ci` command so linting is
treated as part of the same local validation path as tests and container health
checks.

## Decision

Use existing ecosystem tools instead of writing project-specific lint checks
first.

The project-level CI flow now runs:

- Stylelint before Docker work begins
- RuboCop inside the app container
- ERB lint inside the app container
- Rails tests inside the app container
- the app container health check

RuboCop and ERB lint live inside the Rails app because they depend on the Rails
Ruby bundle. Stylelint lives at the repository root because the existing
Playwright tooling already uses a root Node toolchain.

## Rule Tuning

The linting configuration is intentionally practical rather than maximal.

RuboCop keeps the Rails Omakase baseline but disables the array-bracket spacing
rule because the existing codebase already used conventional compact Ruby array
syntax. Enforcing the Omakase variant would have produced broad churn without
meaningful project value.

Stylelint uses the standard config but disables rules that would force a broad
cosmetic rewrite of existing CSS notation, selector ordering, or dynamic class
names. The goal is to catch CSS mistakes and maintain a consistent guardrail,
not to re-theme or mechanically restyle the application.

ERB lint disables its RuboCop sub-linter because it produced noisy false
positives against normal templates. RuboCop remains authoritative for Ruby
files, while ERB lint focuses on template-specific structure and safety.

## Template Safety Finding

Adding ERB lint exposed an unsafe `html_safe` attribute-construction pattern in
the application layout. The layout now delegates frame attribute construction to
`ApplicationHelper` and renders the wrapper through Rails tag helpers.

This was the first concrete example supporting the broader "dumb ERB templates"
direction: templates should not assemble complex attributes or own view
decisions when Ruby helpers or view-facing objects can prepare those values
more safely.

## AI Involvement

Codex proposed adding RuboCop first, then expanded the same issue to include
Stylelint and ERB lint when the user asked whether CSS and ERB linting should be
covered as well.

Codex installed and configured the tooling, tuned noisy rules after seeing real
project output, moved unsafe layout attribute construction out of ERB, updated
the local CI path, and updated project documentation to treat linting as part of
normal verification.
