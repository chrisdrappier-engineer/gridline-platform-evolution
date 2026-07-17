# Gridline Domain Model

This document defines the initial facilities operations domain for Gridline's
mature monolith baseline.

The model is intentionally small. It should be credible enough to support
dispatch workflows, SLA tracking, demo data, and request specs, but restrained
enough that the first implementation remains focused on the scaling story.

## Domain Summary

Gridline manages facilities maintenance work for multi-location commercial
customers.

A customer has many sites. A site can submit service requests. Service requests
become work orders. Dispatchers assign work orders to available technicians.
Technicians move work through the lifecycle. Each meaningful change creates a
work order event. Dispatchers and managers use the dispatch board and summary
reports to understand open work, SLA risk, and operational load.

## Core Entities

### Customer

A commercial account served by Gridline.

Suggested attributes:

- `name`
- `account_tier`
- `active`

Suggested `account_tier` values:

- `standard`
- `priority`
- `national`

Relationships:

- has many `sites`
- has many `service_requests` through `sites`

### Site

A physical customer location where facilities work happens.

Suggested attributes:

- `customer_id`
- `name`
- `address_line_1`
- `city`
- `region`
- `postal_code`
- `timezone`
- `active`

Relationships:

- belongs to `customer`
- has many `service_requests`

### Technician

A Gridline field technician who can be assigned to work orders.

Suggested attributes:

- `name`
- `region`
- `status`
- `skill_set`

Suggested `status` values:

- `available`
- `assigned`
- `off_duty`
- `inactive`

Relationships:

- has many `work_orders`

Implementation note:

`skill_set` can start as a simple string or serialized list. The baseline does
not need a separate skills table unless later behavior earns it.

### ServiceRequest

A request for facilities maintenance at a customer site.

Suggested attributes:

- `site_id`
- `requester_name`
- `category`
- `priority`
- `description`
- `status`
- `requested_at`

Suggested `category` values:

- `hvac`
- `plumbing`
- `electrical`
- `refrigeration`
- `doors`
- `general`

Suggested `priority` values:

- `emergency`
- `high`
- `normal`

Suggested `status` values:

- `new`
- `triaged`
- `converted_to_work_order`
- `cancelled`

Relationships:

- belongs to `site`
- has one `work_order`

### WorkOrder

The operational unit Gridline dispatchers and technicians work through.

Suggested attributes:

- `service_request_id`
- `technician_id`
- `status`
- `priority`
- `scheduled_for`
- `sla_deadline`
- `started_at`
- `completed_at`

Suggested `status` values:

- `open`
- `assigned`
- `in_progress`
- `completed`
- `cancelled`

Relationships:

- belongs to `service_request`
- belongs to `technician`, optional until assignment
- has many `work_order_events`

### WorkOrderEvent

An audit trail entry for important work order changes.

Suggested attributes:

- `work_order_id`
- `actor_type`
- `actor_name`
- `event_type`
- `notes`
- `created_at`

Suggested `actor_type` values:

- `dispatcher`
- `technician`
- `system`

Suggested `event_type` values:

- `created`
- `assigned`
- `started`
- `completed`
- `cancelled`
- `sla_risk_flagged`

Relationships:

- belongs to `work_order`

## Core Workflows

### Submit Service Request

A customer contact or dispatcher creates a service request for a site.

Expected result:

- service request is created with `new` status
- priority and category are recorded
- request timestamp is captured

Scaling relevance:

- customer-facing write path
- future candidate for rate limiting and idempotency

### Triage And Create Work Order

A dispatcher converts a service request into an operational work order.

Expected result:

- service request moves to `converted_to_work_order`
- work order is created with `open` status
- SLA deadline is calculated from priority
- `created` event is recorded

Scaling relevance:

- transaction boundary between request intake and operational work
- source of data for dispatch board reads

### Assign Technician

A dispatcher assigns an available technician to an open work order.

Expected result:

- work order moves to `assigned`
- technician is associated with the work order
- technician status moves to `assigned`
- `assigned` event is recorded

Scaling relevance:

- consistency-sensitive write
- later multiple app instances must not double-assign work

### Start Work

A technician starts the assigned work.

Expected result:

- work order moves to `in_progress`
- `started_at` is recorded
- `started` event is recorded

Scaling relevance:

- field update path
- session behavior becomes visible once multiple web instances exist

### Complete Work

A technician completes the work order.

Expected result:

- work order moves to `completed`
- `completed_at` is recorded
- technician can become `available`
- `completed` event is recorded

Scaling relevance:

- field write path
- report and dispatch board data changes

## Business Rules

SLA deadlines:

- `emergency` requests get a 4-hour SLA
- `high` priority requests get an 8-hour SLA
- `normal` priority requests get a 2-business-day SLA

Workflow rules:

- a service request must belong to an active site
- a work order cannot be completed before assignment
- a work order cannot be started before assignment
- only available technicians can be assigned
- every status change creates a `WorkOrderEvent`
- completed work orders must record `completed_at`

Dispatch board rules:

- open, assigned, and in-progress work orders appear on the dispatch board
- completed and cancelled work orders do not appear as active work
- work is `at_risk` when the SLA deadline is near
- work is `overdue` when the SLA deadline has passed

Initial SLA risk definition:

- `at_risk` means the SLA deadline is within the next hour
- `overdue` means the SLA deadline is before the current time

## Reporting Needs

The baseline should support a simple daily summary report:

- service requests created today
- work orders completed today
- open work orders
- at-risk work orders
- overdue work orders

This report intentionally runs synchronously in the baseline. That limitation
helps motivate the later background jobs scenario.

## Out Of Scope For The Baseline

The initial domain model should not include:

- invoices
- contracts
- purchase orders
- parts inventory
- vendor marketplace workflows
- technician geolocation
- photo uploads
- customer approval workflows
- full authentication and authorization
- multi-region routing rules

These are plausible future extensions, but they are not required to establish
the mature monolith baseline.

## Implementation Guidance

The Rails implementation should keep the domain modular inside the monolith.

Suggested service and query objects:

```text
monolith/app/services/service_requests/create.rb
monolith/app/services/service_requests/convert_to_work_order.rb
monolith/app/services/work_orders/assign_technician.rb
monolith/app/services/work_orders/start.rb
monolith/app/services/work_orders/complete.rb
monolith/app/queries/dispatch_board_query.rb
monolith/app/queries/daily_summary_query.rb
```

Suggested request spec coverage:

- create service request
- convert request to work order
- assign technician
- start work order
- complete work order
- fetch dispatch board
- fetch daily summary

Suggested model or service spec coverage:

- emergency SLA deadline calculation
- high-priority SLA deadline calculation
- normal SLA deadline calculation
- assignment rejects unavailable technicians
- completion rejects unassigned work orders
- lifecycle changes create audit events
