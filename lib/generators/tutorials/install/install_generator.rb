require "rails/generators/base"
require "rails/generators/active_record/migration/migration_generator"

module Tutorials
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def copy_initializer
        template "initializer.rb", "config/initializers/tutorials.rb"
      end

      def create_tours_directory
        create_file "config/tours/.keep", ""
      end

      def copy_locale
        template "tutorials.en.yml", "config/locales/tutorials.en.yml"
      end

      def copy_stimulus_controller
        controller_src = Tutorials::Engine.root.join("app/javascript/controllers/tutorials_controller.js")
        copy_file controller_src.to_s, "app/javascript/controllers/tutorials_controller.js"
      end

      def add_onboarded_at_migration
        migration_template(
          "add_onboarded_at_to_users.rb.tt",
          "db/migrate/add_onboarded_at_to_users.rb"
        )
      end

      def install_engine_migrations
        rake "tutorials:install:migrations"
      end

      def show_readme
        say ""
        say "tutorials engine installed.", :green
        say ""
        say "Next steps:"
        say "  1. Run migrations:"
        say "       bin/rails db:migrate"
        say "  2. Edit config/initializers/tutorials.rb to wire your authorization logic."
        say "  3. Register the Stimulus controller in app/javascript/controllers/application.js:"
        say '       import TutorialsController from "controllers/tutorials_controller"'
        say '       application.register("tutorials", TutorialsController)'
        say "  4. Pin driver.js in config/importmap.rb (if not already):"
        say '       pin "driver.js", to: "https://ga.jspm.io/npm:driver.js@1.4.0/dist/driver.js.iife.js"'
        say "  5. Add `<%= render \"tutorials/loader\" %>` and `<%= render \"tutorials/launcher\" %>` to your layouts."
        say "  6. Add `before_action :set_available_tours` to ApplicationController (see initializer comments)."
        say ""
      end
    end
  end
end
