module Tutorials
  class ProgressController < ApplicationController
    def update
      tour = Registry.find(params[:tour_id].to_s)
      return head :not_found unless tour

      record = UserTourProgress.upsert_for(user: current_user, tour_id: tour.id)
      record.last_step     = params[:last_step].to_i if params[:last_step].present?
      record.completed_at  = Time.current            if truthy?(params[:completed])
      record.dismissed_at  = Time.current            if truthy?(params[:dismissed])
      record.save!

      if truthy?(params[:completed]) && tour.first_login? && current_user.respond_to?(:onboarded_at=)
        current_user.update!(onboarded_at: Time.current) unless current_user.onboarded_at
      end

      render json: { ok: true, last_step: record.last_step, completed_at: record.completed_at }
    end

    private

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
