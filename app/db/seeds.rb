module SeedData
  module_function

  def upsert(model, lookup, attributes = {})
    record = model.find_or_initialize_by(lookup)
    record.assign_attributes(attributes)
    record.save!
    record
  end

  def enabled?(name)
    ActiveModel::Type::Boolean.new.cast(ENV.fetch(name, false))
  end
end

load Rails.root.join("db/seeds/rbac.rb")
RbacSeedData.seed_definitions

unless SeedData.enabled?("SEED_BASELINE_ONLY")
  if SeedData.enabled?("SEED_DEMO_DATA")
    load Rails.root.join("db/seeds/demo.rb")
  else
    load Rails.root.join("db/seeds/development.rb")
  end
end
