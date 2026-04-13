module Tutorials
  class UserTourProgress < ApplicationRecord
    self.table_name = "tutorials_user_tour_progresses"

    belongs_to :user, class_name: "::User"

    validates :tour_id,    presence: true, uniqueness: { scope: :user_id }
    validates :started_at, presence: true
    validates :last_step,  numericality: { greater_than_or_equal_to: 0 }

    def completed?
      completed_at.present?
    end

    def self.upsert_for(user:, tour_id:)
      record = find_or_initialize_by(user: user, tour_id: tour_id)
      record.started_at ||= Time.current
      record.save!
      record
    end
  end
end
