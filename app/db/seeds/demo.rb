dispatcher = SeedData.upsert(
  User,
  { email: "dispatcher@gridline.test" },
  name: "Dana Dispatcher",
  role: "dispatcher",
  active: true
)

manager = SeedData.upsert(
  User,
  { email: "manager@gridline.test" },
  name: "Morgan Manager",
  role: "operations_manager",
  active: true
)

admin = SeedData.upsert(
  User,
  { email: "admin@gridline.test" },
  name: "Avery Admin",
  role: "admin",
  active: true
)

facility_manager = SeedData.upsert(
  User,
  { email: "facility.manager@magnoliaproperty.test" },
  name: "Riley Facility Manager",
  role: "facility_manager",
  active: true
)

red_clay_facility_manager = SeedData.upsert(
  User,
  { email: "facility.manager@redclaylogistics.test" },
  name: "Jordan Dock Manager",
  role: "facility_manager",
  active: true
)

harbor_pine_facility_manager = SeedData.upsert(
  User,
  { email: "facility.manager@harborpine.test" },
  name: "Harper Market Manager",
  role: "facility_manager",
  active: true
)

customer_contact = SeedData.upsert(
  User,
  { email: "customer.contact@magnoliaproperty.test" },
  name: "Casey Customer Contact",
  role: "customer_contact",
  active: true
)

provider_user = SeedData.upsert(
  User,
  { email: "provider.user@coastalcoldchain.test" },
  name: "Taylor Provider User",
  role: "service_provider_user",
  active: true
)

internal_provider = SeedData.upsert(
  ServiceProvider,
  { name: "Gridline Internal Dispatch Team" },
  provider_type: "internal_team",
  status: "active",
  created_by: admin
)

southeast_vendor = SeedData.upsert(
  ServiceProvider,
  { name: "Southeast Vendor Partner" },
  provider_type: "vendor_partner",
  status: "active",
  created_by: admin
)

cold_chain_provider = SeedData.upsert(
  ServiceProvider,
  { name: "Coastal Cold Chain Services" },
  provider_type: "vendor_partner",
  status: "active",
  created_by: admin
)

magnolia = SeedData.upsert(
  Customer,
  { name: "Magnolia Property Group" },
  account_status: "active",
  industry: "property_management",
  created_by: manager
)

red_clay = SeedData.upsert(
  Customer,
  { name: "Red Clay Logistics" },
  account_status: "active",
  industry: "warehousing",
  created_by: manager
)

harbor_pine = SeedData.upsert(
  Customer,
  { name: "Harbor & Pine Retail Cooperative" },
  account_status: "onboarding",
  industry: "retail",
  created_by: manager
)

facility_managers_by_customer_name = {
  magnolia.name => facility_manager,
  red_clay.name => red_clay_facility_manager,
  harbor_pine.name => harbor_pine_facility_manager
}

magnolia_midtown = SeedData.upsert(
  CustomerSite,
  { customer: magnolia, name: "Magnolia Midtown Atlanta" },
  address_line_1: "1180 Peachtree St NE",
  address_line_2: "Lobby Level",
  city: "Atlanta",
  state: "GA",
  postal_code: "30309",
  site_status: "active",
  facility_manager_id: facility_managers_by_customer_name.fetch(magnolia.name).id,
  created_by: dispatcher
)

magnolia_buckhead = SeedData.upsert(
  CustomerSite,
  { customer: magnolia, name: "Magnolia Buckhead Commons" },
  address_line_1: "3340 Peachtree Rd NE",
  address_line_2: "Suite 120",
  city: "Atlanta",
  state: "GA",
  postal_code: "30326",
  site_status: "active",
  facility_manager_id: facility_managers_by_customer_name.fetch(magnolia.name).id,
  created_by: dispatcher
)

red_clay_dock = SeedData.upsert(
  CustomerSite,
  { customer: red_clay, name: "Red Clay South Dock" },
  address_line_1: "2400 Logistics Way",
  address_line_2: "Dock 4",
  city: "Macon",
  state: "GA",
  postal_code: "31216",
  site_status: "active",
  facility_manager_id: facility_managers_by_customer_name.fetch(red_clay.name).id,
  created_by: dispatcher
)

red_clay_cold_storage = SeedData.upsert(
  CustomerSite,
  { customer: red_clay, name: "Red Clay Cold Storage" },
  address_line_1: "88 Harbor Industrial Blvd",
  address_line_2: nil,
  city: "Savannah",
  state: "GA",
  postal_code: "31408",
  site_status: "active",
  facility_manager_id: facility_managers_by_customer_name.fetch(red_clay.name).id,
  created_by: dispatcher
)

