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
