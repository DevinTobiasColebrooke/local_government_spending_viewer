class CreateSpendingReports < ActiveRecord::Migration[8.0]
  def change
    create_table :spending_reports do |t|
      t.string :data_gov_id
      t.string :agency_name
      t.string :department_name
      t.text :description
      t.decimal :amount, precision: 15, scale: 2
      t.date :transaction_date
      t.string :category
      t.jsonb :metadata

      # Add the vector column with 768 dimensions (standard for local embeddings)
      t.vector :embedding, limit: 768

      t.timestamps
    end

    add_index :spending_reports, :data_gov_id, unique: true
    add_index :spending_reports, :agency_name
    add_index :spending_reports, :department_name
    add_index :spending_reports, :category

    # Optional: Add HNSW index for faster vector search if dataset is large (>10k rows)
    # add_index :spending_reports, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
