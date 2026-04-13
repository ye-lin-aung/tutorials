require "test_helper"

module Tutorials
  class ToursControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      Registry.reset!
      Configuration.instance.reset!
      @user = ::User.create!(email: "t@example.test")
      sign_in_as(@user)

      I18n.backend.store_translations(:en, t: {
        dash: { title: "Welcome", s1: { title: "Hi", body: "Click here" } },
        teach: { title: "Grade", s1: { title: "Step 1", body: "Do the thing" } }
      })

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

    test "GET show returns the tour payload with translated strings" do
      get tour_url("dash.welcome")
      assert_response :success
      body = JSON.parse(@response.body)

      assert_equal "dash.welcome", body["id"]
      assert_equal "Welcome", body["title"]
      assert_equal 1, body["steps"].size
      assert_equal "[data-tour='x']", body["steps"].first["element"]
      assert_equal "Hi", body["steps"].first["title"]
    end

    test "GET show returns 404 for unknown id" do
      get tour_url("does.not.exist")
      assert_response :not_found
    end

    test "GET show returns 401 when not signed in" do
      sign_in_as(nil)
      get tour_url("dash.welcome")
      assert_response :unauthorized
    end

    test "GET index returns tours available on the given path" do
      get tours_url, params: { path: "/dashboard" }
      assert_response :success
      body = JSON.parse(@response.body)

      ids = body.map { |t| t["id"] }
      assert_includes ids, "dash.welcome"
      refute_includes ids, "teach.grade"
    end

    test "GET index returns an empty list when no tours match" do
      get tours_url, params: { path: "/nowhere" }
      assert_response :success
      assert_equal [], JSON.parse(@response.body)
    end

    test "GET index marks completed tours when include_completed is requested" do
      UserTourProgress.create!(
        user:         @user,
        tour_id:      "dash.welcome",
        started_at:   Time.current,
        completed_at: Time.current
      )
      get tours_url, params: { path: "/dashboard", include_completed: "1" }
      body = JSON.parse(@response.body)
      entry = body.find { |t| t["id"] == "dash.welcome" }
      assert entry, "dash.welcome should be present in the response"
      assert entry["completed"], "dash.welcome should be marked completed"
    end

    test "GET gallery renders an HTML page listing every authorized tour" do
      get gallery_url
      assert_response :success
      assert_equal "text/html", @response.media_type
      assert_match "Tour Gallery", @response.body
      assert_match "Welcome",      @response.body
      assert_match "Grade",        @response.body
      assert_match "dash.welcome", @response.body
      assert_match "teach.grade",  @response.body
    end

    test "GET gallery hides tours the user is not authorized for" do
      Tutorials.configure { |c| c.authorize_with { |_user, tour| tour.id != "teach.grade" } }
      get gallery_url
      assert_response :success
      assert_match    "dash.welcome", @response.body
      refute_match    "teach.grade",  @response.body
    end

    test "GET gallery does not enforce auth at the engine layer (host responsibility)" do
      # The engine deliberately delegates HTML auth to the host app's normal
      # before_action chain, since hosts know how to redirect to their own
      # login page. Without a host auth check, the request goes through; the
      # gallery just renders an empty list when current_user is nil.
      sign_in_as(nil)
      get gallery_url
      assert_response :success
    end
  end
end
