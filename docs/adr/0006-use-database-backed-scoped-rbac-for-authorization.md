# ADR 0006: Use Database-Backed Scoped RBAC For Authorization

## Status

Accepted

## Context

Gridline is being modeled as a mature Rails monolith that already supports
multiple operational actors. The platform evolution story is primarily about
scaling architecture, delivery, observability, background work, and operational
maturity. Authorization should therefore start from a mature-enough design
rather than from a deliberately incomplete placeholder that would need to be
replaced later.

The application now needs to support distinct workflows for several roles:

- dispatcher: internal Gridline user responsible for intake, triage,
  assignment, and queue coordination across customers and sites
- facility_manager: customer-side site user responsible for submitting service
  requests and verifying completion for assigned facilities
- customer_contact: customer-side account user responsible for reviewing and
  tracking service requests across all sites for a customer
- service_provider_user: provider-side user responsible for responding to
  assigned service requests and documenting actions taken
- admin: internal system user responsible for configuration and operational
  oversight

These roles require both permission boundaries and scope boundaries. For
example, the relevant rule is not simply "facility managers can create service
requests." The actual rule is "facility managers can create service requests
for facilities where they hold the facility manager role."

The application also needs role-specific dashboards. A dispatcher may need
cross-customer visibility. A facility manager should see only requests tied to
assigned facilities. A customer contact should see requests across one
customer's sites. A service provider user should see requests assigned to their
provider.

A simple `user.role` column is no longer expressive enough. Likewise, using a
gem that stores only role assignments while keeping role-to-permission rules in
code would not fully support the mature-baseline model we want to represent.
Since the known product direction includes granular permissions, scoped
assignments, and possible future administrative permission management, the
authorization schema should reflect that shape from the beginning.

## Decision

We will implement a custom database-backed scoped RBAC model.

The authorization model will include:

- roles
- permissions
- role_permissions
- user_role_assignments

Roles represent actor types such as `dispatcher`, `facility_manager`,
`customer_contact`, `service_provider_user`, and `admin`.

Permissions represent granular capabilities as a resource plus an action. For
example:

- resource `service_requests`, action `read`
- resource `service_requests`, action `create`
- resource `service_requests`, action `triage`
- resource `service_requests`, action `assign`
- resource `service_requests`, action `respond`
- resource `service_requests`, action `verify_completion`
- resource `customers`, action `read`
- resource `customer_sites`, action `read`
- resource `service_providers`, action `read`

The application may expose a derived display key such as
`service_requests.create`, but the database should store `resource` and
`action` separately rather than treating a dot-separated string as the primary
permission identity.

Role permissions map roles to capabilities. For example:

- `facility_manager` can create `service_requests`
- `facility_manager` can verify completion for `service_requests`
- `dispatcher` can triage `service_requests`
- `dispatcher` can assign `service_requests`
- `service_provider_user` can respond to `service_requests`

User role assignments map users to roles and may include a scope. Scoped
assignments will identify the resource where the role applies, such as a
Customer, CustomerSite, or ServiceProvider. Global assignments will support
roles such as dispatcher and admin.

Authorization decisions must consider both permission and scope. A user is
allowed to perform an action only when:

- the user has a role assignment
- the assigned role has the requested permission
- the role assignment scope covers the target record or workflow context

The application will expose this through a thin authorization layer.
Controllers, dashboards, and views should ask the authorization layer what the
current user can do or see rather than querying authorization tables directly.

This first implementation will not include a full permissions administration
UI. Roles, permissions, role-permission mappings, and demo assignments can be
seeded. An administrative UI can be added later if the product story calls for
runtime permission management.

## Consequences

This gives the application a mature authorization foundation aligned with the
intended final state.

Benefits:

- Supports permission plus scope, not only role names.
- Makes the role-to-permission matrix visible in the database.
- Allows multiple roles per user.
- Supports scoped roles across customers, customer sites, service providers,
  and global/internal contexts.
- Creates a future path toward administrative permission management.
- Keeps authorization data auditable and inspectable.
- Avoids intentionally adopting a partial authorization model that we already
  expect to replace.

Costs:

- More schema and model complexity than a single `user.role` column.
- More application code than using only Rolify, Pundit, Action Policy, or
  CanCanCan.
- Requires careful testing around both permission checks and scope checks.
- Requires discipline to keep controllers from duplicating authorization logic.
- Needs clear seed data so the demo remains understandable.

This decision does not mean building an elaborate authorization platform
immediately. The first version should be focused: database tables, models, seed
data, an authorization service, scoped query helpers, and tests.

## Alternatives Considered

### Use A `user.role` Column Only

This is simple and easy to understand, but it cannot represent scoped
authorization. It does not support cases like "facility manager for Site A but
not Site B" or "customer contact for Customer X but not Customer Y."

### Use Policy Classes Only

Policy frameworks such as Pundit or Action Policy are strong tools for
enforcement and testability. However, they primarily store permission rules in
application code. That does not match the goal of making the role-to-permission
model visible in the database.

### Use CanCanCan Only

CanCanCan centralizes authorization logic in an Ability class and can support
scoped ActiveRecord queries. It is useful, mature, and Rails-friendly. However,
its role-to-permission matrix still primarily lives in code. It may be useful
later, but by itself it does not provide the database-backed permission model
this application needs.

### Use Rolify Plus CanCanCan

Rolify plus CanCanCan is a practical Rails authorization combination. Rolify can
store role assignments, including scoped role assignments, and CanCanCan can
enforce access rules.

This option was seriously considered because it is likely faster to implement
and relies on mature gems. It matches part of our need: storing user role
assignments and scopes in the database.

We are not choosing it as the primary authorization model because it does not
naturally store the full role-to-permission matrix in the database. The
permission rules would still primarily live in CanCanCan's Ability class. Since
we already know the application is moving toward granular permissions and
scoped access as part of its mature baseline, we prefer to model that explicitly
now instead of starting with a partial solution and refactoring later.

### Use An External Authorization Service

An external authorization service could support sophisticated permission
models, but it adds operational complexity too early. The current baseline is
still a Rails monolith. Authorization should remain inspectable and testable
within the application for now.

## Implementation Notes

Primary keys and foreign keys should use UUIDs, consistent with the project's
UUID primary key decision.

A likely first schema:

- roles
  - id
  - key
  - name
  - description
- permissions
  - id
  - resource
  - action
  - name
  - description
- role_permissions
  - id
  - role_id
  - permission_id
- user_role_assignments
  - id
  - user_id
  - role_id
  - resource_type
  - resource_id

The permission table should have a unique index on `[resource, action]`.

The user role assignment resource fields should support global assignments by allowing
`resource_type` and `resource_id` to be null.

Initial authorization service shape:

- `can?(user, resource:, action:, target: nil)`
- `accessible_scope(user, resource:, action:, relation:)`

Initial implementation should seed:

- roles
- permissions
- role-permission mappings
- demo role assignments for dispatcher, facility manager, customer contact,
  service provider user, and admin

The first controllers to consume this should likely be:

- dashboard
- service_requests
- customer_sites
- customers
- service_providers

## AI Involvement

This decision was developed through substantial AI-assisted discussion with
Codex. See the related decision note:
[Scoped RBAC Authorization](../decision-notes/2026-07-10-scoped-rbac-authorization.md).
