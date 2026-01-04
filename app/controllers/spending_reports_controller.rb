class SpendingReportsController < ApplicationController
  def index
    @query = params[:q]
    @reports = SpendingReport.search_for(@query)

    # Respond to Turbo Frame requests by rendering only the partial
    if turbo_frame_request?
      render partial: "reports_list", locals: { reports: @reports }
    else
      render :index
    end
  end
end
