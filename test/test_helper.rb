# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  # Note: we intentionally do NOT call `fixtures :all` here. The engine ships
  # non-ActiveRecord YAML fixtures (e.g. test/fixtures/tours/*.yml consumed by
  # Tutorials::Registry tests) that would otherwise be misinterpreted as AR
  # fixtures and crash the suite. Add `fixtures :foo` per-test if/when an
  # ActiveRecord fixture is actually needed.
end

module TutorialsTestAuth
  def sign_in_as(user)
    Thread.current[:tutorials_test_user] = user
  end

  def teardown
    Thread.current[:tutorials_test_user] = nil
    super
  end
end

ActiveSupport::TestCase.include TutorialsTestAuth
ActionDispatch::IntegrationTest.include TutorialsTestAuth
