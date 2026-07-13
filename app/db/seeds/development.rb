require "faker"

Faker::Config.locale = "en-US"
Faker::Config.random = Random.new(20_260_710)
Faker::UniqueGenerator.clear

roles = [
  ["dev-dispatcher@gridline.test", "dispatcher"],
  ["dev-manager@gridline.test", "operations_manager"],
  ["dev-admin@gridline.test", "admin"],
  ["dev-facility-manager@gridline.test", "facility_manager"],
  ["dev-customer-contact@gridline.test", "customer_contact"],
  ["dev-provider-user@gridline.test", "service_provider_user"]
]

users = roles.to_h do |email, role|
  user = SeedData.upsert(
    User,
    { email: email },
    name: Faker::Name.name,
    role: role,
    active: true
  )

  [role, user]
end

providers = [
  ["Development Internal Team", "internal_team"],
  ["Development Vendor Partner", "vendor_partner"]
].map do |name, provider_type|
  SeedData.upsert(
    ServiceProvider,
    { name: name },
    provider_type: provider_type,
    status: "active",
    created_by: users.fetch("admin")
  )
end

customers = 3.times.map do |index|
  SeedData.upsert(
    Customer,
    { name: "Dev #{Faker::Company.unique.name}" },
    account_status: Customer::ACCOUNT_STATUSES[index % Customer::ACCOUNT_STATUSES.length],
    industry: Faker::Company.industry.parameterize(separator: "_"),
    created_by: users.fetch("operations_manager")
  )
end

sites = customers.flat_map.with_index do |customer, customer_index|
  2.times.map do |site_index|
    SeedData.upsert(
      CustomerSite,
      { customer: customer, name: "#{customer.name} Site #{site_index + 1}" },
      address_line_1: Faker::Address.street_address,
      address_line_2: site_index.zero? ? "Suite #{Faker::Number.number(digits: 3)}" : nil,
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      postal_code: Faker::Address.zip_code,
      site_status: CustomerSite::SITE_STATUSES[(customer_index + site_index) % CustomerSite::SITE_STATUSES.length],
      created_by: users.fetch("dispatcher")
    )
  end
end

request_titles = [
  "Intermittent HVAC alarm",
  "Dock keypad failure",
  "Ceiling leak report",
  "Exterior lighting outage",
  "Restroom fixture repair",
  "Loading bay door inspection"
]

sites.each_with_index do |site, index|
  SeedData.upsert(
    ServiceRequest,
    { customer_site: site, title: request_titles.fetch(index) },
    service_provider: providers[index % providers.length],
    created_by: users.fetch("dispatcher"),
    assigned_dispatcher: index.even? ? nil : users.fetch("dispatcher"),
    description: Faker::Lorem.paragraph(sentence_count: 2),
    priority: ServiceRequest::PRIORITIES[index % ServiceRequest::PRIORITIES.length],
    status: ServiceRequest::STATUSES[index % ServiceRequest::STATUSES.length],
    reported_at: Time.zone.parse("2026-07-10 08:00:00") + index.hours
  )
end

RbacSeedData.assign_role(users.fetch("dispatcher"), "dispatcher")
RbacSeedData.assign_role(users.fetch("admin"), "admin")
RbacSeedData.assign_role(users.fetch("facility_manager"), "facility_manager", resource: sites.first)
RbacSeedData.assign_role(users.fetch("customer_contact"), "customer_contact", resource: customers.first)
RbacSeedData.assign_role(users.fetch("service_provider_user"), "service_provider_user", resource: providers.last)
