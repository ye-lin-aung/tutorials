require "test_helper"

class Tutorials::SourceResolverTest < ActiveSupport::TestCase
  class FakeWorkflowsGem
    def self.load_tour_hashes(workflows_dir)
      [{ id: "from.workflows", route: "/x", title_key: "t", steps: [] }]
    end
  end

  test "resolves tours from tour YAML (legacy) when no workflows gem hook is registered" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "legacy.yml"), <<~YML)
        id: legacy.only
        route: /legacy
        title_key: legacy.title
        steps: []
      YML
      Tutorials::SourceResolver.reset!
      hashes = Tutorials::SourceResolver.new.load_all(tours_dir: dir, workflows_dir: nil)
      assert_equal ["legacy.only"], hashes.map { |h| h[:id] }
    end
  end

  test "merges workflow-derived tours with legacy tours" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "legacy.yml"), <<~YML)
        id: legacy.only
        route: /legacy
        title_key: legacy.title
        steps: []
      YML
      Tutorials::SourceResolver.reset!
      Tutorials::SourceResolver.register_hook(->(workflows_dir) { FakeWorkflowsGem.load_tour_hashes(workflows_dir) })

      hashes = Tutorials::SourceResolver.new.load_all(tours_dir: dir, workflows_dir: "/anywhere")
      ids = hashes.map { |h| h[:id] }.sort
      assert_equal %w[from.workflows legacy.only], ids
    end
  end

  test "workflow-derived tour wins over legacy tour of the same id" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "dup.yml"), <<~YML)
        id: from.workflows
        route: /legacy
        title_key: legacy.title
        steps: []
      YML
      Tutorials::SourceResolver.reset!
      Tutorials::SourceResolver.register_hook(->(_) { [{ id: "from.workflows", route: "/new", title_key: "x", steps: [] }] })
      hashes = Tutorials::SourceResolver.new.load_all(tours_dir: dir, workflows_dir: "/anywhere")
      new_one = hashes.find { |h| h[:id] == "from.workflows" }
      assert_equal "/new", new_one[:route]
    end
  end
end
