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

    # Engine controllers must NOT run the host's auth before_actions. Those
    # callbacks tend to call `redirect_to new_session_path` (or similar)
    # without scoping to `main_app`, and named-route resolution inside an
    # engine controller looks at the engine's url_helpers first — which
    # don't have host routes. The result is UrlGenerationError 500s for
    # unauthenticated visitors. Instead we skip the host's auth callbacks
    # (best-effort: raise:false handles hosts that don't define them) and
    # run our own check below.
    skip_before_action :require_authentication,  raise: false  # school-management style
    skip_before_action :authenticate_user!,      raise: false  # Devise style

    # Some hosts populate Current.user / current_user via the same auth
    # before_action we just skipped. Call the host's session-resume helper
    # if it exists so Current.session (and therefore Current.user) is
    # populated for genuine logged-in visitors.
    prepend_before_action :tutorials_resume_host_session
    before_action         :tutorials_require_current_user

    private

    def tutorials_resume_host_session
      resume_session if respond_to?(:resume_session, true)
    end

    def tutorials_require_current_user
      return if current_user
      if request.format.html?
        redirect_to "/", allow_other_host: false
      else
        render json: { error: "unauthorized" }, status: :unauthorized
      end
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
