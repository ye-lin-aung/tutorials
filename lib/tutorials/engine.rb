module Tutorials
  class Engine < ::Rails::Engine
    isolate_namespace Tutorials

    # Register lib/tutorials/ as a Zeitwerk autoload root under the Tutorials
    # namespace so that pure-Ruby classes living under lib/tutorials/*.rb
    # (PathMatcher, Step, Tour, Registry, Configuration, Availability, and
    # later helpers) are reloaded in development and eager-loaded in production
    # the same way Rails loads code under app/**.
    #
    # version.rb is ignored because it defines a VERSION constant inside the
    # Tutorials module rather than a Tutorials::Version constant, which would
    # confuse Zeitwerk's filename-to-constant convention. It's required
    # directly in lib/tutorials.rb so Zeitwerk never needs to resolve it.
    initializer "tutorials.zeitwerk_lib", before: :set_autoload_paths do
      loader = Rails.autoloaders.main
      lib_tutorials = root.join("lib/tutorials").to_s
      loader.push_dir(lib_tutorials, namespace: Tutorials)
      loader.ignore(root.join("lib/tutorials/version.rb").to_s)
    end
  end
end
