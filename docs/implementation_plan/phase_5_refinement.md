# Phase 5: Refinement & Observability

**Goal**: Harden the application for production use by optimizing database performance, implementing user analytics, and ensuring the AI pipeline is resilient to failures.

## Objectives
- [ ] Eliminate N+1 queries and optimize database indices.
- [ ] Track activist search behavior using Ahoy analytics.
- [ ] Implement graceful fallbacks for when Local Llama is unavailable.
- [ ] Apply rate limiting to protect resource-intensive AI endpoints.

## Step 1: Database & Query Optimization
We will use the `Bullet` gem (configured in Phase 0) to identify N+1 queries. Additionally, we need to ensure our indices support common sorting and filtering patterns.

### 1. Additional Indices
Create a migration to add indices for common filtering columns.
```bash
bin/rails g migration AddPerformanceIndicesToSpendingReports
```

Update the migration file:
```ruby
class AddPerformanceIndicesToSpendingReports < ActiveRecord::Migration[8.0]
  def change
    add_index :spending_reports, :transaction_date
    add_index :spending_reports, [:category, :transaction_date]
  end
end
```

### 2. Query Refinement
In `SpendingReportsController`, ensure we are only selecting necessary fields if the dataset becomes massive, and use `includes` if we add associated models (like `Agency` or `User`).

## Step 2: Search Analytics
To better serve civic activists, we need to know what they are searching for. We will use the `Ahoy` gem to track search queries.

Update `app/controllers/spending_reports_controller.rb`:
```ruby
def index
  @query = params[:q]
  
  # Track the search event
  if @query.present?
    ahoy.track "Search", query: @query
  end

  @reports = SpendingReport.search_for(@query)
  # ...
end
```

## Step 3: AI Resilience & Fallbacks
AI services can be slow or go offline. The application must remain functional even if the Windows host running Ollama is unreachable.

Update `app/models/spending_report.rb`:
```ruby
def self.search_for(query)
  return all.order(transaction_date: :desc) if query.blank?

  begin
    # 1. Attempt Semantic Search (requires Ollama)
    query_vector = EmbeddingService.generate(query)
    if query_vector
      return nearest_neighbors(:embedding, query_vector, distance: "cosine").limit(50)
    end
  rescue StandardError => e
    # 2. Fallback to Keyword Search if AI is offline
    Rails.logger.warn "AI Search failed, falling back to keywords: #{e.message}"
  end

  # Standard ILIKE search as safety net
  where("description ILIKE ? OR agency_name ILIKE ?", "%#{query}%", "%#{query}%")
    .limit(50)
end
```

## Step 4: Rate Limiting
Since generating embeddings and processing LLM requests is CPU-intensive, we must protect these actions from abuse using `Rack::Attack`.

Update `config/initializers/rack_attack.rb`:
```ruby
class Rack::Attack
  # Limit search requests per IP to prevent AI server exhaustion
  throttle("spending_search/ip", limit: 30, period: 1.minute) do |req|
    if req.path == "/spending_reports" && req.get?
      req.ip
    end
  end
end
```

## Step 5: Final Verification & Cleanup
1. **Load Test**: Use the backfill task from Phase 3 to process 1,000+ records and monitor CPU usage on the AI host.
2. **Resilience Test**: Stop the `llama-server` on your Windows host. Attempt a search in the UI. Ensure the app displays "Keyword" results instead of a 500 error.
3. **Analytics Check**: 
   ```ruby
   # In rails console
   Ahoy::Event.where(name: "Search").last.properties
   ```

## Phase Checklist
- [ ] No N+1 query alerts triggered by `Bullet`.
- [ ] Database indices exist for `transaction_date`.
- [ ] `Ahoy` records search queries in the `ahoy_events` table.
- [ ] Application remains functional when `LOCAL_LLM_URL` is unreachable.
- [ ] `Rack::Attack` blocks excessive search requests.
```