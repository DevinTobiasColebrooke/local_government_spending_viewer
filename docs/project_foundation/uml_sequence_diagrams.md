# UML Sequence Diagrams

Use [Mermaid.js](https://mermaid.js.org/syntax/sequenceDiagram.html) syntax to document complex logic.

## Critical Paths

### Spending Report Search and Categorization Flow
```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant RailsApp
    participant SpendingReportsController
    participant DataGovService
    participant EmbeddingService
    participant LocalLlmService
    participant SpendingReportModel
    participant PostgreSQL

    User->>Browser: Navigates to /spending_reports
    Browser->>RailsApp: GET /spending_reports
    RailsApp->>SpendingReportsController: #index action
    SpendingReportsController-->>Browser: Renders search form and initial empty turbo_frame

    User->>Browser: Enters keywords/agency in search form
    Browser->>RailsApp: Submits form (data-turbo-frame="spending_results")
    RailsApp->>SpendingReportsController: #search action (or #index with params)

    SpendingReportsController->>DataGovService: fetch_spending_data(query_params)
    DataGovService->>Data.gov API: HTTP GET /schools (e.g., for education spending)
    Data.gov API-->>DataGovService: Returns JSON data
    DataGovService-->>SpendingReportsController: Returns parsed spending entries

    loop For each spending entry from Data.gov
        SpendingReportsController->>EmbeddingService: generate(entry.description)
        EmbeddingService->>LocalLlmService: API request to local Ollama Embedding server
        LocalLlmService-->>EmbeddingService: Returns embedding vector
        EmbeddingService-->>SpendingReportsController: Returns embedding vector

        SpendingReportsController->>LocalLlmService: chat(entry.description, system_message: Prompt.get('system.data_analyst'))
        LocalLlmService->>LocalLlmService: API request to local Ollama LLM server for categorization
        LocalLlmService-->>SpendingReportsController: Returns categorized string (e.g., "Personnel")

        SpendingReportsController->>SpendingReportModel: create_or_update(entry_data, embedding, category)
        SpendingReportModel->>PostgreSQL: INSERT/UPDATE into 'spending_reports' table
        PostgreSQL-->>SpendingReportModel: Success/Failure
    end

    SpendingReportsController->>SpendingReportModel: semantic_search(user_query) OR filter_by_keywords(user_query)
    SpendingReportModel->>PostgreSQL: SELECT * FROM spending_reports WHERE ... ORDER BY embedding <-> query_vector
    PostgreSQL-->>SpendingReportModel: Returns matched spending reports
    SpendingReportModel-->>SpendingReportsController: Returns ActiveRecord objects

    SpendingReportsController-->>Browser: Renders partial for 'spending_results' turbo_frame with results
    Browser-->>User: Updates the 'spending_results' section of the page with new data