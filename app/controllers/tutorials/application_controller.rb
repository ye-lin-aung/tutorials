module Tutorials
  # The engine's base controller. Inherits from the host app's ApplicationController
  # when one is defined (so it picks up host helpers like `current_user`), or from
  # ActionController::Base when running in isolation (e.g., the engine's own dummy
  # app during testing).
  class ApplicationController < Tutorials.parent_controller_class
    protect_from_forgery with: :null_session
    before_action :require_current_user

    private

    def require_current_user
      return if current_user
      render json: { error: "unauthorized" }, status: :unauthorized
    end
  end
end
