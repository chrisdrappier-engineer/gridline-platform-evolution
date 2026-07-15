# Decision Note: Dumb ERB View Model Refactor

## Date

2026-07-15

## Related Work

- [Issue 27: Refactor Rails views toward dumb ERB templates](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/27)
- [ADR 0007: Render Rails views from prepared view models](../adr/0007-render-rails-views-from-prepared-view-models.md)
- [Dumb ERB Template Boundary](2026-07-15-dumb-erb-template-boundary.md)

## Summary

Issue 27 begins the refactor from logic-heavy ERB templates toward prepared
view data and partial composition.

The initial implementation first focused on high-value application decisions,
then tightened the endpoint to remove explicit conditional syntax from ERB
templates entirely.

## Decision

Adopt plain Ruby view models as the first view-boundary mechanism.

This keeps the project close to Rails conventions while giving the application
a testable place for page-level decisions such as:

- which workflow actions are visible
- which permission-filtered links are shown
- how status, priority, timestamps, and money values are presented
- which sections appear on complex detail pages
- how layout structure changes when a user is signed in

The first reusable objects are:

- `ViewAction`
- `DetailRow`
- `MetricCard`
- `ServiceRequestShowPage`

The refactor moves direct authorization checks out of ERB for customer, site,
provider, and service request pages. The service request detail page now uses a
page object for header actions, detail rows, metrics, quote/cost state,
assignment visibility, and provider response visibility.

The stricter pass also moves empty states, form error rendering, submit labels,
pagination controls, admin table fallbacks, service request form context, and
shared action rendering out of explicit ERB conditionals.

## Scope Boundary

This pass deliberately does not eliminate Rails helper calls or collection
iteration. Templates still render partials, forms, links, fields, and prepared
collections.

The strict boundary is that ERB no longer contains explicit conditional syntax.
Rendering decisions live in helpers, table helpers, view models, or
controller-prepared state.

A follow-up to issue 27 adds a custom `bin/dumb-erb-lint` check to CI so this
boundary is enforced automatically instead of relying on manual repository
scans.

## Rationale

Trying to enforce "no method calls in ERB" would fight normal Rails rendering.
The selected rule is more useful: no application decision-making in ERB.

Plain Ruby view models and helper-returned fragments give Gridline a
low-overhead path to move those decisions out of templates without introducing a
new presentation framework before the project has enough duplication to justify
one.

## AI Involvement

Codex proposed ADR 0007, added the first view-model objects, and refactored the
layout plus the highest-risk authorization and workflow branches out of ERB.
After the user asked to include the stricter endpoint in issue 27, Codex moved
the remaining explicit ERB conditionals into helpers, partial selection, or view
models and verified the absence of conditional syntax with a repository scan.

The user set the direction by asking for a stronger boundary around application
logic in views and by deciding that the dumb-view rule should be promoted into
the operating agreement after the ADR.
