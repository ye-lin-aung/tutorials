require "test_helper"
require "tutorials/path_matcher"

module Tutorials
  class PathMatcherTest < ActiveSupport::TestCase
    test "literal segments match exactly" do
      assert PathMatcher.match?("/dashboard", "/dashboard")
      assert PathMatcher.match?("/dashboard", "/dashboard/")
      refute PathMatcher.match?("/dashboard", "/dashboard/settings")
      refute PathMatcher.match?("/dashboard", "/other")
    end

    test "named parameters match a single segment" do
      assert PathMatcher.match?("/teacher/assignments/:id", "/teacher/assignments/42")
      assert PathMatcher.match?("/teacher/assignments/:id", "/teacher/assignments/uuid-abc-123")
      refute PathMatcher.match?("/teacher/assignments/:id", "/teacher/assignments")
      refute PathMatcher.match?("/teacher/assignments/:id", "/teacher/assignments/42/edit")
    end

    test "glob segments match remaining path" do
      assert PathMatcher.match?("/admin/*path", "/admin")
      assert PathMatcher.match?("/admin/*path", "/admin/users")
      assert PathMatcher.match?("/admin/*path", "/admin/users/42/edit")
      refute PathMatcher.match?("/admin/*path", "/other/users")
    end

    test "multiple parameters in one pattern" do
      assert PathMatcher.match?("/schools/:school_id/students/:id", "/schools/1/students/42")
      refute PathMatcher.match?("/schools/:school_id/students/:id", "/schools/1/students")
    end

    test "trailing slash is optional" do
      assert PathMatcher.match?("/courses", "/courses")
      assert PathMatcher.match?("/courses", "/courses/")
      assert PathMatcher.match?("/courses/:id", "/courses/7/")
    end

    test "root path" do
      assert PathMatcher.match?("/", "/")
      refute PathMatcher.match?("/", "/anything")
    end

    test "special regex characters in literals are escaped" do
      assert PathMatcher.match?("/foo.bar", "/foo.bar")
      refute PathMatcher.match?("/foo.bar", "/fooxbar")
    end

    test "mixed literal and param segment raises ArgumentError" do
      assert_raises(ArgumentError) { PathMatcher.match?("/users/:id.json", "/users/42.json") }
      assert_raises(ArgumentError) { PathMatcher.match?("/:id-foo", "/abc-foo") }
    end

    test "mixed literal and glob segment raises ArgumentError" do
      assert_raises(ArgumentError) { PathMatcher.match?("/prefix-*path", "/prefix-anything") }
    end

    test "error message mentions the bad segment" do
      err = assert_raises(ArgumentError) { PathMatcher.match?("/:id.json", "/42.json") }
      assert_match(/:id\.json/, err.message)
    end
  end
end
