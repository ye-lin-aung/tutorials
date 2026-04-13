require "test_helper"

module Tutorials
  class AvailabilityTest < ActiveSupport::TestCase
    setup do
      Registry.reset!
      Configuration.instance.reset!
      @user = ::User.create!(email: "a@example.test")

      Registry.register(Tour.load(<<~YAML, source: "dash.yml"))
        id: dash.welcome
        route: /dashboard
        title_key: t.dash.title
        first_login: true
        steps:
          - element: "[data-tour='x']"
            title_key: t.dash.s1.title
            body_key:  t.dash.s1.body
      YAML

      Registry.register(Tour.load(<<~YAML, source: "teach.yml"))
        id: teach.grade
        route: /teacher/assignments/:id
        title_key: t.teach.title
        first_login: false
        steps:
          - element: "[data-tour='y']"
            title_key: t.teach.s1.title
            body_key:  t.teach.s1.body
      YAML
    end

    teardown do
      Registry.reset!
      Configuration.instance.reset!
    end

    test ".for returns tours whose route matches the request path" do
      result = Availability.for(user: @user, path: "/dashboard")
      assert_equal ["dash.welcome"], result.map(&:id)
    end

    test ".for matches parameterised routes" do
      result = Availability.for(user: @user, path: "/teacher/assignments/42")
      assert_equal ["teach.grade"], result.map(&:id)
    end

    test ".for excludes tours the authorize_with proc denies" do
      Tutorials.configure do |c|
        c.authorize_with { |_user, tour| tour.id != "dash.welcome" }
      end
      result = Availability.for(user: @user, path: "/dashboard")
      assert_empty result
    end

    test ".for excludes tours the user has already completed" do
      UserTourProgress.create!(
        user:         @user,
        tour_id:      "dash.welcome",
        started_at:   Time.current,
        completed_at: Time.current
      )
      result = Availability.for(user: @user, path: "/dashboard")
      assert_empty result
    end

    test ".for includes tours the user dismissed but did not complete" do
      UserTourProgress.create!(
        user:         @user,
        tour_id:      "dash.welcome",
        started_at:   Time.current,
        dismissed_at: Time.current
      )
      result = Availability.for(user: @user, path: "/dashboard")
      assert_equal ["dash.welcome"], result.map(&:id)
    end

    test ".auto_open_tour returns a first_login tour only if user is not onboarded" do
      assert_equal "dash.welcome", Availability.auto_open_tour(user: @user, path: "/dashboard")&.id

      @user.update!(onboarded_at: Time.current)
      assert_nil Availability.auto_open_tour(user: @user, path: "/dashboard")
    end

    test ".auto_open_tour skips completed tours" do
      UserTourProgress.create!(
        user:         @user,
        tour_id:      "dash.welcome",
        started_at:   Time.current,
        completed_at: Time.current
      )
      assert_nil Availability.auto_open_tour(user: @user, path: "/dashboard")
    end

    test ".for returns [] when DB is unreachable" do
      UserTourProgress.singleton_class.alias_method :__orig_completed_tour_ids_for, :completed_tour_ids_for
      UserTourProgress.define_singleton_method(:completed_tour_ids_for) do |**_kwargs|
        raise ActiveRecord::ConnectionNotEstablished
      end
      begin
        assert_empty Availability.for(user: @user, path: "/dashboard")
      ensure
        UserTourProgress.singleton_class.alias_method :completed_tour_ids_for, :__orig_completed_tour_ids_for
        UserTourProgress.singleton_class.remove_method :__orig_completed_tour_ids_for
      end
    end
  end
end
