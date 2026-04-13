require "test_helper"

class BootLoaderTest < ActiveSupport::TestCase
  setup do
    Tutorials::Registry.reset!
    tours_path = Rails.root.join("config/tours").to_s
    Tutorials::Registry.load_directory(tours_path) if File.directory?(tours_path)
  end

  test "engine initializer registers tours from the host config/tours directory" do
    # The dummy app has test/dummy/config/tours/example.yml. The initializer
    # fired when Rails booted for this test process.
    tour = Tutorials::Registry.find("dummy.example")
    assert_not_nil tour, "expected dummy.example to be registered at boot"
    assert_equal "/dashboard", tour.route
    assert tour.first_login?
  end
end
