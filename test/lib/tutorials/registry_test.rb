require "test_helper"

module Tutorials
  class RegistryTest < ActiveSupport::TestCase
    setup { Registry.reset! }
    teardown { Registry.reset! }

    FIXTURES = File.expand_path("../../fixtures/tours", __dir__)

    test ".load_directory registers every valid tour" do
      Registry.load_directory(FIXTURES, glob: "valid_tour.yml")
      assert_equal 1, Registry.all.size
      assert_equal "demo.first", Registry.all.first.id
      assert_equal "demo.first", Registry.find("demo.first").id
    end

    test ".find returns nil for unknown id" do
      assert_nil Registry.find("does.not.exist")
    end

    test ".load_directory raises with file path when YAML is invalid" do
      err = assert_raises(Tour::InvalidTour) do
        Registry.load_directory(FIXTURES, glob: "invalid_tour.yml")
      end
      assert_match(/invalid_tour\.yml/, err.message)
      assert_match(/missing required key `route`/, err.message)
    end

    test ".load_directory rejects duplicate ids across files" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "a.yml"), File.read(File.join(FIXTURES, "valid_tour.yml")))
        File.write(File.join(dir, "b.yml"), File.read(File.join(FIXTURES, "valid_tour.yml")))

        err = assert_raises(Registry::DuplicateId) do
          Registry.load_directory(dir)
        end
        assert_match(/duplicate tour id `demo\.first`/, err.message)
      end
    end

    test ".first_login_tour_for returns the first tour whose route matches and is flagged first_login" do
      Registry.load_directory(FIXTURES, glob: "valid_tour.yml")
      tour = Registry.first_login_tour_for("/dashboard")
      assert_equal "demo.first", tour.id
    end

    test ".first_login_tour_for returns nil when route does not match" do
      Registry.load_directory(FIXTURES, glob: "valid_tour.yml")
      assert_nil Registry.first_login_tour_for("/somewhere/else")
    end

    test ".unregister removes a single tour by id" do
      Registry.load_directory(FIXTURES, glob: "valid_tour.yml")
      assert_equal 1, Registry.all.size
      Registry.unregister("demo.first")
      assert_equal 0, Registry.all.size
      assert_nil Registry.find("demo.first")
    end
  end
end
