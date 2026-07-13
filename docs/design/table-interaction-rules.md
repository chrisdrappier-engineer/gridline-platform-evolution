# Table Interaction Rules

Operational tables should behave consistently across index pages and dashboards
as Gridline's data volume grows. Tables are data exploration surfaces, so their
behavior must remain accurate when authorization scopes, filters, sorting, and
pagination interact.

## Rendering Model

Tables are rendered by Rails using shared ERB partials or components. Turbo
Frames may replace a table region dynamically after a user searches, filters,
sorts, or changes pages.

JavaScript may collect intent, debounce input, submit forms, and show loading
state. It must not become the source of truth for table contents.

## Data Operations

The backend applies table operations in this order:

- authorization scope
- search and filters
- sorting
- pagination

Filtering and searching are always backend operations. The frontend must not
hide or show rows by matching text in the browser.

Pagination is always backend-backed. Pagination controls are shown or hidden
based on the filtered result count. If a filter reduces the result set below the
page-size threshold, pagination links disappear for that result state.

Sorting for paginated tables is backend-backed. Sorting mode does not change
based on the current filtered result count. A paginated index table remains
server-sorted even when a filter returns only a few rows.

Client-side sorting is allowed only for explicitly unpaginated compact tables
that render the complete result set for that widget.

## Query Params

Table state should live in query params so links are shareable, reloads preserve
state, and browser navigation remains useful.

Each table should use a stable key to scope its params and DOM ids. This allows
multiple tables to appear on one dashboard without their controls conflicting.

Search and filter changes reset the table page to 1. This prevents a user from
remaining on a page number that no longer exists after the filtered result set
shrinks.

## Table Configuration

Each table is defined declaratively. The definition should include:

- stable table key
- base relation, already authorization-scoped by the caller
- columns
- searchable fields
- filterable fields
- sortable fields
- default sort
- page size
- rendering mode, such as index or compact
- row actions
- empty-state copy

The table implementation must whitelist sortable, searchable, and filterable
fields. It must not infer SQL behavior directly from arbitrary request params.

## Column Labels

Column headers should default to the column key converted with Rails string
helpers, such as `to_s.titleize`.

Explicit labels should be used only when domain language requires an override,
such as abbreviations, relationship columns, or intentionally friendlier terms.

## Pagination Library

Gridline should use a pagination gem behind the shared table abstraction rather
than maintaining custom pagination internals.

Pagy is the preferred starting choice because it is small, Rails-friendly, and
can support conventional offset pagination now while leaving room for different
pagination strategies later.

Controllers and views should interact with Gridline's table abstraction, not
directly with the pagination library.

## Dynamic Rendering

Search inputs should submit `GET` requests to the same resource route. Stimulus
may debounce typing and target the relevant Turbo Frame. The server rebuilds the
table state from query params and returns updated server-rendered HTML.

The frontend may show loading state while the request is in flight, but the
backend remains responsible for determining which rows exist, how they are
ordered, and which page is being displayed.

## Dashboard Tables

Dashboard tables are workflow summaries. They may use the same table system in a
compact mode, or they may show a small fixed slice with a link to the full index
page.

Dashboard tables should not grow indefinitely. When a dashboard user needs data
exploration controls, the dashboard should link to the corresponding index table
or render the shared table component in compact mode.

## Test And Demo Data

Table behavior needs data volume to be meaningful.

Tests should create only the records needed for the behavior under test. Table
tests should use deterministic records for pagination thresholds, backend
filtering, backend sorting, filtered pagination recalculation, authorization
scope enforcement, page reset behavior, and param whitelisting.

Demo data should be larger and presentation-friendly. It should include enough
customers, sites, providers, statuses, priorities, and reported timestamps to
exercise pagination, search, sorting, filtering, role scoping, and compact
dashboard summaries in the browser.
