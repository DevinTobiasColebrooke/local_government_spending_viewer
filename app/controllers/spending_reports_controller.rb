class SpendingReportsController < ApplicationController
  def index
    @query = params[:q]

    # Track the search event if a query is present
    if @query.present?
      ahoy.track "Search", query: @query
    end

    @reports = SpendingReport.search_for(@query)

    # Respond to Turbo Frame requests by rendering only the partial
    if turbo_frame_request?
      render partial: "reports_list", locals: { reports: @reports }
    else
      render :index
    end
  end

  def show
    @report = SpendingReport.find(params[:id])
    # Convenience accessor for the metadata hash
    @meta = @report.metadata || {}
  end
end
