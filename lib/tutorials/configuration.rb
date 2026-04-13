require "singleton"

module Tutorials
  # Host apps configure the engine via:
  #
  #   Tutorials.configure do |c|
  #     c.authorize_with { |user, tour| user.can_reach?(tour.route) }
  #   end
  #
  # Called from config/initializers/tutorials.rb in each host app.
  class Configuration
    include Singleton

    DEFAULT_AUTHORIZE = ->(_user, _tour) { true }

    def initialize
      reset!
    end

    def reset!
      @authorize_proc = DEFAULT_AUTHORIZE
    end

    def authorize_with(&block)
      @authorize_proc = block
    end

    def authorized?(user:, tour:)
      !!@authorize_proc.call(user, tour)
    end
  end
end
