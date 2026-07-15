# Rails Generator History

This file records Rails generator commands used to create or modify repository
files.

Keep this history factual and concise. Context and rationale belong in commit
messages, ADRs, decision notes, and pull request descriptions.

## Commands


### 2026-07-09

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-new --database=postgresql --skip-git --skip-docker --skip-kamal --skip-devcontainer --skip-ci --skip-solid --force`

### 2026-07-09

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model User email:string name:string role:string active:boolean`

### 2026-07-09

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model Customer name:string account_status:string industry:string created_by:references`

### 2026-07-09

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model CustomerSite customer:references name:string address_line_1:string address_line_2:string city:string state:string postal_code:string site_status:string created_by:references`

### 2026-07-09

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model ServiceProvider name:string provider_type:string status:string created_by:references`

### 2026-07-09

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model ServiceRequest customer_site:references service_provider:references created_by:references assigned_dispatcher:references title:string description:text priority:string status:string reported_at:datetime`

### 2026-07-10

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model Role key:string name:string description:text`

### 2026-07-10

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model Permission resource:string action:string name:string description:text`

### 2026-07-10

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model RolePermission role:references permission:references`

### 2026-07-10

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model UserRoleAssignment user:references role:references resource:references\{polymorphic\}`

### 2026-07-14

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate migration AddQuoteApprovalThresholdToCustomers quote_approval_threshold_cents:integer`

### 2026-07-14

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model ServiceRequestCost service_request:references recorded_by:references category:string amount_cents:integer currency:string incurred_on:date description:text`

### 2026-07-14

- Rails `8.1.3`; Ruby image `ruby:4.0.5-slim`; command: `bin/rails-generate model ServiceRequestQuote service_request:references created_by:references amount_cents:integer currency:string description:text status:string approval_required:boolean submitted_at:datetime approved_by:references approved_at:datetime rejected_by:references rejected_at:datetime approval_notes:text amendment_reason:text amended_by:references amended_at:datetime original_amount_cents:integer`
