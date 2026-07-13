# Application Interaction Rules

Gridline should model workflows that feel mature enough for an operations
platform, not only a CRUD demonstration. User-facing pages should therefore
prefer role-aware, context-rich actions over generic blank forms.

## Route-Backed Information Access

Pages that expose collections of domain records should map closely to Rails
resource routes where possible. Dashboards may summarize work, but they should
not become the only place where a role can access records it is allowed to see.

Navigation should link to resource pages when a permission grants visibility to
that resource. Friendly labels are encouraged, but the underlying page should
still represent the relevant resource and action.

## Contextual Create Forms

Create actions should begin from the richest safe workflow context available.
When a user starts an action from a customer, site, provider, user, role, or
other concrete record, the application should carry that context into the form.

Context should be used to:

- prefill associations that are already known
- narrow selectable options to the relevant scope
- hide inputs when there is only one valid choice
- show read-only context so the user can confirm where the action applies
- avoid asking the user to re-enter information already implied by the workflow

Global create routes may still exist as fallback paths for users with broad
operational scope, but they should not be the preferred path for workflows that
usually start from a specific record.

## Permission-Scoped Form Options

Form options must be built from authorized scopes, not from all records in the
database. A user should not see choices that they could not successfully submit.

When route context narrows a form, the controller must authorize that context
before using it. Query parameters and hidden fields are convenience mechanisms,
not trusted permission checks.

## Read-Only Context Panels

When the application infers or locks a form association, the form should display
that inferred context as read-only information. This is especially important
when the underlying form field is hidden because there is only one valid choice.

Context panels should answer the user's immediate question: "What record am I
creating this under?"

## Server-Side Authorization Remains Authoritative

Client-side hiding, preselection, and route context improve workflow efficiency,
but server-side authorization remains authoritative. Controllers must recheck
permissions on submitted records before creating or mutating data.

The expected pattern is:

- use route context to improve the form
- use authorized scopes to build form choices
- validate and authorize submitted associations in the controller
- render or redirect with a clear error when the submitted action is not allowed
