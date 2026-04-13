require "test_helper"
require "rails/generators"
require "generators/tutorials/tour/tour_generator"

module Tutorials
  module Generators
    class TourGeneratorTest < Rails::Generators::TestCase
      tests TourGenerator
      destination File.expand_path("../../../tmp/tour_gen", __dir__)
      setup :prepare_destination

      test "generates a tour YAML file at config/tours/<path>.yml" do
        run_generator ["teacher/grade_assignment", "--route=/teacher/assignments/:id", "--steps=2"]

        assert_file "config/tours/teacher/grade_assignment.yml" do |content|
          assert_match(/id: teacher\.grade_assignment/, content)
          assert_match(%r{route: /teacher/assignments/:id}, content)
          assert_match(/first_login: false/, content)
          assert_match(/title_key: tours\.teacher\.grade_assignment\.title/, content)
          assert_match(/data-tour='teacher-grade_assignment-step-1'/, content)
          assert_match(/data-tour='teacher-grade_assignment-step-2'/, content)
          refute_match(/step-3/, content)
        end
      end

      test "first_login flag is reflected" do
        run_generator ["student/welcome", "--route=/dashboard", "--first-login"]
        assert_file "config/tours/student/welcome.yml" do |content|
          assert_match(/first_login: true/, content)
        end
      end
    end
  end
end
