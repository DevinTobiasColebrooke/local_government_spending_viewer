# Phase 4: UI & Semantic Search

**Goal**: Build a reactive, single-page interface that allows users to perform both keyword-based filtering and AI-powered semantic search without page reloads.

## Objectives
- [ ] Implement the semantic search query logic in the `SpendingReport` model.
- [ ] Create a "Search-as-you-type" experience using Stimulus.
- [ ] Use Hotwire Turbo Frames to isolate result updates.
- [ ] Provide a clean, tabulated display for spending results.

## Step 1: Implement Search Logic
Update the `SpendingReport` model to handle both standard text filtering and vector-based semantic search.

Update `app/models/spending_report.rb`:

```ruby
class SpendingReport < ApplicationRecord
  has_neighbors :embedding

  # Combine keyword search and semantic search
  def self.search_for(query)
    return all.order(transaction_date: :desc) if query.blank?

    # 1. Try keyword search first for exact matches
    results = where("description ILIKE ? OR agency_name ILIKE ?", "%#{query}%", "%#{query}%")
    
    # 2. If results are low, or by default, add semantic results
    query_vector = EmbeddingService.generate(query)
    if query_vector
      semantic_results = nearest_neighbors(:embedding, query_vector, distance: "cosine")
      # Merge or prioritize semantic results
      results = semantic_results
    end

    results.limit(50)
  end
end
```

## Step 2: Build the Controller
The controller will handle the search requests and render only the Turbo Frame when requested.

Update `app/controllers/spending_reports_controller.rb`:

```ruby
class SpendingReportsController < ApplicationController
  def index
    @query = params[:q]
    @reports = SpendingReport.search_for(@query)

    # Respond to Turbo Frame requests by rendering only the partial
    render partial: "reports_list", locals: { reports: @reports } if turbo_frame_request?
  end
end
```

## Step 3: Create the Reactive View
Construct the main search page with a persistent search bar and a dynamic results frame.

Update `app/views/spending_reports/index.html.erb`:

```erb
<div class="max-w-6xl mx-auto py-10 px-4">
  <h1 class="text-3xl font-bold text-gray-900 mb-8">Civic Spending Search</h1>

  <!-- Search Form -->
  <div class="mb-8" data-controller="search">
    <%= form_with url: spending_reports_path, method: :get, 
                  data: { 
                    action: "input->search#submit",
                    turbo_frame: "spending_results" 
                  } do |f| %>
      <div class="relative">
        <%= f.text_field :q, value: @query, 
            placeholder: "Search by keyword or concept (e.g., 'school repairs')...", 
            class: "w-full p-4 pl-12 rounded-lg border border-gray-300 shadow-sm focus:ring-indigo-500 focus:border-indigo-500" %>
        <div class="absolute left-4 top-4 text-gray-400">
          <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
        </div>
      </div>
    <% end %>
  </div>

  <!-- Turbo Frame for Results -->
  <%= turbo_frame_tag "spending_results" do %>
    <%= render "reports_list", reports: @reports %>
  <% end %>
</div>
```

Create the partial `app/views/spending_reports/_reports_list.html.erb`:

```erb
<div class="bg-white shadow overflow-hidden sm:rounded-md">
  <ul role="list" class="divide-y divide-gray-200">
    <% reports.each do |report| %>
      <li class="p-4 hover:bg-gray-50">
        <div class="flex items-center justify-between">
          <div class="flex-1">
            <p class="text-sm font-medium text-indigo-600 truncate"><%= report.agency_name %></p>
            <p class="text-lg text-gray-900 font-semibold"><%= report.description %></p>
            <div class="mt-2 flex items-center text-sm text-gray-500">
              <span class="mr-4"><%= report.transaction_date.strftime("%b %d, %Y") %></span>
              <span class="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs uppercase"><%= report.category %></span>
            </div>
          </div>
          <div class="text-right">
            <p class="text-xl font-bold text-gray-900"><%= number_to_currency(report.amount) %></p>
          </div>
        </div>
      </li>
    <% end %>
  </ul>
  <% if reports.empty? %>
    <p class="p-10 text-center text-gray-500">No reports found matching your search.</p>
  <% end %>
</div>
```

## Step 4: Add the Stimulus Search Controller
This controller handles the "instant" submission and prevents flooding the server by debouncing inputs.

Create `app/javascript/controllers/search_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form" ]

  connect() {
    this.timeout = null
  }

  submit() {
    clearTimeout(this.timeout)
    // Wait 300ms after typing stops before submitting
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
}
```

## Step 5: Verification
1. Navigate to `/spending_reports`.
2. Type a specific keyword (e.g., "WHISKEY"). Verify the table updates instantly.
3. Type a concept (e.g., "Education supplies"). Even if the word "Education" isn't in the description, AI semantic search should surface relevant items based on the vector distance calculated in Phase 3.
4. Inspect network tab: verify that only a `turbo-frame` snippet is being returned from the server.

## Phase Checklist
- [ ] `SpendingReport.search_for` handles semantic vector generation.
- [ ] Search input debounces correctly (doesn't hit server on every keystroke).
- [ ] Results update without a browser refresh via `turbo_frame`.
- [ ] Interface is responsive and clean using Tailwind classes.
```