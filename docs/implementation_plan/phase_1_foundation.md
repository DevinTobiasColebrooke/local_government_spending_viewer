# Phase 1: Foundation & Data Modeling

**Goal**: Establish the database structure required to store government spending data and support vector search using PostgreSQL and `pgvector`.

## Prerequisites
- Ensure the `neighbor` and `pgvector` gems are in your `Gemfile` (already included).
- Ensure the Postgres database is running.

## Step 1: Database Migration
We need to create the table to store the spending data. We will index the text fields for standard filtering and the embedding column for AI search.

Run this command in your terminal:

```bash
bin/rails g model SpendingReport \
  data_gov_id:string:index \
  agency_name:string:index \
  department_name:string:index \
  description:text \
  amount:decimal{15,2} \
  transaction_date:date \
  category:string:index \
  metadata:jsonb
```

## Step 2: Add Vector Support
The default generator doesn't always handle vector dimensions perfectly via the command line. We need to manually add the `embedding` column with the specific dimension used by Local Llama (usually 768 for Nomic/BERT models).

Open the newly generated migration file (found in `db/migrate/`) and update it to look like this:

```ruby
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
```

Run the migration:

```bash
bin/rails db:migrate
```

## Step 3: Configure the Model
We need to tell the Rails model how to handle vector searches and validate data integrity.

Update `app/models/spending_report.rb`:

```ruby
class SpendingReport < ApplicationRecord
  # Enable nearest neighbor search on the embedding column
  has_neighbors :embedding

  validates :data_gov_id, uniqueness: true, allow_nil: true
  validates :amount, presence: true
  validates :description, presence: true

  # Scope for simple keyword filtering
  scope :filter_by_text, ->(query) { 
    where("description ILIKE ? OR agency_name ILIKE ?", "%#{query}%", "%#{query}%") 
  }

  # Wrapper for semantic search
  def self.semantic_search(query_text)
    # This requires the EmbeddingService to be active (Phase 3)
    # For Phase 1, we just define the structure.
    return none if query_text.blank?
    
    # Placeholder: In Phase 3, we generate the vector here.
    # vector = EmbeddingService.generate(query_text)
    # nearest_neighbors(:embedding, vector, distance: "cosine")
    none
  end
end
```

## Step 4: Verification
To ensure Phase 1 is complete, run the Rails console and check that we can create a record.

1. Open console:
   ```bash
   bin/rails c
   ```

2. Run this snippet:
   ```ruby
   SpendingReport.create!(
     agency_name: "Phase 1 Test",
     description: "Test Infrastructure",
     amount: 100.50,
     transaction_date: Date.today,
     metadata: { source: "manual" }
   )
   ```

3. Ensure it returns a green/success result (e.g., `#<SpendingReport id: 1 ...>`).

## Phase Checklist
- [ ] `spending_reports` table exists.
- [ ] `embedding` column exists with type `vector(768)`.
- [ ] Model `SpendingReport` has `has_neighbors`.
- [ ] Manual test creation succeeds.
```