harbor_pine_market = SeedData.upsert(
  CustomerSite,
  { customer: harbor_pine, name: "Harbor & Pine Savannah Market" },
  address_line_1: "201 Bay Market Walk",
  address_line_2: "Food Court",
  city: "Savannah",
  state: "GA",
  postal_code: "31401",
  site_status: "active",
  facility_manager_id: facility_managers_by_customer_name.fetch(harbor_pine.name).id,
  created_by: dispatcher
)

SeedData.upsert(
  ServiceRequest,
  { customer_site: magnolia_midtown, title: "Lobby HVAC failure" },
  service_provider: internal_provider,
  created_by: dispatcher,
  assigned_dispatcher: nil,
  description: "Tenant reports warm air and intermittent fan noise in the main lobby.",
  priority: "urgent",
  status: "new",
  reported_at: Time.zone.parse("2026-07-10 08:15:00")
)

SeedData.upsert(
  ServiceRequest,
  { customer_site: red_clay_dock, title: "Dock door sensor misalignment" },
  service_provider: southeast_vendor,
  created_by: dispatcher,
  assigned_dispatcher: dispatcher,
  description: "South dock sensor intermittently reports blocked state after closing.",
  priority: "normal",
  status: "triaged",
  reported_at: Time.zone.parse("2026-07-10 09:05:00")
)

SeedData.upsert(
  ServiceRequest,
  { customer_site: red_clay_cold_storage, title: "Freezer temperature alarm" },
  service_provider: cold_chain_provider,
  created_by: dispatcher,
  assigned_dispatcher: dispatcher,
  description: "Freezer monitoring alarm triggered twice during the morning receiving window.",
  priority: "urgent",
  status: "in_progress",
  reported_at: Time.zone.parse("2026-07-10 09:40:00")
)

SeedData.upsert(
  ServiceRequest,
  { customer_site: harbor_pine_market, title: "Restroom leak near food court" },
  service_provider: southeast_vendor,
  created_by: dispatcher,
  assigned_dispatcher: nil,
  description: "Customer reports water pooling near the east food court restroom entrance.",
  priority: "high",
  status: "new",
  reported_at: Time.zone.parse("2026-07-10 10:10:00")
)

SeedData.upsert(
  ServiceRequest,
  { customer_site: magnolia_buckhead, title: "Elevator inspection follow-up" },
  service_provider: internal_provider,
  created_by: manager,
  assigned_dispatcher: manager,
  description: "Follow up on inspection findings before the next tenant move-in.",
  priority: "low",
  status: "scheduled",
  reported_at: Time.zone.parse("2026-07-10 11:30:00")
)

additional_provider_specs = [
  ["Palmetto Ridge Facilities", "vendor_partner"],
  ["Lowcountry Mechanical Group", "vendor_partner"],
  ["Peachtree Electrical Services", "vendor_partner"],
  ["Blue Ridge Access Control", "vendor_partner"],
  ["Gulfstream Plumbing Response", "vendor_partner"],
  ["Gridline Regional Maintenance", "internal_team"]
]

additional_providers = additional_provider_specs.map do |name, provider_type|
  SeedData.upsert(
    ServiceProvider,
    { name: name },
    provider_type: provider_type,
    status: "active",
    created_by: admin
  )
end

demo_providers = [
  internal_provider,
  southeast_vendor,
  cold_chain_provider,
  *additional_providers
]

additional_customer_specs = [
  ["Palmetto Ridge Communities", "property_management", "active"],
  ["Bluewater Distribution Group", "warehousing", "active"],
  ["Piedmont Medical Offices", "healthcare", "active"],
  ["Riverbend Student Housing", "property_management", "active"],
  ["Cypress Grove Hospitality", "hospitality", "active"],
  ["Atlantic Light Manufacturing", "light_manufacturing", "active"],
  ["Queen City Storage Partners", "self_storage", "onboarding"],
  ["Live Oak Senior Living", "senior_living", "active"],
  ["Foothills Retail Centers", "retail", "active"]
]

additional_customers = additional_customer_specs.map do |name, industry, account_status|
  SeedData.upsert(
    Customer,
    { name: name },
    account_status: account_status,
    industry: industry,
    created_by: manager
  )
end

additional_customers.each do |customer|
  facility_managers_by_customer_name[customer.name] = SeedData.upsert(
    User,
    { email: "facility.manager@#{customer.name.parameterize}.test" },
    name: "#{customer.name.split.first} Facility Manager",
    role: "facility_manager",
    active: true
  )
end

