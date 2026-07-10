# Decision Note: Scoped RBAC Authorization

## Date

2026-07-10

## Related ADR

[ADR 0006: Use Database-Backed Scoped RBAC For Authorization](../adr/0006-use-database-backed-scoped-rbac-for-authorization.md)

## Summary

This discussion defined Gridline's authorization direction as a custom
database-backed scoped RBAC model.

The final decision was to model roles, permissions, role-permission mappings,
and scoped user role assignments inside the Rails application database. This
lets Gridline represent both capability and scope, such as a facility manager
being allowed to create service requests only for facilities where they hold
that role.

## Why This Needed A Note

ADR 0006 captures the final architecture decision, but the conversation leading
to it included several important reasoning steps:

- the role model changed from internal-only users to multi-party actors
- role-specific dashboards made authorization boundaries necessary
- the user distinguished permission data from authorization logic
- the discussion compared policy-only gems, role-assignment gems, gem
  combinations, and custom RBAC
- the user explicitly connected the decision to the broader mature Rails
  monolith narrative
- a UUID primary key refactor was identified as a prerequisite before adding
  authorization tables

Because AI-assisted discussion materially shaped the decision and the user
redirected several assumptions, this note records the reasoning path without
duplicating the ADR.

## Role Model Shift

The application originally had a small internal role set:

- dispatcher
- operations_manager
- admin

As workflows became more realistic, the user reframed the actor model around
the people who would actually participate in the service request lifecycle:

- dispatcher: internal Gridline user responsible for intake, triage,
  assignment, and queue coordination across customers and sites
- facility_manager: customer-side site user responsible for submitting service
  requests and verifying completion
- customer_contact: customer-side account user responsible for reviewing and
  tracking service requests across all sites for a customer
- service_provider_user: provider-side user responsible for responding to
  service requests, documenting actions taken, and identifying follow-up needs

Codex initially suggested that operations manager could remain an internal
Gridline role. The user then clarified a workflow-centered role set that better
supported the next stage of application behavior.

## Dashboards And Access Boundaries

The user identified that each supported role should have a dashboard showing
only the information that role is allowed to see.

This shifted authorization from a later concern into a prerequisite for
workflow development. Without permission-scoped dashboards, the application
would remain a demo where every user can see the same operational universe.

Codex proposed introducing a permission layer before expanding workflows so
controllers and dashboards could ask an authorization layer what a user can see
or do.

## Permission Plus Scope

The discussion moved from simple role checks to permission-plus-scope checks.

The user clarified that the application does not only need rules such as:

- facility_manager can create service requests

The application needs scoped rules such as:

- facility_manager can create service requests for the facilities they manage

That distinction became the core design constraint. Authorization must consider
both whether a role has a capability and whether the user's role assignment
covers the target resource.

## Gem Evaluation

Codex initially suggested common Rails authorization approaches:

- Action Policy
- Pundit
- CanCanCan
- Rolify

The user asked how each stores permission information. Codex distinguished
between code-backed policy rules and database-backed role assignments.

The key finding was:

- Pundit and Action Policy primarily store authorization rules in Ruby policy
  classes.
- CanCanCan primarily stores authorization rules in an Ability class.
- Rolify stores role assignments in the database, including scoped role
  assignments, but does not enforce authorization or store a full
  role-to-permission matrix.

The user then clarified the desired direction: permission information should be
stored in the database at the level of role capability and assignment scope.

## Rolify Plus CanCanCan

The user brought in outside AI feedback suggesting that Rolify plus CanCanCan
might be a more practical implementation than a custom system.

Codex evaluated that combination more deeply and acknowledged that it is a
sane, mature Rails approach for many applications:

- Rolify can store scoped user-role assignments.
- CanCanCan can enforce access rules and scope ActiveRecord queries.

However, the combination does not naturally store the full role-to-permission
matrix in the database. Permission rules would still primarily live in
CanCanCan's Ability class.

The user then tied the decision back to the project narrative. Gridline is
intended to begin as a mature Rails application and then demonstrate horizontal
scaling concepts. Since the final state is relatively known, the user preferred
not to intentionally start with a partial authorization model that would later
need to be replaced.

Codex agreed that this project should not make authorization refactoring the
main platform evolution story. The selected authorization design should support
the mature baseline from the start while remaining focused enough to implement
incrementally.

## UUID Sidetrack

During the authorization discussion, the user identified that adding scoped RBAC
tables would deepen the schema and make primary key strategy more important.

The current Rails migrations used default bigint primary keys. The user decided
that all table primary keys should use UUIDs going forward to allow more
flexibility if models are later split, merged, or moved across service
boundaries.

Codex updated the existing early-stage migrations to use UUID primary keys and
UUID foreign keys, enabled Postgres `pgcrypto`, configured Rails generators to
default to UUID primary keys, and verified the fresh schema with Docker-backed
CI and a temporary database inspection.

This UUID refactor was not the authorization decision itself, but it became an
important prerequisite before adding authorization tables.

## Final Position

The final position was to implement a focused custom database-backed scoped
RBAC model:

- roles
- permissions
- role_permissions
- user_role_assignments
- a thin authorization service
- scoped query helpers
- seeded initial roles, permissions, mappings, and demo assignments
- tests for capability checks and scope checks

The decision explicitly does not require an administrative permissions UI in
the first implementation. The database model should support that future, but
the initial implementation can be seeded and code-consumed.

## AI Involvement

Codex contributed by:

- summarizing the existing role model
- distinguishing internal Gridline users from customer-side and provider-side
  actors
- proposing role-specific dashboards and permission scoping
- comparing Action Policy, Pundit, CanCanCan, Rolify, and external
  authorization services
- explaining the difference between role assignment storage and permission rule
  storage
- evaluating Rolify plus CanCanCan against the project's requirements
- recognizing that the user's mature-baseline narrative favored a complete
  enough final authorization shape over a deliberately partial interim model
- identifying the implementation boundary between seeded RBAC data and a future
  administrative UI
- implementing the related UUID migration refactor after the user raised the
  primary-key concern

The user made the decisive architectural calls:

- refocusing roles around dispatcher, facility manager, customer contact, and
  service provider user workflows
- requiring dashboards and data visibility to differ by role
- requiring database-visible permission information
- clarifying that permission checks must include resource scope
- challenging whether Rolify plus CanCanCan was sufficient
- choosing the mature-baseline interpretation that favors a custom scoped RBAC
  model now instead of a planned authorization replacement later
