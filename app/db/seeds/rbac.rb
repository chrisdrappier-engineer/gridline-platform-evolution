module RbacSeedData
  module_function

  ROLES = [
    ["dispatcher", "Dispatcher", "Internal Gridline dispatcher."],
    ["facility_manager", "Facility Manager", "Customer-side site manager."],
    ["customer_contact", "Customer Contact", "Customer-side account contact."],
    ["service_provider_user", "Service Provider User", "Provider-side service user."],
    ["admin", "Admin", "Internal Gridline administrator."]
  ].freeze

  PERMISSIONS = [
    ["service_requests", "read", "Read service requests", "View service requests."],
    ["service_requests", "create", "Create service requests", "Create service requests."],
    ["service_requests", "update", "Update service requests", "Update service request details."],
    ["service_requests", "triage", "Triage service requests", "Triage service requests."],
    ["service_requests", "assign", "Assign service requests", "Assign service requests."],
    ["service_requests", "respond", "Respond to service requests", "Record service provider response details."],
    ["service_requests", "verify_completion", "Verify service request completion", "Verify completed service requests."],
    ["service_request_quotes", "read", "Read service request quotes", "View service request quote details."],
    ["service_request_quotes", "create", "Create service request quotes", "Create and submit service request quotes."],
    ["service_request_quotes", "update", "Update service request quotes", "Amend service request quotes."],
    ["service_request_quotes", "approve", "Approve service request quotes", "Approve service request quotes."],
    ["service_request_quotes", "reject", "Reject service request quotes", "Reject service request quotes."],
    ["service_request_costs", "read", "Read service request costs", "View actual service request costs."],
    ["service_request_costs", "create", "Create service request costs", "Record actual service request costs."],
    ["service_request_costs", "update", "Update service request costs", "Update actual service request costs."],
    ["service_request_notes", "read", "Read service request notes", "View service request notes allowed by visibility."],
    ["service_request_notes", "create", "Create service request notes", "Add service request notes allowed by visibility."],
    ["customers", "read", "Read customers", "View customer records."],
    ["customers", "create", "Create customers", "Create customer records."],
    ["customers", "update", "Update customers", "Update customer records."],
    ["customer_sites", "read", "Read customer sites", "View customer site records."],
    ["customer_sites", "create", "Create customer sites", "Create customer site records."],
    ["customer_sites", "update", "Update customer sites", "Update customer site records."],
    ["service_providers", "read", "Read service providers", "View service provider records."],
    ["service_providers", "create", "Create service providers", "Create service provider records."],
    ["service_providers", "update", "Update service providers", "Update service provider records."],
    ["roles", "read", "Read roles", "View role definitions."],
    ["role_permissions", "read", "Read role permissions", "View the role-to-permission matrix."],
    ["user_role_assignments", "read", "Read role assignments", "View user role assignments."],
    ["users", "read", "Read users", "View user records."]
  ].freeze

  ROLE_PERMISSIONS = {
    "dispatcher" => [
      ["service_requests", "read"],
      ["service_requests", "create"],
      ["service_requests", "update"],
      ["service_requests", "triage"],
      ["service_requests", "assign"],
      ["service_requests", "respond"],
      ["service_requests", "verify_completion"],
      ["service_request_quotes", "read"],
      ["service_request_quotes", "create"],
      ["service_request_quotes", "update"],
      ["service_request_costs", "read"],
      ["service_request_costs", "create"],
      ["service_request_costs", "update"],
      ["service_request_notes", "read"],
      ["service_request_notes", "create"],
      ["customers", "read"],
      ["customer_sites", "read"],
      ["service_providers", "read"]
    ],
    "facility_manager" => [
      ["service_requests", "read"],
      ["service_request_quotes", "read"],
      ["service_request_quotes", "approve"],
      ["service_request_quotes", "reject"],
      ["service_request_costs", "read"],
      ["service_request_notes", "read"],
      ["service_request_notes", "create"],
      ["customer_sites", "read"]
    ],
    "customer_contact" => [
      ["service_requests", "read"],
      ["service_request_quotes", "read"],
      ["service_request_costs", "read"],
      ["service_request_notes", "read"],
      ["service_request_notes", "create"],
      ["customers", "read"],
      ["customer_sites", "read"]
    ],
    "service_provider_user" => [
      ["service_requests", "read"],
      ["service_request_notes", "read"],
      ["service_request_notes", "create"],
      ["service_providers", "read"]
    ],
    "admin" => PERMISSIONS.map { |resource, action, _name, _description| [resource, action] }
  }.freeze

  def seed_definitions
    roles = ROLES.to_h do |key, name, description|
      role = SeedData.upsert(Role, { key: key }, name: name, description: description)
      [key, role]
    end

    permissions = PERMISSIONS.to_h do |resource, action, name, description|
      permission = SeedData.upsert(
        Permission,
        { resource: resource, action: action },
        name: name,
        description: description
      )
      [[resource, action], permission]
    end

    ROLE_PERMISSIONS.each do |role_key, permission_keys|
      role = roles.fetch(role_key)
      desired_permissions = permission_keys.map { |permission_key| permissions.fetch(permission_key) }

      role.role_permissions.where.not(permission_id: desired_permissions.map(&:id)).destroy_all

      desired_permissions.each do |permission|
        SeedData.upsert(RolePermission, { role: role, permission: permission })
      end
    end
  end

  def assign_role(user, role_key, resource: nil)
    role = Role.find_by!(key: role_key)
    assignment = UserRoleAssignment.find_or_initialize_by(user: user, role: role, resource: resource)
    assignment.save!
    assignment
  end
end