site_specs = [
  ["Palmetto Ridge Communities", "Palmetto Ridge Lakewood", "410 Lakewood Dr", nil, "Orlando", "FL", "32803"],
  ["Palmetto Ridge Communities", "Palmetto Ridge Winter Park", "620 Park Ave N", "Clubhouse", "Winter Park", "FL", "32789"],
  ["Palmetto Ridge Communities", "Palmetto Ridge Kissimmee", "911 Cypress Pkwy", nil, "Kissimmee", "FL", "34741"],
  ["Bluewater Distribution Group", "Bluewater Charleston Crossdock", "77 Crossdock Ln", "Dock 12", "North Charleston", "SC", "29418"],
  ["Bluewater Distribution Group", "Bluewater Greenville Fulfillment", "1320 Fulfillment Rd", nil, "Greenville", "SC", "29605"],
  ["Bluewater Distribution Group", "Bluewater Columbia Returns", "455 Garners Ferry Rd", "Bay C", "Columbia", "SC", "29209"],
  ["Piedmont Medical Offices", "Piedmont Midtown Clinic", "901 W Trade St", "Suite 300", "Charlotte", "NC", "28202"],
  ["Piedmont Medical Offices", "Piedmont Cary Plaza", "120 Health Park Dr", nil, "Cary", "NC", "27518"],
  ["Piedmont Medical Offices", "Piedmont Durham Specialty", "44 Research Way", "Building B", "Durham", "NC", "27709"],
  ["Riverbend Student Housing", "Riverbend Athens Commons", "315 College Ave", nil, "Athens", "GA", "30601"],
  ["Riverbend Student Housing", "Riverbend Auburn Lofts", "801 Magnolia Ave", "Leasing Office", "Auburn", "AL", "36830"],
  ["Riverbend Student Housing", "Riverbend Tallahassee Flats", "522 Gaines St", nil, "Tallahassee", "FL", "32301"],
  ["Cypress Grove Hospitality", "Cypress Grove Gulf Shores", "181 Beach Blvd", nil, "Gulf Shores", "AL", "36542"],
  ["Cypress Grove Hospitality", "Cypress Grove Savannah Riverfront", "33 River St", "Kitchen Level", "Savannah", "GA", "31401"],
  ["Cypress Grove Hospitality", "Cypress Grove Asheville", "70 Biltmore Ave", nil, "Asheville", "NC", "28801"],
  ["Atlantic Light Manufacturing", "Atlantic Light Mobile Plant", "2400 Industrial Canal Rd", nil, "Mobile", "AL", "36602"],
  ["Atlantic Light Manufacturing", "Atlantic Light Augusta Assembly", "500 Innovation Dr", "Line 2", "Augusta", "GA", "30901"],
  ["Atlantic Light Manufacturing", "Atlantic Light Chattanooga Works", "880 Riverport Rd", nil, "Chattanooga", "TN", "37406"],
  ["Queen City Storage Partners", "Queen City Uptown Storage", "220 Graham St", nil, "Charlotte", "NC", "28202"],
  ["Queen City Storage Partners", "Queen City Concord Annex", "810 Speedway Blvd", "Office", "Concord", "NC", "28027"],
  ["Queen City Storage Partners", "Queen City Rock Hill", "145 Textile Way", nil, "Rock Hill", "SC", "29730"],
  ["Live Oak Senior Living", "Live Oak Decatur Residence", "210 Clairmont Ave", "Front Desk", "Decatur", "GA", "30030"],
  ["Live Oak Senior Living", "Live Oak Greenville Commons", "370 Pelham Rd", nil, "Greenville", "SC", "29615"],
  ["Live Oak Senior Living", "Live Oak Jacksonville Harbor", "660 Riverside Ave", nil, "Jacksonville", "FL", "32204"],
  ["Foothills Retail Centers", "Foothills Knoxville Market", "850 Kingston Pike", "Suite 101", "Knoxville", "TN", "37919"],
  ["Foothills Retail Centers", "Foothills Huntsville Plaza", "2900 Memorial Pkwy SW", nil, "Huntsville", "AL", "35801"],
  ["Foothills Retail Centers", "Foothills Birmingham Shops", "310 Summit Blvd", "Security Office", "Birmingham", "AL", "35243"]
]

customers_by_name = ([magnolia, red_clay, harbor_pine] + additional_customers).index_by(&:name)

