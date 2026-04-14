require "yaml"

module Tutorials
  # Represents one tour parsed from a YAML file.
  #
  # Required keys:     id, route, title_key, steps
  # Optional keys:     description_key, first_login (default false)
  # Unknown keys:      rejected with InvalidTour
  #
  # Required keys on each step: element, title_key, body_key
  class Tour
    class InvalidTour < StandardError; end

    REQUIRED_KEYS = %w[id route title_key steps].freeze
    OPTIONAL_KEYS = %w[description_key first_login preview_path].freeze
    ALLOWED_KEYS  = (REQUIRED_KEYS + OPTIONAL_KEYS).freeze

    REQUIRED_STEP_KEYS = %w[element title_key body_key].freeze

    attr_reader :id, :route, :title_key, :description_key, :steps, :source, :preview_path

    def self.load(yaml_source, source:)
      # Pre-scan for required top-level keys so that a YAML document with a
      # missing key (which may otherwise become structurally invalid, e.g.
      # removing `steps:` leaves its list items orphaned) still produces a
      # meaningful "missing required key" error rather than a parser crash.
      REQUIRED_KEYS.each do |key|
        unless yaml_source =~ /^#{Regexp.escape(key)}:/
          raise InvalidTour, "#{source}: missing required key `#{key}`"
        end
      end

      raw =
        begin
          YAML.safe_load(yaml_source, permitted_classes: [], aliases: false) || {}
        rescue Psych::SyntaxError => e
          raise InvalidTour, "#{source}: invalid YAML (#{e.message})"
        end

      unless raw.is_a?(Hash)
        raise InvalidTour, "#{source}: top level must be a mapping"
      end
      new(raw, source: source)
    end

    def self.load_file(path)
      load(File.read(path), source: path)
    end

    def initialize(raw, source:)
      @source = source.to_s
      validate_top_level!(raw)

      @id              = raw.fetch("id").to_s
      @route           = raw.fetch("route").to_s
      @title_key       = raw.fetch("title_key").to_s
      @description_key = raw["description_key"]&.to_s
      @first_login     = raw.fetch("first_login", false) ? true : false
      @preview_path    = raw["preview_path"]&.to_s
      @steps           = build_steps(raw.fetch("steps")).freeze

      # Cache the compiled path matcher regex so repeated matches_path? calls
      # from Availability don't recompile on every request.
      @compiled_route = PathMatcher.compile(@route)
    end

    def first_login?
      @first_login
    end

    def matches_path?(request_path)
      @compiled_route.match?(PathMatcher.normalize(request_path))
    end

    def render_for_locale(locale)
      {
        id:          id,
        title:       I18n.t(title_key, locale: locale),
        description: description_key ? I18n.t(description_key, locale: locale) : nil,
        first_login: first_login?,
        steps:       steps.map { |s| s.render_for_locale(locale) }
      }
    end

    private

    def validate_top_level!(raw)
      missing = REQUIRED_KEYS - raw.keys
      if missing.any?
        raise InvalidTour, "#{source}: missing required key `#{missing.first}`"
      end

      unknown = raw.keys - ALLOWED_KEYS
      if unknown.any?
        raise InvalidTour, "#{source}: unknown top-level key `#{unknown.first}`"
      end

      unless raw["steps"].is_a?(Array)
        raise InvalidTour, "#{source}: `steps` must be a list"
      end

      if raw["steps"].empty?
        raise InvalidTour, "#{source}: must have at least one step"
      end
    end

    def build_steps(raw_steps)
      raw_steps.each_with_index.map do |raw, idx|
        unless raw.is_a?(Hash)
          raise InvalidTour, "#{source}: step #{idx} must be a mapping"
        end
        missing = REQUIRED_STEP_KEYS - raw.keys
        if missing.any?
          raise InvalidTour, "#{source}: step #{idx} missing `#{missing.first}`"
        end
        Step.new(
          element:   raw["element"],
          title_key: raw["title_key"],
          body_key:  raw["body_key"]
        )
      end
    end
  end
end
