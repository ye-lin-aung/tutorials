module Tutorials
  # The engine's base controller. Inherits from the host app's ApplicationController
  # so it picks up host helpers like `current_user`, but it does NOT want the
  # host's auth flow (which typically redirects to a login page that has no
  # JSON format and would 500 on engine API requests).
  #
  # Strategy: prepend our own auth check at the very front of the callback
  # chain. If current_user is missing, we render JSON 401. Rails halts the
  # remaining before_action chain automatically once `performed?` is true, so
  # any subsequent host auth callback (like `redirect_to new_session_path`)
  # never fires.
  class ApplicationController < Tutorials.parent_controller_class
    protect_from_forgery with: :null_session
    prepend_before_action :tutorials_require_current_user

    private

    def tutorials_require_current_user
      return if current_user
      render json: { error: "unauthorized" }, status: :unauthorized
    end

    # Some host apps have a `current_user` method, others have `Current.user`,
    # others use `warden.user`. We try them in order. Override this in a host
    # initializer if your app exposes the current user differently.
    unless method_defined?(:current_user) || private_method_defined?(:current_user)
      def current_user
        if defined?(Current) && Current.respond_to?(:user)
          Current.user
        elsif request.env["warden"]
          request.env["warden"].user
        end
      end
    end
  end
end
