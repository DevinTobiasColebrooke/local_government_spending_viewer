# Architecture Blueprint

## System Overview
The primary goal of this application is to provide local journalists and civic activists with a fast and intuitive way to search, filter, and categorize raw government spending reports. It ingests complex, raw spending data from external APIs, allowing for instant filtering by keywords or agency names, and leverages AI-powered categorization of line-item expenditures. The application is built as a Rails 8 monolith, utilizing Stimulus and Hotwire for a dynamic, single-page application (SPA)-like frontend experience. PostgreSQL, with the `pgvector` extension, serves as the database for efficient semantic searching, and local Ollama instances are integrated for AI-powered categorization and embedding generation.

## Tech Stack Decisions
- **Framework**: Rails 8 (Monolith)
- **Database**: PostgreSQL (with `pgvector` extension for vector embeddings)
- **Frontend**: Tailwind CSS + ERB (with Stimulus and Hotwire Turbo for interactivity)
- **AI**: Local Ollama (running via Windows Batch Script in WSL, configured in `config/initializers/ai_config.rb`) for Large Language Model (LLM) and Embedding services.

## Core Components
- **`SpendingReport` Model**: Stores raw government spending data, including textual descriptions, calculated `pgvector` embeddings for semantic search, AI-assigned categories, and any relevant metadata.
- **`DataGovService`**: An external service wrapper responsible for interacting with the Data.gov API to fetch raw spending data.
- **`EmbeddingService`**: Handles the generation of vector embeddings for spending report descriptions using a local Ollama embedding model.
- **`LocalLlmService`**: Manages interactions with a local Ollama LLM for AI-powered categorization of spending entries.
- **`SpendingReportsController`**: Manages the display of spending reports, handles search queries, and orchestrates the interaction with `DataGovService`, `EmbeddingService`, and `LocalLlmService`.
- **`HomeController`**: Serves as the application's root entry point.
- **Stimulus Controllers**: Manage UI state and interactions for search forms and dynamically updated content.
- **Hotwire Turbo**: Facilitates fast, smooth page updates by replacing parts of the page (e.g., search results) using `turbo_frame` elements without full page reloads.

## Data Flow

### Overall Application Data Flow
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
    
    User->>Browser: Access /spending_reports
    Browser->>RailsApp: GET /spending_reports
    RailsApp->>SpendingReportsController: Render initial search form
    SpendingReportsController-->>Browser: Display search form (empty results)

    User->>Browser: Enters search query and submits
    Browser->>RailsApp: POST /spending_reports (with query) via Turbo Frame
    RailsApp->>SpendingReportsController: Process search query

    SpendingReportsController->>DataGovService: Fetch raw spending data (e.g., by agency, keywords)
    DataGovService->>DataGovService: Process raw API response
    DataGovService-->>SpendingReportsController: Return structured spending data

    loop For each new or updated spending entry
        SpendingReportsController->>EmbeddingService: Generate embedding for description
        EmbeddingService->>LocalLlmService: Request embedding from local Ollama
        LocalLlmService-->>EmbeddingService: Return embedding vector
        EmbeddingService-->>SpendingReportsController: Return embedding vector

        SpendingReportsController->>LocalLlmService: Categorize description
        LocalLlmService->>LocalLlmService: Request categorization from local Ollama
        LocalLlmService-->>SpendingReportsController: Return category (e.g., "Personnel")

        SpendingReportsController->>SpendingReportModel: Create/Update SpendingReport (content, embedding, category, metadata)
        SpendingReportModel->>PostgreSQL: Save/Update record
        PostgreSQL-->>SpendingReportModel: Confirmation
    end

    SpendingReportsController->>SpendingReportModel: Query filtered/categorized reports (potentially semantic search using embeddings)
    SpendingReportModel->>PostgreSQL: Execute SQL query (with `ORDER BY embedding <-> query_vector`)
    PostgreSQL-->>SpendingReportModel: Return matching reports
    SpendingReportModel-->>SpendingReportsController: Return `SpendingReport` objects

    SpendingReportsController-->>Browser: Render search results (within Turbo Frame)
    Browser-->>User: Display updated list of spending reports