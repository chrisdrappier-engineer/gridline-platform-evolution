class CreateUserRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :user_role_assignments, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :role, null: false, foreign_key: true, type: :uuid
      t.references :resource, polymorphic: true, type: :uuid

      t.timestamps
    end

    add_check_constraint :user_role_assignments,
                         "(resource_type IS NULL AND resource_id IS NULL) OR (resource_type IS NOT NULL AND resource_id IS NOT NULL)",
                         name: "user_role_assignments_resource_presence"
    add_index :user_role_assignments,
              [:user_id, :role_id],
              unique: true,
              where: "resource_type IS NULL AND resource_id IS NULL",
              name: "index_user_role_assignments_on_global_role"
    add_index :user_role_assignments,
              [:user_id, :role_id, :resource_type, :resource_id],
              unique: true,
              where: "resource_type IS NOT NULL AND resource_id IS NOT NULL",
              name: "index_user_role_assignments_on_scoped_role"
  end
end
