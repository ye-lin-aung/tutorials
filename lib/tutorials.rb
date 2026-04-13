require "tutorials/version"
require "tutorials/engine"
require "tutorials/configuration"

module Tutorials
  # Tutorials::PathMatcher, ::Step, ::Tour, ::Registry, and ::Availability are
  # autoloaded by Zeitwerk from lib/tutorials/*.rb — see the Zeitwerk
  # configuration in lib/tutorials/engine.rb.
  #
  # Tutorials::Configuration is required eagerly above because hosts call
  # Tutorials.configure { ... } from config/initializers/tutorials.rb, which
  # runs at :load_config_initializers — BEFORE :setup_main_autoloader. Zeitwerk
  # cannot resolve the constant at that point, so we require it directly.

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
