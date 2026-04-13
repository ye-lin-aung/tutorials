module Tutorials
  class ToursController < ApplicationController
    def show
      tour = Registry.find(params[:id])
      return head :not_found unless tour
      return head :forbidden unless Tutorials.config.authorized?(user: current_user, tour: tour)

      render json: tour.render_for_locale(I18n.locale)
    end

    def index
      path_param        = params[:path].to_s
      include_completed = ActiveModel::Type::Boolean.new.cast(params[:include_completed])

      available = Availability.for(user: current_user, path: path_param)

      tours = available
      if include_completed
        completed_ids = UserTourProgress
                          .where(user: current_user)
                          .where.not(completed_at: nil)
                          .pluck(:tour_id)
        extra = (Registry.all - available)
                  .select { |t| t.matches_path?(path_param) }
                  .select { |t| Tutorials.config.authorized?(user: current_user, tour: t) }
                  .select { |t| completed_ids.include?(t.id) }
        tours = available + extra
      end

      render json: tours.map { |t|
        payload = t.render_for_locale(I18n.locale).slice(:id, :title, :description, :first_login)
        if include_completed
          payload[:completed] = UserTourProgress
                                  .where(user: current_user, tour_id: t.id)
                                  .where.not(completed_at: nil)
                                  .exists?
        end
        payload
      }
    end
  end
end
