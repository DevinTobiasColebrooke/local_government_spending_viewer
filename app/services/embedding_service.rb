class EmbeddingService
  def self.generate(text)
    # Check if the AI Config exists and has a local embedding URL
    if defined?(AiConfig::LOCAL_EMBEDDING_URL)
      generate_local(text)
    else
      Rails.logger.warn "No Embedding provider configured (AiConfig::LOCAL_EMBEDDING_URL missing)."
      nil
    end
  end

  private

  def self.generate_local(text)
    require "net/http"
    # Connects to http://192.168.x.x:8081/embeddings
    uri = URI("#{AiConfig::LOCAL_EMBEDDING_URL}/embeddings")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = { content: text }.to_json

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    json = JSON.parse(response.body)

    # Handle various response formats from different server versions
    # Standard OpenAI format vs Raw format
    (json["embedding"] || json.dig("data", 0, "embedding"))&.flatten&.map(&:to_f)
  rescue => e
    Rails.logger.error "Local Embedding Error: #{e.message}"
    nil
  end
end
