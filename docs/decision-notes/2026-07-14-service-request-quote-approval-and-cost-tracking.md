# Decision Note: Service Request Quote Approval And Cost Tracking

## Date

2026-07-14

## Related Work

- [Issue 16: Add service request quote approval and actual cost tracking](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/16)
- [Roadmap](../roadmap/README.md)
- [User Stories](../user-stories/README.md)
- [Application Interaction Rules](../design/application-interaction-rules.md)

## Summary

This discussion expanded the original cost-tracking idea into a fuller service
request quote approval workflow.

The final direction was to model one Gridline-vetted quote per service request,
customer-level approval thresholds, facility-manager approval when a quote is
above threshold, amendment language for changed site conditions, and separate
actual cost entries after work is performed.

This keeps the feature grounded in Gridline's fictional business model while
creating useful future reporting dimensions such as quote-to-actual variance,
approval frequency, approval cycle time, amended quote frequency, and
customer-level spend.

## Why This Needed A Note

Issue 16 began as service request cost tracking. During discussion, the user
identified several domain details that materially changed the feature shape:

- facility managers should approve cost before work is performed
- Gridline's offering includes prescreening vendors for price reasonability
- customers should not need multiple quotes for a single job
- the correct term is quote, not estimate
- quotes need legalistic amendment language because site conditions may change
- customer contracts should include an approval threshold below which explicit
  approval is not required

Those decisions affect data modeling, authorization, UI workflow, seeded demo
data, and future reporting. They are broader than routine implementation
details, but they do not require a new ADR because they refine product/domain
behavior rather than changing the core architecture.

## Business Model Clarification

The user clarified that Gridline is not simply dispatching arbitrary vendors.
Part of Gridline's value proposition is prescreening service providers for:

- trade capability
- regional availability
- compliance and reliability
- price reasonability

Because Gridline does this screening up front, the customer does not need to
collect multiple quotes for a single job. Gridline can present one quote tied
to the assigned provider and service request context.

This decision strengthens the fictional real-world scenario. It makes the
approval workflow more plausible than a generic cost-entry feature and gives
Gridline a clearer market position.

## Quote Instead Of Estimate

The user rejected estimate as the primary term and selected quote.

That terminology matters because quote sounds closer to a customer-facing
authorization artifact, while estimate sounds softer and more tentative. The
implementation therefore uses:

- `ServiceRequestQuote` for the pre-work amount presented for approval
- `ServiceRequestCost` for actual post-work cost entries

This separates expected authorized spend from actual incurred spend.

## One Quote Per Request

Codex initially suggested that multiple estimates or quote versions might be
useful. The user narrowed the first implementation to one quote per request
because Gridline's prescreening removes the need for multiple competing vendor
quotes.

The implementation follows that direction with a one-to-one relationship
between service request and quote.

The project may later introduce quote version history, but the first slice uses
amendment fields on the current quote rather than adding a full revision model.

## Approval Threshold

The user proposed an approval threshold: an amount below which explicit
customer-side approval is not required and above which approval is required.

Codex recommended starting at the customer level instead of the site level:

- customer-level thresholds match account contract terms
- they are simpler to implement and explain
- site-level overrides can be added later if the domain needs them

The selected rule is:

- quotes at or below the customer threshold are automatically approved
- quotes above the customer threshold require facility-manager approval

This keeps the workflow realistic without overbuilding contract policy in the
first implementation.

## Facility Manager Approval

Facility managers were identified as the appropriate first approvers because
they are responsible for assigned facilities and can authorize work before it
proceeds.

The initial permission model is:

- dispatchers can create, submit, and amend quotes for authorized requests
- facility managers can approve or reject quotes for sites they manage
- customer contacts can view quote and cost information across their customer
  scope
- admins can manage quote and cost workflows globally
- service provider users do not create, approve, or amend quotes in the first
  implementation

