class DataGovService < ApplicationApiService
  # https://api.data.gov/
  BASE_URL = "https://api.data.gov/ed/collegescorecard/v1"

  def initialize(api_key: ENV["DATA_GOV_KEY"])
    super()
    @api_key = api_key
  end

  def search_schools(state: "CA")
    url = "#{BASE_URL}/schools"
    get(url, { api_key: @api_key, 'school.state_fips': state })
  end
end
