class ApplicationApiService
  def initialize
    @conn = Faraday.new do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  protected

  def get(url, params = {})
    response = @conn.get(url, params)
    handle_response(response)
  end

  def handle_response(response)
    if response.success?
      response.body
    else
      Rails.logger.error "API Error: #{response.status} - #{response.body}"
      nil
    end
  end
end
