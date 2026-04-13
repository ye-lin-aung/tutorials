require "test_helper"

# Verifies that the engine's LauncherHelper is included into the host's
# ActionController::Base so that host views (rendered outside engine
# controllers) can call `tutorials_available_ids` etc. without a NameError.
class HelperInclusionTest < ActionDispatch::IntegrationTest
  test "host ApplicationController inherits LauncherHelper methods" do
    helpers = ApplicationController.helpers
    assert helpers.respond_to?(:tutorials_available_ids),
      "Expected host helpers to respond to :tutorials_available_ids"
    assert helpers.respond_to?(:tutorials_auto_open_id),
      "Expected host helpers to respond to :tutorials_auto_open_id"
    assert helpers.respond_to?(:any_tutorials_available?),
      "Expected host helpers to respond to :any_tutorials_available?"
  end

  test "tutorials_available_ids returns [] when nothing is set on the controller" do
    helpers = ApplicationController.helpers
    assert_equal [], helpers.tutorials_available_ids
    assert_nil helpers.tutorials_auto_open_id
  end
end
