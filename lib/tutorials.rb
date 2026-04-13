require "tutorials/version"
require "tutorials/engine"

module Tutorials
  # Eager-loaded classes are autoloaded via the engine once the host app boots.
  # Bare-gem consumers can require individual files by path.
  autoload :Configuration, "tutorials/configuration"
  autoload :PathMatcher,   "tutorials/path_matcher"
  autoload :Step,          "tutorials/step"
  autoload :Tour,          "tutorials/tour"
  autoload :Registry,      "tutorials/registry"
  autoload :Availability,  "tutorials/availability"

  def self.configure
    yield(Configuration.instance)
  end

  def self.config
    Configuration.instance
  end
end
