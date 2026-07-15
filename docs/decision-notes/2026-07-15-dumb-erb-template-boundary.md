# Decision Note: Dumb ERB Template Boundary

## Date

2026-07-15

## Related Work

- [Issue 25: Add Ruby, CSS, and ERB linting to local CI verification](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/25)
- [Application Interaction Rules](../design/application-interaction-rules.md)

## Summary

While adding ERB linting, the user raised a broader design question: whether
views should be refactored so application logic does not live in ERB templates.

The discussion distinguished between two ideas:

- linting as an automated guardrail
- dumb ERB templates as an architectural boundary

The linting work belongs in issue 25. The full dumb-views refactor should be a
separate issue because it affects page construction, controller responsibilities,
helpers, presenters or view models, partial composition, and test strategy.

## Working Boundary

The emerging rule is not "no method calls in ERB" in an absolute sense. Rails
templates reasonably call rendering helpers such as `render`, `link_to`,
`button_to`, `form_with`, path helpers, and tag helpers.

The stronger and more useful rule is "no decision-making in ERB."

ERB templates should not own:

- authorization checks
- business rules
- record queries
- status or state branching
- table construction
- form option filtering
- dynamic class or attribute assembly
- complex object traversal
- formatting decisions beyond displaying already-prepared values

Templates may still own:

- declarative markup
- partial composition
- simple rendering of prepared values
- standard Rails rendering helpers
- iteration over already-prepared display collections, if the collection has
  already resolved visibility and state

## Expected Refactor Direction

The likely refactor path is to introduce a page or presenter layer that prepares
view-facing objects before rendering.

Controllers or page objects would prepare actions, sections, table metadata,
form context, and visibility decisions. ERB would render that prepared structure
through simple partials.

For example, a template should render prepared actions rather than ask whether a
role is permitted to see each action. The permission decision should happen
before the template receives the action list.

## ADR Recommendation

This direction probably deserves an ADR before implementation because it changes
the architectural contract between Rails controllers, helpers, service objects,
view models or presenters, and ERB templates.

The ADR should define:

- which logic is forbidden in ERB
- which Rails helper calls remain acceptable
- where page-level decision-making should live
- how the boundary will be tested
- how strictly the rule should be enforced by linting or custom checks

## AI Involvement

Codex initially framed "dumb views" as a design rule rather than something ERB
lint can fully enforce out of the box. The user pressed on whether the boundary
should exclude conditionals and method calls. Codex recommended targeting zero
decision-making rather than zero method calls, because Rails views need some
rendering helper calls to remain practical.

Codex documented the first version of the boundary in the application
interaction rules and recommended a follow-up issue plus ADR for the larger
refactor.
