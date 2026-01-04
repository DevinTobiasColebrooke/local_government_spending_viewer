class DataGovService < ApplicationApiService
  # Using State of Iowa - Liquor Sales as a proxy for high-volume transaction data
  # Source: https://data.iowa.gov/resource/m3tr-qhgy.json
  ENDPOINT = "https://data.iowa.gov/resource/m3tr-qhgy.json"

  def initialize(api_key: ENV["DATA_GOV_KEY"])
    super()
    @api_key = api_key
  end

  def ingest_recent(limit: 50)
    Rails.logger.info "Fetching #{limit} records from #{ENDPOINT}..."

    # 1. Fetch data from API (Socrata SODA API)
    raw_data = get(ENDPOINT, { "$limit" => limit, "$order" => "date DESC" })

    unless raw_data.is_a?(Array)
      Rails.logger.error "Data ingestion failed: Expected Array, got #{raw_data.class}"
      return 0
    end

    count = 0
    raw_data.each do |entry|
      # 2. Skip if already exists (Idempotency)
      # Based on logs, the key is 'invoice_line_no'
      external_id = entry["invoice_line_no"]

      if external_id.blank?
        Rails.logger.warn "Skipping entry with missing invoice_line_no. Keys: #{entry.keys}"
        next
      end

      next if SpendingReport.exists?(data_gov_id: external_id)

      # 3. Create record
      # Mapping based on confirmed keys: invoice_line_no, im_desc, sale_dollars, date, category_name
      report = SpendingReport.create!(
        data_gov_id: external_id,
        agency_name: "State of Iowa",
        department_name: entry["category_name"] || "General",
        description: entry["im_desc"] || "Unspecified Item",
        amount: (entry["sale_dollars"] || 0).to_f,
        transaction_date: parse_date(entry["date"]),
        category: entry["category_name"],
        metadata: entry
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
