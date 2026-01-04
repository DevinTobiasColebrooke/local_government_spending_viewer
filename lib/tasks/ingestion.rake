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
end
