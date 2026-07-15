# ADR 0007: Render Rails Views From Prepared View Models

## Status

Accepted

## Context

Gridline's baseline Rails application began with ordinary Rails ERB views. As
the application gained role-specific navigation, scoped permissions, workflow
actions, quote approval, actual cost tracking, lifecycle metrics, and reporting
surfaces, several templates started to contain application decisions.

Examples include:

- permission checks for action visibility
- workflow state checks for triage and completion verification
- dynamic attribute and class assembly
- display fallbacks for timestamps, assignments, and summaries
- table and form option decisions

This makes templates harder to scan and pushes behavior into a layer that is
awkward to test directly. ERB linting helps catch template safety problems, but
it cannot define the architectural boundary by itself.

## Decision

Rails ERB templates should render prepared view data instead of making
application decisions.

Gridline will use small view-facing Ruby objects for page-level presentation
state. These objects may be plain Ruby classes under `app/view_models`, helper
objects, table objects, or focused objects returned by controllers. Their job is
to prepare visible actions, sections, detail rows, labels, paths, CSS classes,
and empty-state text before ERB renders.

ERB templates may still use normal Rails rendering helpers such as:

- `render`
- `link_to`
- `button_to`
- `form_with`
- path helpers
- tag helpers
- simple iteration over already-prepared display collections

ERB templates should not own explicit conditional logic. That includes:

- `if`, `elsif`, `else`, `unless`, `case`, and `when`
- inline conditional modifiers
- ternary expressions
- boolean composition used to decide rendering

Those choices should move into helpers, table objects, view models, controller
setup, or partial names prepared before rendering.

ERB templates should also not own:

- authorization checks
- business rules
- record queries
- status or state branching
- table construction
- form option filtering
- dynamic class or attribute assembly that depends on application state
- complex object traversal
- formatting decisions beyond displaying already-prepared values

The practical target is zero decision-making in ERB, not zero method calls.

## Consequences

This introduces a clearer boundary between application behavior and markup:

- controllers authorize and load records
- table objects prepare tabular data
- view models prepare page display state
- helpers handle small formatting and rendering conveniences
- ERB renders declarative markup and partial composition

The tradeoff is additional Ruby objects for pages that previously embedded
logic directly in templates. That overhead is acceptable for views that expose
permissions, workflow state, or domain-specific display decisions. Very small
static templates do not need dedicated page objects.

This ADR does not require a single framework or gem for presenters. The project
will start with plain Ruby view models and extract common patterns only when
real duplication appears.

## Verification

The boundary is enforced through a combination of:

- code review against this ADR
- ERB lint for template safety
- custom dumb ERB linting for explicit template decision logic
- RuboCop for Ruby code
- focused Rails tests for view model behavior when page decisions become
  meaningful
- browser workflow tests for user-visible behavior

The custom dumb ERB lint check runs in `bin/ci` and rejects explicit
conditional syntax, inline conditional modifiers, ternary rendering decisions,
boolean rendering decisions, direct authorization checks, and `.html_safe` in
ERB templates.

## AI Involvement

Codex proposed the distinction between "no method calls in ERB" and "no
decision-making in ERB." The user pushed for a stronger boundary around
application logic in templates. Codex recommended a presenter/view-model layer
because it preserves normal Rails helper usage while moving authorization,
state, and display decisions into testable Ruby objects.
