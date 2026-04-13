require_relative "lib/tutorials/version"

Gem::Specification.new do |spec|
  spec.name        = "tutorials"
  spec.version     = Tutorials::VERSION
  spec.authors     = ["Ye Lin Aung"]
  spec.email       = ["noreply@example.com"]
  spec.homepage    = "https://github.com/yelinaung/tutorials"
  spec.summary     = "In-app guided tour engine for LMS and school-os."
  spec.description = "Ships YAML-authored driver.js tours, DB-tracked progress, route-based availability, and a selector-audit CI task. Shared between LMS and school-os."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["allowed_push_host"] = "none"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.0"
end
