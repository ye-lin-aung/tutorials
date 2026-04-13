module Tutorials
  # Immutable value object representing a single step in a tour.
  #
  # Stored form (from YAML):
  #   element:   CSS selector, usually "[data-tour='...']"
  #   title_key: I18n translation key for the tooltip title
  #   body_key:  I18n translation key for the tooltip body
  class Step
    attr_reader :element, :title_key, :body_key

    def initialize(element:, title_key:, body_key:)
      raise ArgumentError, "Step#element is required"   if element.nil?   || element.to_s.empty?
      raise ArgumentError, "Step#title_key is required" if title_key.nil? || title_key.to_s.empty?
      raise ArgumentError, "Step#body_key is required"  if body_key.nil?  || body_key.to_s.empty?

      @element   = element.to_s.freeze
      @title_key = title_key.to_s.freeze
      @body_key  = body_key.to_s.freeze
      freeze
    end

    def to_h
      { element: element, title_key: title_key, body_key: body_key }.freeze
    end

    # Returns a hash ready to hand to the Stimulus controller / driver.js.
    # Translation missing -> Rails default (returns the key string) which QA will catch.
    def render_for_locale(locale)
      {
        element: element,
        title:   I18n.t(title_key, locale: locale),
        body:    I18n.t(body_key,  locale: locale)
      }
    end
  end
end
