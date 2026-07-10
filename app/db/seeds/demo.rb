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

magnolia_midtown = SeedData.upsert(
  CustomerSite,
  { customer: magnolia, name: "Magnolia Midtown Atlanta" },
  address_line_1: "1180 Peachtree St NE",
  address_line_2: "Lobby Level",
  city: "Atlanta",
  state: "GA",
  postal_code: "30309",
  site_status: "active",
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
