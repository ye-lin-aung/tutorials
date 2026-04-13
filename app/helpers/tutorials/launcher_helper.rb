module Tutorials
  module LauncherHelper
    # Call in host layouts like:
    #   <%= render "tutorials/loader" %>
    #   ... later near page titles ...
    #   <%= render "tutorials/launcher" %>
    #
    # Both partials read @tutorials_available and @tutorials_auto_open set by
    # ApplicationController#set_available_tours.
    def tutorials_available_ids
      (@tutorials_available || []).map(&:id)
    end

    def tutorials_auto_open_id
      @tutorials_auto_open&.id
    end

    def any_tutorials_available?
      tutorials_available_ids.any?
    end
  end
end
