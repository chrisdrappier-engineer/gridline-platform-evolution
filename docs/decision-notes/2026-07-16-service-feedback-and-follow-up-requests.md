# 2026-07-16: Service Feedback And Follow-Up Requests

## Related Issue

- [Issue 20: Add facility manager feedback and service ratings](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/20)

## Context

Issue 20 began as service completion ratings and facility-manager feedback.
During planning, the user raised an important workflow question: what happens
when completed work still requires more work?

The initial simple answer, "put in a new request," was too loose because it
would lose the connection between the completed work and the follow-up work.

## Decision

Follow-up work is represented as a new service request linked to the original
service request.

The original request may have multiple follow-up requests. Each follow-up keeps
normal request behavior: its own lifecycle, provider assignment, quote, costs,
notes, evidence, metrics, and completion review.

The original request shows its follow-up requests. A follow-up request shows
the request it follows up from.

## Rationale

A follow-up is operationally new work, but contextually linked work.

Keeping follow-ups as ordinary service requests avoids overloading completion
feedback, notes, or status fields with new work. It also supports realistic
cases where separate follow-up items need different providers, priorities,
timelines, costs, evidence, or approvals.

The first UI pass intentionally avoids a recursive tree view. A compact
`Follow-Up To` and `Follow-Up Requests` section is enough to make the
relationship visible without turning the request page into a case-management
screen.

## Implementation Shape

- `ServiceRequestFeedback` stores one completion review per request.
- Feedback includes a 1-5 rating, text feedback, and a `follow_up_needed` flag.
- `ServiceRequest` has an optional `follow_up_to_service_request_id`.
- `ServiceRequest` has many `follow_up_service_requests`.
- Facility managers can submit feedback for resolved requests in their scoped
  facilities.
- Dispatcher/admin users can create linked follow-up requests from resolved
  requests.
- Demo seeds include service feedback and an original request with multiple
  follow-up requests.
- Playwright coverage exercises the workflow through visible browser
  navigation.

## AI Involvement

Codex helped evaluate whether follow-up work should be a note, a status, or a
new linked request. The user challenged the workflow semantics and asked how
multiple follow-ups should be represented in the UI. The resulting design keeps
the data model simple while preserving a realistic operational relationship
between completed work and newly discovered work.