additional_sites = site_specs.each_with_index.map do |(customer_name, name, address_line_1, address_line_2, city, state, postal_code), index|
  site_status = if index % 11 == 0
                  "inactive"
                elsif index % 7 == 0
                  "temporarily_closed"
                else
                  "active"
                end

  SeedData.upsert(
    CustomerSite,
    { customer: customers_by_name.fetch(customer_name), name: name },
    address_line_1: address_line_1,
    address_line_2: address_line_2,
    city: city,
    state: state,
    postal_code: postal_code,
    site_status: site_status,
    facility_manager_id: site_status == "active" ? facility_managers_by_customer_name.fetch(customer_name).id : nil,
    created_by: dispatcher
  )
end

demo_sites = [
  magnolia_midtown,
  magnolia_buckhead,
  red_clay_dock,
  red_clay_cold_storage,
  harbor_pine_market,
  *additional_sites
]

request_templates = [
  ["HVAC rooftop unit alarm", "Rooftop unit reported a fault during morning startup."],
  ["Access control reader offline", "Badge reader is intermittently rejecting valid staff credentials."],
  ["Exterior lighting outage", "Multiple exterior fixtures are dark near a customer entrance."],
  ["Loading dock door inspection", "Dock door is moving slowly and needs inspection before peak receiving."],
  ["Restroom leak response", "Water is pooling near a restroom fixture and needs containment."],
  ["Fire panel trouble signal", "Panel is reporting a trouble condition after the overnight inspection."],
  ["Freezer temperature variance", "Cold storage temperature drifted outside the expected range."],
  ["Elevator service follow-up", "Vendor follow-up is needed after recurring elevator fault codes."],
  ["Parking gate motor noise", "Gate motor is grinding during open and close cycles."],
  ["Roof drain blockage", "Standing water was observed near a roof drain after heavy rain."]
]

base_reported_at = Time.zone.parse("2026-06-03 07:30:00")

demo_sites.each_with_index do |site, site_index|
  6.times do |request_index|
    title, description = request_templates.fetch((site_index + request_index) % request_templates.length)
    sequence = (site_index * 6) + request_index + 1
    status = ServiceRequest::STATUSES[(site_index + request_index) % ServiceRequest::STATUSES.length]

    SeedData.upsert(
      ServiceRequest,
      { customer_site: site, title: "#{title} ##{sequence.to_s.rjust(3, "0")}" },
      service_provider: demo_providers[(site_index + request_index) % demo_providers.length],
      created_by: dispatcher,
      assigned_dispatcher: request_index.even? ? dispatcher : nil,
      description: description,
      priority: ServiceRequest::PRIORITIES[(site_index + request_index) % ServiceRequest::PRIORITIES.length],
      status: status,
      reported_at: base_reported_at + sequence.hours,
      provider_response_summary: status == "resolved" ? "Completed service visit and confirmed normal operation." : nil,
      follow_up_notes: status == "resolved" ? "Monitor for recurrence during the next operating cycle." : nil,
      provider_work_completed_at: status == "resolved" ? base_reported_at + sequence.hours + 2.hours : nil,
      completion_verified_at: status == "resolved" ? base_reported_at + sequence.hours + 3.hours : nil,
      completion_verified_by: status == "resolved" ? facility_manager : nil
    )
  end
end

ServiceRequest.includes(customer_site: :customer).where(customer_site: demo_sites).order(:reported_at, :title).each_with_index do |request, index|
  assigned_at = nil
  provider_responded_at = nil
  scheduled_at = nil
  provider_work_completed_at = nil
  completion_verified_at = nil
  completion_verified_by = nil
  resolved_at = nil
  canceled_at = nil
  provider_response_summary = nil
  follow_up_notes = nil

  unless request.status == "new"
    assigned_at = request.reported_at + (15 + (index % 6) * 5).minutes
  end

  if %w[scheduled in_progress resolved canceled].include?(request.status) || (request.status == "triaged" && index % 3 != 0)
    provider_responded_at = assigned_at + (20 + (index % 8) * 10).minutes
    provider_response_summary = "Provider acknowledged the request and confirmed the initial service plan."
  end

  if %w[scheduled in_progress resolved].include?(request.status)
    scheduled_at = provider_responded_at + (1 + (index % 4)).hours
  end

  if request.status == "resolved"
    provider_work_completed_at = scheduled_at + (2 + (index % 5)).hours
    resolved_at = provider_work_completed_at + (15 + (index % 4) * 10).minutes
    follow_up_notes = "Work completed; monitor site conditions during the next operating cycle."

    if index.even?
      completion_verified_at = resolved_at + (30 + (index % 5) * 15).minutes
      completion_verified_by = facility_managers_by_customer_name.fetch(request.customer_site.customer.name)
    end
  elsif request.status == "canceled"
    canceled_at = assigned_at + (45 + (index % 6) * 15).minutes
    follow_up_notes = "Canceled after customer or dispatcher review."
  end

  request.update!(
    assigned_at: assigned_at,
    provider_responded_at: provider_responded_at,
    scheduled_at: scheduled_at,
    provider_work_completed_at: provider_work_completed_at,
    completion_verified_at: completion_verified_at,
    completion_verified_by: completion_verified_by,
    resolved_at: resolved_at,
    canceled_at: canceled_at,
    provider_response_summary: provider_response_summary,
    follow_up_notes: follow_up_notes
  )
