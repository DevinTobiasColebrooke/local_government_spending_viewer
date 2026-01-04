class AddPerformanceIndicesToSpendingReports < ActiveRecord::Migration[8.0]
  def change
    add_index :spending_reports, :transaction_date
    add_index :spending_reports, [ :category, :transaction_date ]
  end
end
