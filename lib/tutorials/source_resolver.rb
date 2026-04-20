require "yaml"

module Tutorials
  # Unifies tour loading across multiple sources. By default, reads legacy
  # `config/tours/*.yml` files. Other gems (like `workflows`) can register
  # a hook that produces tour hashes programmatically — merged on top of
  # legacy tours, wins on id collision.
  class SourceResolver
    @hooks = []

    class << self
      def register_hook(callable)
        @hooks << callable
      end

      def hooks
        @hooks
      end

      def reset!
        @hooks = []
      end
    end

    def load_all(tours_dir:, workflows_dir: nil)
      legacy  = load_legacy(tours_dir)
      derived = load_from_hooks(workflows_dir)
      merge_by_id(legacy, derived)
    end

    private

    def load_legacy(dir)
      return [] unless dir && File.directory?(dir)
      Dir.glob(File.join(dir, "**/*.yml")).sort.map do |f|
        hash = YAML.safe_load_file(f, permitted_classes: [Symbol], aliases: true)
        hash.transform_keys(&:to_sym)
      end
    end

    def load_from_hooks(workflows_dir)
      return [] if workflows_dir.nil?
      self.class.hooks.flat_map { |hook| hook.call(workflows_dir) }
    end

    # Derived hashes win: last-write-wins on id collision.
    def merge_by_id(legacy, derived)
      by_id = {}
      legacy.each  { |h| by_id[h[:id]] = h }
      derived.each { |h| by_id[h[:id]] = h }
      by_id.values
    end
  end
end
