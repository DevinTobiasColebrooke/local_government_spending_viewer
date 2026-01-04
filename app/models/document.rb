class Document < ApplicationRecord
has_neighbors :embedding

# Simple wrapper to find similar content
def self.semantic_search(query, limit: 5)
  # 1. Generate embedding for the query string
  query_vector = EmbeddingService.generate(query)
  return [] unless query_vector

  # 2. Search by nearest neighbor (Cosine Similarity)
  nearest_neighbors(:embedding, query_vector, distance: "cosine").limit(limit)
end
end
