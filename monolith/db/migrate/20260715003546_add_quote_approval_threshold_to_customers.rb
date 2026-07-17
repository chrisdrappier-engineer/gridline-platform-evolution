class AddQuoteApprovalThresholdToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :quote_approval_threshold_cents, :integer, null: false, default: 50_000
  end
end
