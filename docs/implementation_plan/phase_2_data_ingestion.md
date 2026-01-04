# Phase 2: Data Ingestion (ETL)

**Goal**: Establish a robust pipeline to fetch, normalize, and store raw government spending data from external APIs (Data.gov / Socrata).

## Objectives
- [ ] Implement a specific API adapter for a spending dataset.
- [ ] Map external JSON fields to the `SpendingReport` schema.
- [ ] Ensure idempotency (no duplicate records).
- [ ] Automate the process via a Rake task.

## Step 1: Identify the Dataset
For this implementation, we will use the **State of Iowa - Liquor Sales** dataset (frequently used as a proxy for high-volume transaction data) OR a **City Vendor Payments** dataset. 

- **Source**: Socrata (Data.gov compatible)
- **API Endpoint**: `https://data.iowa.gov/resource/4i7z-6y4p.json`
- **Key Fields**: 
  - `invoice_line_no` -> `data_gov_id`
  - `item_description` -> `description`
  - `sale_dollars` -> `amount`
  - `date` -> `transaction_date`
  - `category_name` -> `category` (initial raw category)

## Step 2: Implement the Service
Update `app/services/data_gov_service.rb`. This service handles the HTTP request and the mapping of raw data into our database.

```ruby
class DataGovService < ApplicationApiService
  ENDPOINT = "https://data.iowa.gov/resource/4i7z-6y4p.json"

  def ingest_recent(limit: 50)
    # 1. Fetch data from API
    raw_data = get(ENDPOINT, { "$limit" => limit, "$order" => "date DESC" })
    return 0 unless raw_data.is_a?(Array)

    count = 0
    raw_data.each do |entry|
      # 2. Skip if already exists (Idempotency)
      external_id = entry["invoice_line_no"]
      next if SpendingReport.exists?(data_gov_id: external_id)

      # 3. Create record
      SpendingReport.create!(
        data_gov_id: external_id,
        agency_name: "State of Iowa", # Hardcoded for this source
        department_name: entry["category_name"] || "General",
        description: entry["item_description"],
        amount: entry["sale_dollars"].to_f,
        transaction_date: Date.parse(entry["date"]),
        metadata: entry # Store raw JSON for future reference
      )
      count += 1
    end
    count
  end
end
```

## Step 3: Create the Automation Task
Create a Rake task to allow manual or scheduled triggers of the ingestion process.

Create `lib/tasks/ingestion.rake`:

```ruby
namespace :ingestion do
  desc "Fetch latest spending data from Data.gov"
  task fetch: :environment do
    puts "Starting ingestion..."
    service = DataGovService.new
    count = service.ingest_recent(limit: 100)
    puts "Successfully ingested #{count} new records."
  end
end
```

## Step 4: Verification
Test the ingestion pipeline from the command line.

1. Run the Rake task:
   ```bash
   bin/rails ingestion:fetch
   ```

2. Verify records in the database:
   ```bash
   bin/rails c
   ```
   ```ruby
   # Check the latest record
   report = SpendingReport.last
   puts report.description
   puts report.amount
   
   # Ensure no duplicates if run again
   DataGovService.new.ingest_recent(limit: 10) # Should return 0
   ```

## Phase Checklist
- [ ] API endpoint returns valid JSON.
- [ ] `DataGovService` correctly maps external fields to internal attributes.
- [ ] Rake task completes without errors.
- [ ] Running the task twice does not create duplicate `data_gov_id` records.
```