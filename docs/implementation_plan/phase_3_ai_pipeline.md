# Phase 3: AI Pipeline

**Goal**: Enrich ingested records by generating vector embeddings for semantic search and using a Local LLM to categorize spending into standardized buckets.

## Objectives
- [ ] Configure specialized AI prompts for categorization.
- [ ] Implement background processing to avoid blocking the ingestion flow.
- [ ] Connect `SpendingReport` to `EmbeddingService` and `LocalLlmService`.

## Step 1: Configure AI Prompts
Standardize the output of the Local LLM by defining a strict system prompt.

Update `config/prompts.yml`:

```yaml
system:
  # ... existing prompts ...
  categorizer: >
    You are a civic data analyst. Analyze the following expense description and 
    assign exactly ONE category from this list: 
    [Personnel, Infrastructure, Services, Supplies, Debt, Other]. 
    Respond only with the category name.

user:
  categorize_expense: "Description: %{description}"
```

## Step 2: Create the Enrichment Job
Since AI calls are slow (1-5 seconds per record), we must process them in the background.

Create `app/jobs/enrich_spending_report_job.rb`:

```ruby
class EnrichSpendingReportJob < ApplicationJob
  queue_as :default
  
  # Prevent multiple attempts on AI timeout to avoid server load
  discard_on StandardError do |job, error|
    Rails.logger.error "AI Enrichment failed for report #{job.arguments.first.id}: #{error.message}"
  end

  def perform(report)
    # 1. Generate Vector Embedding
    embedding = EmbeddingService.generate(report.description)
    
    # 2. Get AI Category
    llm = LocalLlmService.new
    system_prompt = Prompt.get("system.categorizer")
    user_prompt = Prompt.get("user.categorize_expense", description: report.description)
    
    ai_category = llm.chat(user_prompt, system_message: system_prompt)

    # 3. Update Record
    report.update!(
      embedding: embedding,
      category: ai_category
    )
  end
end
```

## Step 3: Trigger Enrichment during Ingestion
Update the service from Phase 2 to enqueue a job for every new record.

Update `app/services/data_gov_service.rb`:

```ruby
# Inside the .each loop in ingest_recent
report = SpendingReport.create!(...)
EnrichSpendingReportJob.perform_later(report)
```

## Step 4: Create a Backfill Task
For records already in the database without embeddings or categories, we need a way to process them in bulk.

Update `lib/tasks/ingestion.rake`:

```ruby
namespace :ingestion do
  # ... existing fetch task ...

  desc "Process AI enrichment for pending records"
  task enrich_pending: :environment do
    pending = SpendingReport.where(embedding: nil)
    puts "Enqueuing enrichment for #{pending.count} records..."
    pending.find_each do |report|
      EnrichSpendingReportJob.perform_later(report)
    end
  end
end
```

## Step 5: Verification
1. Ensure your Local Llama batch script is running on the Windows host.
2. Run the ingestion:
   ```bash
   bin/rails ingestion:fetch
   ```
3. Start the background worker (default in Rails 8 is `bin/jobs` for Solid Queue):
   ```bash
   bin/jobs
   ```
4. Check the records after processing:
   ```ruby
   # In rails console
   report = SpendingReport.where.not(category: nil).last
   puts report.category # Should be "Supplies", "Personnel", etc.
   puts report.embedding.to_a # Should be a long array of numbers
   ```

## Phase Checklist
- [ ] `config/prompts.yml` includes the categorizer prompt.
- [ ] `EnrichSpendingReportJob` handles AI service errors gracefully.
- [ ] Ingestion service triggers a background job for new records.
- [ ] `backfill` task successfully enqueues pending records.
```