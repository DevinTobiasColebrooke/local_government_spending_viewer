class IngestionController < ApplicationController
  # This controller is intended for development use to manually trigger data fetches
  def fetch
    service = DataGovService.new
    # Fetch a small batch (default 50) to keep the request relatively quick
    count = service.ingest_recent

    redirect_back fallback_location: root_path, notice: "Successfully ingested #{count} new records."
  end
end
