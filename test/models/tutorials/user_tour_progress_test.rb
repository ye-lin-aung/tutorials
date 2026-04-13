require "test_helper"

module Tutorials
  class UserTourProgressTest < ActiveSupport::TestCase
    setup do
      @user = ::User.create!(email: "a@example.test")
    end

    test "belongs_to user" do
      record = UserTourProgress.new(user: @user, tour_id: "t1", started_at: Time.current)
      assert record.valid?
    end

    test "requires tour_id and started_at" do
      record = UserTourProgress.new(user: @user)
      refute record.valid?
      assert_includes record.errors[:tour_id], "can't be blank"
      assert_includes record.errors[:started_at], "can't be blank"
    end

    test "enforces uniqueness of (user_id, tour_id)" do
      UserTourProgress.create!(user: @user, tour_id: "t1", started_at: Time.current)
      dup = UserTourProgress.new(user: @user, tour_id: "t1", started_at: Time.current)
      refute dup.valid?
      assert_includes dup.errors[:tour_id], "has already been taken"
    end

    test "different tours for same user are allowed" do
      UserTourProgress.create!(user: @user, tour_id: "t1", started_at: Time.current)
      assert UserTourProgress.new(user: @user, tour_id: "t2", started_at: Time.current).valid?
    end

    test "#completed? reflects completed_at" do
      record = UserTourProgress.new(started_at: Time.current)
      refute record.completed?
      record.completed_at = Time.current
      assert record.completed?
    end

    test ".upsert_for finds or creates by (user, tour_id)" do
      record = UserTourProgress.upsert_for(user: @user, tour_id: "t1")
      assert record.persisted?
      assert record.started_at.present?

      again = UserTourProgress.upsert_for(user: @user, tour_id: "t1")
      assert_equal record.id, again.id
    end
  end
end
