require "tutorials/version"
require "tutorials/engine"

module Tutorials
  # Tutorials::Configuration, ::PathMatcher, ::Step, ::Tour, ::Registry, and
  # ::Availability are autoloaded by Zeitwerk from lib/tutorials/*.rb — see
  # the Zeitwerk configuration in lib/tutorials/engine.rb.

  def self.configure
    yield(Configuration.instance)
  end

  def self.config
    Configuration.instance
  end

  def self.parent_controller_class
    if Object.const_defined?(:ApplicationController)
      Object.const_get(:ApplicationController)
    else
      ActionController::Base
    end
  end
end
