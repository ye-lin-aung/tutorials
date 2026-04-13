module Tutorials
  # Returns the list of tours that should be visible to a user on a given path.
  # Call from ApplicationController#set_available_tours in host apps.
  module Availability
    module_function

    # Returns an Array<Tutorials::Tour>. Safe: returns [] on DB failure.
    def for(user:, path:)
      matching = Registry.all.select { |t| t.matches_path?(path) }
      return [] if matching.empty?

      allowed  = matching.select { |t| Tutorials.config.authorized?(user: user, tour: t) }
      return [] if allowed.empty?

      completed_ids = UserTourProgress.completed_tour_ids_for(user: user, tour_ids: allowed.map(&:id))
      allowed.reject { |t| completed_ids.include?(t.id) }
    rescue ActiveRecord::ConnectionNotEstablished,
           ActiveRecord::StatementInvalid,
           ActiveRecord::NoDatabaseError
      []
    end

    # The single tour (or nil) that should auto-open on first login for this request.
    def auto_open_tour(user:, path:)
      return nil unless user
      return nil if user.respond_to?(:onboarded_at) && user.onboarded_at.present?

      self.for(user: user, path: path).find(&:first_login?)
    end
  end
end
