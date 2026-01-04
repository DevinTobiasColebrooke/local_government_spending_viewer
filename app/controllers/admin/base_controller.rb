module Admin
  class BaseController < ApplicationController
    # Ensure only authenticated users can access admin
    # You should add a role check here (e.g., unless current_user.admin?)
    before_action :resume_session
    before_action :require_authentication

    layout "admin"
  end
end
