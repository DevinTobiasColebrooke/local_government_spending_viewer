class DataGovService < ApplicationApiService
  # Using State of Iowa - Liquor Sales as a proxy for high-volume transaction data
  # Source: https://data.iowa.gov/resource/4i7z-6y4p.json
  ENDPOINT = "https://data.iowa.gov/resource/4i7z-6y4p.json"

  def initialize(api_key: ENV["DATA_GOV_KEY"])
    super()
    @api_key = api_key
  end

  def ingest_recent(limit: 50)
    Rails.logger.info "Fetching #{limit} records from #{ENDPOINT}..."

    # 1. Fetch data from API (Socrata SODA API)
    # Socrata uses $limit and $order parameters
    raw_data = get(ENDPOINT, { "$limit" => limit, "$order" => "date DESC" })

    unless raw_data.is_a?(Array)
      Rails.logger.error "Data ingestion failed: Expected Array, got #{raw_data.class}"
      return 0
    end

    count = 0
    raw_data.each do |entry|
      # 2. Skip if already exists (Idempotency)
      # invoice_line_no is unique in this dataset
      external_id = entry["invoice_line_no"]

      if external_id.blank?
        Rails.logger.warn "Skipping entry with missing invoice_line_no"
        next
      end

      next if SpendingReport.exists?(data_gov_id: external_id)

      # 3. Create record
      report = SpendingReport.create!(
        data_gov_id: external_id,
        agency_name: "State of Iowa", # Hardcoded for this specific source
        department_name: entry["category_name"] || "General",
        description: entry["item_description"] || "Unspecified Item",
        amount: entry["sale_dollars"].to_f,
        transaction_date: parse_date(entry["date"]),
        category: entry["category_name"], # Initial raw category, will be refined by AI later
        metadata: entry # Store raw JSON for future reference
      )

      # 4. Trigger AI Enrichment
      EnrichSpendingReportJob.perform_later(report)

      count += 1
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create report #{external_id}: #{e.message}"
    end

    count
  end

  private

  def parse_date(date_string)
    return Date.today if date_string.blank?
    Date.parse(date_string)
  rescue Date::Error
    Date.today
  end
end
