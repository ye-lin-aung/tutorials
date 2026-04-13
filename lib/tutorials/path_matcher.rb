module Tutorials
  # Compiles a Rails-style route pattern ("/teacher/assignments/:id")
  # into a regex and matches it against a concrete request path.
  #
  # Supported pattern syntax:
  #   /literal          - exact segment match
  #   /:name            - single-segment capture (matches [^/]+)
  #   /*name            - glob capture (matches the remaining path, including empty)
  #
  # Trailing slashes on the path are optional.
  module PathMatcher
    module_function

    def match?(pattern, path)
      compile(pattern).match?(normalize(path))
    end

    def normalize(path)
      p = path.to_s
      p = "/" + p unless p.start_with?("/")
      p.chomp("/").then { |s| s.empty? ? "/" : s }
    end

    def compile(pattern)
      segments = pattern.to_s.split("/", -1).reject(&:empty?)
      regex_body =
        if segments.empty?
          "/"
        else
          segments.map { |seg| compile_segment(seg) }.join
        end
      Regexp.new("\\A#{regex_body}\\z")
    end

    def compile_segment(segment)
      case segment
      when /\A:(\w+)\z/   then "/[^/]+"
      when /\A\*(\w+)\z/  then "(?:/.*)?"
      else "/#{Regexp.escape(segment)}"
      end
    end
  end
end
