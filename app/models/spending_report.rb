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

  # Combine keyword search and semantic search
  def self.search_for(query)
    return all.order(transaction_date: :desc).limit(50) if query.blank?

    # 1. Start with keyword search
    results = where("description ILIKE ? OR agency_name ILIKE ?", "%#{query}%", "%#{query}%")

    # 2. Try to generate a vector for semantic search
    # If the AI service is up, this usually provides better results for concepts
    query_vector = EmbeddingService.generate(query)

    if query_vector
      # Use pgvector nearest neighbor search
      # This finds records conceptually similar even if keywords don't match exactly
      semantic_results = nearest_neighbors(:embedding, query_vector, distance: "cosine")
      results = semantic_results
    end

    results.limit(50)
  end

  # Wrapper for semantic search (kept for compatibility with docs, mapped to search_for)
  def self.semantic_search(query_text)
    search_for(query_text)
  end
end
