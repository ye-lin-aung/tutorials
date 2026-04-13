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

    # Don't auto-append the engine's db/migrate to the host app's migration
    # paths. Hosts copy migrations into their own db/migrate/ via
    # `rake tutorials:install:migrations`. The dummy app keeps its own copy
    # in test/dummy/db/migrate/ so it can boot independently for tests
    # without colliding with the engine's own migration files.
    def append_migrations(app)
      # no-op: hosts opt in by copying migrations explicitly
    end
  end
end
