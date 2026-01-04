namespace :ingestion do
  desc "Fetch latest spending data from Data.gov (Iowa Liquor Sales Proxy)"
  task fetch: :environment do
    puts "Starting ingestion..."

    # Default to 50, or allow override via LIMIT env var
    limit = ENV.fetch("LIMIT", 50).to_i

    service = DataGovService.new
    count = service.ingest_recent(limit: limit)

    puts "Successfully ingested #{count} new records."
  end

  desc "Process AI enrichment for pending records"
  task enrich_pending: :environment do
    # Find records that haven't been embedded yet
    pending = SpendingReport.where(embedding: nil)
    puts "Enqueuing enrichment for #{pending.count} records..."

    pending.find_each do |report|
      EnrichSpendingReportJob.perform_later(report)
    end
  end
end
