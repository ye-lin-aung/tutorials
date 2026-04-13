require "test_helper"

module Tutorials
  class ConfigurationTest < ActiveSupport::TestCase
    setup { Configuration.instance.reset! }
    teardown { Configuration.instance.reset! }

    test "default authorize_with permits every user/tour combination" do
      assert Configuration.instance.authorized?(user: Object.new, tour: Object.new)
    end

    test "configurable authorize_with is invoked with user and tour" do
      seen = []
      Tutorials.configure do |c|
        c.authorize_with { |user, tour| seen << [user, tour]; false }
      end

      user = Object.new
      tour = Object.new
      refute Configuration.instance.authorized?(user: user, tour: tour)
      assert_equal [[user, tour]], seen
    end

    test "reset! restores default" do
      Tutorials.configure { |c| c.authorize_with { |_u, _t| false } }
      refute Configuration.instance.authorized?(user: nil, tour: nil)

      Configuration.instance.reset!
      assert Configuration.instance.authorized?(user: nil, tour: nil)
    end
  end
end
