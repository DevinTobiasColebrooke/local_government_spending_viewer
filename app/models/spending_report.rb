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

  # Combine keyword search and semantic search with resilience
  def self.search_for(query)
    return all.order(transaction_date: :desc).limit(50) if query.blank?

    begin
      # 1. Try to generate a vector for semantic search
      # If the AI service is up, this usually provides better results for concepts
      query_vector = EmbeddingService.generate(query)

      if query_vector
        # Use pgvector nearest neighbor search
        return nearest_neighbors(:embedding, query_vector, distance: "cosine").limit(50)
      end
    rescue StandardError => e
      # Log warning but continue to keyword search
      Rails.logger.warn "AI Search failed, falling back to keywords: #{e.message}"
    end

    # 2. Fallback to keyword search (AI offline or returned nil)
    filter_by_text(query).order(transaction_date: :desc).limit(50)
  end

  # Wrapper for semantic search (kept for compatibility with docs, mapped to search_for)
  def self.semantic_search(query_text)
    search_for(query_text)
  end
end
