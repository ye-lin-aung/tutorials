require "test_helper"
require "tutorials/step"

module Tutorials
  class StepTest < ActiveSupport::TestCase
    test "valid step with all keys" do
      step = Step.new(
        element:    "[data-tour='foo']",
        title_key:  "tours.demo.steps.1.title",
        body_key:   "tours.demo.steps.1.body"
      )
      assert_equal "[data-tour='foo']", step.element
      assert_equal "tours.demo.steps.1.title", step.title_key
      assert_equal "tours.demo.steps.1.body",  step.body_key
    end

    test "requires element, title_key, and body_key" do
      assert_raises(ArgumentError) { Step.new(element: nil, title_key: "t", body_key: "b") }
      assert_raises(ArgumentError) { Step.new(element: "x", title_key: nil, body_key: "b") }
      assert_raises(ArgumentError) { Step.new(element: "x", title_key: "t", body_key: nil) }
    end

    test "#to_h returns a serialisable representation keyed by symbols" do
      step = Step.new(element: "x", title_key: "t", body_key: "b")
      assert_equal({ element: "x", title_key: "t", body_key: "b" }, step.to_h)
    end

    test "#render_for_locale translates with I18n and returns client-ready payload" do
      I18n.backend.store_translations(:en, tours: { demo: { steps: { "1" => { title: "Hi", body: "Body" } } } })

      step = Step.new(
        element:   "[data-tour='foo']",
        title_key: "tours.demo.steps.1.title",
        body_key:  "tours.demo.steps.1.body"
      )

      assert_equal(
        { element: "[data-tour='foo']", title: "Hi", body: "Body" },
        step.render_for_locale(:en)
      )
    end
  end
end
