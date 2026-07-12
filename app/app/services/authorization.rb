class Authorization
  class AccessDenied < StandardError; end

  class << self
    def can?(user, resource:, action:, target: nil)
      assignments_for(user, resource, action).any? do |assignment|
        covers_target?(assignment, target)
      end
    end

    def authorize!(user, resource:, action:, target: nil)
      return true if can?(user, resource: resource, action: action, target: target)

      raise AccessDenied, "Not authorized to #{action} #{resource}"
    end

    def accessible_scope(user, resource:, action:, relation:)
      assignments = assignments_for(user, resource, action).to_a
      return relation.none if assignments.empty?
      return relation if assignments.any?(&:global?)

      scoped_relation(relation, scoped_resource_ids(assignments))
    end

    private

    def assignments_for(user, resource, action)
      UserRoleAssignment
        .joins(role: :permissions)
        .where(user: user, permissions: { resource: resource, action: action })
        .distinct
    end

    def covers_target?(assignment, target)
      return true if assignment.global?
      return false if target.blank?

      resource = assignment.resource

      case target
      when ServiceRequest
        resource == target.customer_site ||
          resource == target.customer_site.customer ||
          resource == target.service_provider
      when CustomerSite
        resource == target || resource == target.customer
      when Customer
        resource == target
      when ServiceProvider
        resource == target
      else
        resource == target
      end
    end

    def scoped_resource_ids(assignments)
      assignments.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |assignment, ids|
        ids[assignment.resource_type] << assignment.resource_id
      end
    end

    def scoped_relation(relation, resource_ids)
      case relation.klass.name
      when "ServiceRequest"
        service_request_scope(relation, resource_ids)
      when "CustomerSite"
        customer_site_scope(relation, resource_ids)
      when "Customer"
        customer_scope(relation, resource_ids)
      when "ServiceProvider"
        relation.where(id: resource_ids["ServiceProvider"])
      else
        relation.none
      end
    end

    def service_request_scope(relation, resource_ids)
      scope = relation.none

      if resource_ids["CustomerSite"].present?
        scope = scope.or(relation.where(customer_site_id: resource_ids["CustomerSite"]))
      end

      if resource_ids["Customer"].present?
        customer_site_ids = CustomerSite.where(customer_id: resource_ids["Customer"]).select(:id)
        scope = scope.or(relation.where(customer_site_id: customer_site_ids))
      end

      if resource_ids["ServiceProvider"].present?
        scope = scope.or(relation.where(service_provider_id: resource_ids["ServiceProvider"]))
      end

      scope
    end

    def customer_site_scope(relation, resource_ids)
      scope = relation.none

      if resource_ids["CustomerSite"].present?
        scope = scope.or(relation.where(id: resource_ids["CustomerSite"]))
      end

      if resource_ids["Customer"].present?
        scope = scope.or(relation.where(customer_id: resource_ids["Customer"]))
      end

      scope
    end

    def customer_scope(relation, resource_ids)
      scope = relation.none

      if resource_ids["Customer"].present?
        scope = scope.or(relation.where(id: resource_ids["Customer"]))
      end

      if resource_ids["CustomerSite"].present?
        customer_ids = CustomerSite.where(id: resource_ids["CustomerSite"]).select(:customer_id)
        scope = scope.or(relation.where(id: customer_ids))
      end

      scope
    end
  end
end
