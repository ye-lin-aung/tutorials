# Tutorials engine configuration.
#
# The authorize_with block decides whether a given user should see a given
# tour in the launcher / command palette. Route matching already filters by
# URL; this block is your place to enforce role or permission checks using
# whatever authorization library your app uses (Pundit, CanCan, custom).
#
# Default: allow signed-in users to see any tour whose route they can reach.
Tutorials.configure do |config|
  config.authorize_with do |user, tour|
    # Examples:
    #
    # # Pundit:
    # Pundit.policy(user, :tour).view?(tour)
    #
    # # Role-check via a method on User:
    # user.present? && user.active_memberships.any?
    #
    # # Deny for guests:
    # user.present? && !user.guest?
    user.present?
  end
end

# Add this before_action to your ApplicationController to expose the available
# tours to the layout helpers:
#
#   class ApplicationController < ActionController::Base
#     before_action :set_available_tours
#
#     private
#
#     def set_available_tours
#       return unless current_user
#       @tutorials_available  = Tutorials::Availability.for(user: current_user, path: request.path)
#       @tutorials_auto_open  = Tutorials::Availability.auto_open_tour(user: current_user, path: request.path)
#     end
#   end
