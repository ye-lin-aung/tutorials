require "test_helper"
require "tutorials/tour"

module Tutorials
  class TourTest < ActiveSupport::TestCase
    VALID_YAML = <<~YAML.freeze
      id: teacher.grade_assignment
      route: /teacher/assignments/:id
      title_key: tours.teacher.grade_assignment.title
      description_key: tours.teacher.grade_assignment.description
      first_login: false
      steps:
        - element: "[data-tour='grade-table']"
          title_key: tours.teacher.grade_assignment.steps.1.title
          body_key:  tours.teacher.grade_assignment.steps.1.body
        - element: "[data-tour='save-button']"
          title_key: tours.teacher.grade_assignment.steps.2.title
          body_key:  tours.teacher.grade_assignment.steps.2.body
    YAML

    test ".load parses a valid YAML document" do
      tour = Tour.load(VALID_YAML, source: "grade_assignment.yml")
      assert_equal "teacher.grade_assignment", tour.id
      assert_equal "/teacher/assignments/:id", tour.route
      assert_equal "tours.teacher.grade_assignment.title", tour.title_key
      assert_equal 2, tour.steps.size
      assert_kind_of Step, tour.steps.first
      assert_equal "[data-tour='grade-table']", tour.steps.first.element
      refute tour.first_login?
    end

    test "first_login defaults to false when omitted" do
      yaml = VALID_YAML.sub("first_login: false\n", "")
      refute Tour.load(yaml, source: "x.yml").first_login?
    end

    test "first_login: true is reflected" do
      yaml = VALID_YAML.sub("first_login: false", "first_login: true")
      assert Tour.load(yaml, source: "x.yml").first_login?
    end

    test ".load raises when required keys are missing" do
      %w[id route title_key steps].each do |missing|
        yaml = VALID_YAML.sub(/^#{missing}:.*\n/, "")
        err = assert_raises(Tour::InvalidTour) { Tour.load(yaml, source: "x.yml") }
        assert_match(/missing required key `#{missing}`/, err.message)
        assert_match(/x\.yml/, err.message)
      end
    end

    test ".load rejects unknown top-level keys" do
      yaml = VALID_YAML + "unknown_key: oops\n"
      err = assert_raises(Tour::InvalidTour) { Tour.load(yaml, source: "x.yml") }
      assert_match(/unknown top-level key `unknown_key`/, err.message)
    end

    test ".load rejects non-array steps" do
      yaml = VALID_YAML.sub(/steps:.*\z/m, "steps: not_an_array\n")
      err = assert_raises(Tour::InvalidTour) { Tour.load(yaml, source: "x.yml") }
      assert_match(/`steps` must be a list/, err.message)
    end

    test ".load rejects empty steps" do
      yaml = VALID_YAML.sub(/steps:.*\z/m, "steps: []\n")
      err = assert_raises(Tour::InvalidTour) { Tour.load(yaml, source: "x.yml") }
      assert_match(/must have at least one step/, err.message)
    end

    test "#matches_path? delegates to PathMatcher" do
      tour = Tour.load(VALID_YAML, source: "x.yml")
      assert tour.matches_path?("/teacher/assignments/7")
      refute tour.matches_path?("/teacher/assignments")
    end

    test "#render_for_locale returns a hash with translated strings and steps" do
      I18n.backend.store_translations(:en, tours: { teacher: { grade_assignment: {
        title: "Grade an assignment",
        description: "Walk through marking",
        steps: {
          "1" => { title: "Pick a submission", body: "Click any row" },
          "2" => { title: "Save",              body: "Hit save" }
        }
      } } })

      payload = Tour.load(VALID_YAML, source: "x.yml").render_for_locale(:en)

      assert_equal "teacher.grade_assignment", payload[:id]
      assert_equal "Grade an assignment",      payload[:title]
      assert_equal "Walk through marking",     payload[:description]
      assert_equal 2, payload[:steps].size
      assert_equal "Pick a submission", payload[:steps].first[:title]
      assert_equal "Save",              payload[:steps].last[:title]
    end
  end
end
