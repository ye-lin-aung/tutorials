require "test_helper"

module Tutorials
  class ProgressControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      Registry.reset!
      @user = ::User.create!(email: "p@example.test")
      sign_in_as(@user)

      Registry.register(Tour.load(<<~YAML, source: "onboard.yml"))
        id: onboard.welcome
        route: /dashboard
        title_key: t.on.title
        first_login: true
        steps:
          - element: "[data-tour='x']"
            title_key: t.on.s1.title
            body_key:  t.on.s1.body
      YAML

      Registry.register(Tour.load(<<~YAML, source: "help.yml"))
        id: help.guide
        route: /help
        title_key: t.help.title
        first_login: false
        steps:
          - element: "[data-tour='y']"
            title_key: t.help.s1.title
            body_key:  t.help.s1.body
      YAML
    end

    teardown { Registry.reset! }

    test "PATCH creates a new progress row on first call" do
      patch progress_url, params: { tour_id: "help.guide", last_step: 0 }
      assert_response :success

      record = UserTourProgress.find_by!(user: @user, tour_id: "help.guide")
      assert_equal 0, record.last_step
      assert record.started_at.present?
      assert_nil record.completed_at
    end

    test "PATCH updates last_step on subsequent calls" do
      UserTourProgress.create!(user: @user, tour_id: "help.guide", started_at: 10.minutes.ago, last_step: 0)
      patch progress_url, params: { tour_id: "help.guide", last_step: 2 }
      assert_response :success
      assert_equal 2, UserTourProgress.find_by(user: @user, tour_id: "help.guide").last_step
    end

    test "PATCH with completed:true marks tour complete and sets onboarded_at for first_login tours" do
      patch progress_url, params: { tour_id: "onboard.welcome", completed: "true", last_step: 2 }
      assert_response :success

      record = UserTourProgress.find_by!(user: @user, tour_id: "onboard.welcome")
      assert record.completed_at.present?

      @user.reload
      assert @user.onboarded_at.present?, "onboarded_at should be set for first_login tours"
    end

    test "PATCH with completed:true does NOT set onboarded_at for non-first_login tours" do
      patch progress_url, params: { tour_id: "help.guide", completed: "true", last_step: 2 }
      @user.reload
      assert_nil @user.onboarded_at
    end

    test "PATCH with dismissed:true records dismissal but not completion" do
      patch progress_url, params: { tour_id: "onboard.welcome", dismissed: "true", last_step: 1 }
      record = UserTourProgress.find_by!(user: @user, tour_id: "onboard.welcome")
      assert record.dismissed_at.present?
      assert_nil record.completed_at

      @user.reload
      assert_nil @user.onboarded_at, "dismiss does not count as onboarding"
    end

    test "PATCH returns 404 for unknown tour" do
      patch progress_url, params: { tour_id: "nope" }
      assert_response :not_found
    end

    test "PATCH returns 401 when not signed in" do
      sign_in_as(nil)
      patch progress_url, params: { tour_id: "help.guide" }
      assert_response :unauthorized
    end
  end
end