end

ServiceRequest.includes(customer_site: :customer).where(customer_site: demo_sites).order(:reported_at, :title).each_with_index do |request, index|
  threshold_cents = request.quote_approval_threshold_cents
  quoted_amount_cents = if index % 5 == 0
                          threshold_cents + 35_000 + (index * 1_250)
                        elsif index % 7 == 0
                          threshold_cents + 10_000 + (index * 900)
                        else
                          18_000 + (index * 1_175)
                        end
  quoted_amount_cents = [quoted_amount_cents, 225_000].min
  approval_required = quoted_amount_cents > threshold_cents
  submitted_at = request.reported_at + 30.minutes
  facility_manager_for_site = facility_managers_by_customer_name.fetch(request.customer_site.customer.name)
  status_sequence = index % 8

  quote_attributes = {
    created_by: dispatcher,
    amount_cents: quoted_amount_cents,
    currency: "USD",
    description: "Quoted service scope for #{request.title.downcase}.",
    status: "approved",
    approval_required: approval_required,
    submitted_at: submitted_at,
    approved_by: nil,
    approved_at: nil,
    rejected_by: nil,
    rejected_at: nil,
    approval_notes: ServiceRequestQuote::AUTO_APPROVAL_NOTE,
    amendment_reason: nil,
    amended_by: nil,
    amended_at: nil,
    original_amount_cents: nil
  }

  if approval_required
    case status_sequence
    when 0, 5
      quote_attributes.merge!(
        status: "approved",
        approved_by: facility_manager_for_site,
        approved_at: submitted_at + 2.hours,
        approval_notes: "Approved for scheduled service under the customer maintenance policy."
      )
    when 7
      quote_attributes.merge!(
        status: "rejected",
        rejected_by: facility_manager_for_site,
        rejected_at: submitted_at + 90.minutes,
        approval_notes: "Rejected pending additional clarification from Gridline dispatch."
      )
    else
      quote_attributes.merge!(
        status: "pending_approval",
        approval_notes: nil
      )
    end
  end

  if index % 9 == 0
    quote_attributes.merge!(
      amount_cents: quoted_amount_cents + 18_000,
      original_amount_cents: quoted_amount_cents,
      amendment_reason: "Provider discovered additional site conditions requiring amended scope.",
      amended_by: dispatcher,
      amended_at: submitted_at + 45.minutes
    )

    if quote_attributes[:amount_cents] > threshold_cents
      quote_attributes[:approval_required] = true
      unless quote_attributes[:approved_by]
        quote_attributes[:status] = "pending_approval"
        quote_attributes[:approved_at] = nil
        quote_attributes[:approval_notes] = nil
      end
    end
  end

  SeedData.upsert(ServiceRequestQuote, { service_request: request }, quote_attributes)

  labor_cents = (quote_attributes[:amount_cents] * (82 + (index % 9)) / 100.0).round
  SeedData.upsert(
    ServiceRequestCost,
    { service_request: request, category: "labor", description: "Labor and dispatch time for #{request.title.downcase}." },
    recorded_by: dispatcher,
    amount_cents: [labor_cents, 12_000].max,
    currency: "USD",
    incurred_on: request.reported_at.to_date
  )

  next unless index.even?

  parts_cents = 4_500 + ((index % 6) * 2_750)
  SeedData.upsert(
    ServiceRequestCost,
    { service_request: request, category: "parts", description: "Parts and materials for #{request.title.downcase}." },
    recorded_by: dispatcher,
    amount_cents: parts_cents,
    currency: "USD",
    incurred_on: request.reported_at.to_date
  )
end

RbacSeedData.assign_role(dispatcher, "dispatcher")
RbacSeedData.assign_role(admin, "admin")
demo_sites.select { |site| site.site_status == "active" }.each do |site|
  RbacSeedData.assign_role(
    facility_managers_by_customer_name.fetch(site.customer.name),
    "facility_manager",
    resource: site
  )
end
RbacSeedData.assign_role(customer_contact, "customer_contact", resource: magnolia)
RbacSeedData.assign_role(provider_user, "service_provider_user", resource: cold_chain_provider)
