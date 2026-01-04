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
