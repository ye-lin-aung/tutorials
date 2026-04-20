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

    # Load tour definitions from the host app's config/tours directory after
    # all host initializers have run. This ensures any Tutorials.configure
    # blocks in the host's config/initializers have already fired before we
    # register tours. YAML parse errors deliberately surface and halt boot.
    #
    # Registry, Tour, Step, and PathMatcher are eagerly required here because
    # this initializer runs before :setup_main_autoloader (Rails' Finisher
    # sets up Zeitwerk at the end of boot). Without the requires, referencing
    # Tutorials::Registry raises NameError since Zeitwerk's `setup` hasn't
    # been called yet at load_config_initializers time.
    initializer "tutorials.load_tours", after: :load_config_initializers do |app|
      require "tutorials/path_matcher"
      require "tutorials/step"
      require "tutorials/tour"
      require "tutorials/registry"
      require "tutorials/source_resolver"

      tours_path     = app.root.join("config/tours")
      workflows_path = app.root.join("config/workflows")

      hashes = Tutorials::SourceResolver.new.load_all(
        tours_dir:     (tours_path.directory?     ? tours_path.to_s     : nil),
        workflows_dir: (workflows_path.directory? ? workflows_path.to_s : nil)
      )
      hashes.each { |h| Tutorials::Registry.register(Tutorials::Tour.load_hash(h)) }
    end

    # Make the engine's launcher helper available to host views automatically.
    # Because the engine isolates its namespace, host controllers don't pick
    # up Tutorials::LauncherHelper through the normal `helper :all` path, so
    # `<%= render "tutorials/loader" %>` raises NameError on
    # `tutorials_available_ids`. Including it on action_controller load gives
    # every host view (including unauthenticated layouts) the helper methods.
    initializer "tutorials.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Tutorials::LauncherHelper
      end
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