This keeps the customer-side approval path scoped to the facility where work
will happen.

## Facility Manager Accountability For Active Sites

After the first quote approval slice was implemented, the user noticed an
important domain gap: a facility manager cannot approve customer-side work for
a site unless that site has a clearly assigned facility manager.

Codex initially treated this as technically separable from issue 16 because it
is a broader site-accountability rule rather than quote-specific behavior. The
user decided to include it in issue 16 anyway because the implementation risk
was low and creating a separate administrative work item would add more
overhead than value at this stage.

The selected rule is:

- active customer sites require at least one assigned facility manager
- the assignment is represented through the existing scoped RBAC model
- one facility manager may cover multiple active sites
- inactive and temporarily closed sites may exist without a facility manager
- admin site create and update workflows must provide a normal path to assign
  the facility manager

This rule supports quote approvals because the application can now assume that
an active site has a customer-side accountable party before service work and
cost authorization are modeled around it.

Demo and development seeds were updated so every active seeded site has a
facility manager assignment.

## Amendment Language

The user asked for legalistic language allowing a vendor quote to be amended if
new details surface on site.

The selected product behavior is that quotes are based on information available
before service begins. If material site conditions, concealed damage, parts
requirements, safety constraints, or other facts are discovered during service,
Gridline may amend the quote and request approval again when required.

This language appears in the service request quote section rather than only in
documentation so the approval workflow carries the business rule visibly.

## Actual Costs And Variance

The implementation keeps actual costs separate from quote approval.

Actual costs can be entered after work is performed and categorized as:

- labor
- parts
- trip charge
- emergency fee
- other

This allows the service request detail page to show:

- quoted amount
- approval status
- approval threshold
- actual cost total
- quote-to-actual variance

Those data points support future customer and management reporting.

## Scaling And Reporting Value

Although issue 16 is primarily domain richness, it supports the later scaling
story.

Quote and cost data creates credible future reporting pressure:

- customer-wide spend reports
- quote-to-actual variance reports
- pending approval queues
- amended quote frequency
- provider price reliability
- threshold impact analysis

These reporting needs can later drive larger seed profiles, expensive
aggregate queries, indexes, caching decisions, background report generation,
and eventually horizontal scaling considerations.

## Implementation Notes

The first implementation used Rails generators through the tracked generator
tooling, then refined the generated files by hand.

The implementation added:

- customer quote approval threshold
- `ServiceRequestQuote`
- `ServiceRequestCost`
- nested quote and cost controllers
- RBAC permissions and authorization coverage for service request child records
- quote and cost UI on the service request detail page
- customer threshold display and maintenance
- active-site facility manager enforcement
- demo data updates
- Rails model/controller tests
- Playwright browser workflow coverage
- E2E one-worker default to avoid shared demo data races

The implementation intentionally did not add:

- multiple competing quotes
- provider-submitted quotes
- quote version history
- invoice or payment workflows
- accounting integrations
- site-specific threshold overrides

## AI Involvement

Codex contributed by:

- proposing the initial cost-entry model
- recognizing that quote approval changed the feature shape
- recommending separate quote and actual cost models
- suggesting customer-level approval thresholds as the first policy layer
- translating the discussion into issue #16's updated GitHub description
- implementing the first Rails slice on an issue branch
- adding tests and browser workflow coverage
- updating README, roadmap, and user stories to reflect the new feature
- identifying that facility manager assignment could technically be separated
  from issue 16, then implementing it in issue 16 after the user weighed the
  low risk against the administrative overhead

The user made the decisive product calls:

- facility managers should approve pre-work cost when required
- Gridline prescreens vendors so customers do not need multiple quotes per job
- the domain term should be quote, not estimate
- one quote per request is enough for the first implementation
- quotes should include amendment language for changed site conditions
- approval thresholds should determine whether explicit approval is required
- active customer sites should require an accountable facility manager now,
  without creating a separate issue for that enforcement
