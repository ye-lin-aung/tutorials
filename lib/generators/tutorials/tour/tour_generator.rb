require "rails/generators/named_base"

module Tutorials
  module Generators
    class TourGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, banner: "teacher/grade_assignment"
      class_option :route,       type: :string,  default: "/",   desc: "Route pattern the tour is bound to"
      class_option :first_login, type: :boolean, default: false, desc: "Flag as a first-login onboarding tour"
      class_option :steps,       type: :numeric, default: 3,     desc: "Number of starter step stubs"

      def create_tour_file
        @tour_id          = name.tr("/", ".")
        @tour_path        = name.gsub(".", "/")
        @route_pattern    = options[:route]
        @first_login      = options[:first_login]
        @step_count       = options[:steps].to_i.clamp(1, 20)
        @translation_root = "tours.#{@tour_id}"

        template "tour.yml.tt", "config/tours/#{@tour_path}.yml"
      end

      def show_locale_snippet
        say ""
        say "Add the following translation keys to config/locales/tutorials.en.yml:", :yellow
        say ""
        snippet  = File.read(File.expand_path("templates/locale_snippet.yml.tt", __dir__))
        rendered = ERB.new(snippet, trim_mode: "-").result(binding)
        say rendered
      end
    end
  end
end
