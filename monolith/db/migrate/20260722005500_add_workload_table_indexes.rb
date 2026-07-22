class AddWorkloadTableIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :service_requests, %i[status priority reported_at], name: "index_service_requests_on_status_priority_reported"
    add_index :service_requests, %i[assigned_dispatcher_id reported_at], name: "index_service_requests_on_dispatcher_reported"
    add_index :service_requests, %i[customer_site_id reported_at], name: "index_service_requests_on_site_reported"
    add_index :service_requests, %i[service_provider_id reported_at], name: "index_service_requests_on_provider_reported"

    add_index :customer_sites, %i[customer_id name], name: "index_customer_sites_on_customer_name"
    add_index :customer_sites, %i[site_status name], name: "index_customer_sites_on_status_name"

    add_index :service_providers, %i[status name], name: "index_service_providers_on_status_name"
    add_index :service_providers, %i[provider_type name], name: "index_service_providers_on_type_name"

    add_index :users, %i[active name], name: "index_users_on_active_name"
    add_index :users, %i[role name], name: "index_users_on_role_name"

    add_index :roles, :name, name: "index_roles_on_name"
    add_index :user_role_assignments, %i[resource_type role_id], name: "index_user_role_assignments_on_resource_type_role"
    add_index :user_role_assignments, %i[role_id user_id], name: "index_user_role_assignments_on_role_user"
    add_index :role_permissions, %i[permission_id role_id], name: "index_role_permissions_on_permission_role"
  end
end
