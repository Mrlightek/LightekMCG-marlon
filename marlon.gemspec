# marlon.gemspec

require_relative "lib/marlon/version"


Gem::Specification.new do |spec|
  spec.name          = "marlon"
  spec.version       = Marlon::VERSION
  spec.authors       = ["Marlon Henry"]
  spec.email         = ["mrlightek@gmail.com"]
  spec.summary       = "MARLON framework for LightekMCG"
  spec.description   = "Framework + CLI + generators for Lightek MARLON routing"
  spec.files         = Dir["lib/**/*", "exe/*", "marlon.gemspec", "Rakefile"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "zeitwerk"
  spec.add_dependency "activesupport"
  spec.add_dependency "active_model"

  spec.add_development_dependency "rake"
end

