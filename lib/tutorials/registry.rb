module Tutorials
  # Singleton in-memory registry of all tours loaded at boot.
  #
  # The engine's initializer calls Registry.load_directory(Rails.root/config/tours)
  # once per boot. Tests call Registry.reset! between examples.
  module Registry
    class DuplicateId < StandardError; end

    @tours = {}

    class << self
      def reset!
        @tours = {}
      end

      def all
        @tours.values
      end

      def find(id)
        @tours[id.to_s]
      end

      def register(tour)
        if @tours.key?(tour.id)
          raise DuplicateId, "duplicate tour id `#{tour.id}` (already loaded from #{@tours[tour.id].source})"
        end
        @tours[tour.id] = tour
      end

      # Remove a single tour. Used by system tests that inject transient
      # fixtures and need to clean up without nuking the whole registry.
      def unregister(id)
        @tours.delete(id.to_s)
      end

      def load_directory(path, glob: "**/*.yml")
        return unless path && File.directory?(path)

        Dir.glob(File.join(path, glob)).sort.each do |file|
          register(Tour.load_file(file))
        end
      end

      def first_login_tour_for(request_path)
        all.find { |t| t.first_login? && t.matches_path?(request_path) }
      end
    end
  end
end
