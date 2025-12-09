# marlon.gemspec
require_relative "lib/marlon/version"

Gem::Specification.new do |spec|
  spec.name          = "marlon"
  spec.version       = Marlon::VERSION
  spec.authors       = ["Marlon Henry"]
  spec.email         = ["mrlightek@gmail.com"]
  spec.summary       = "MARLON: Lightek hybrid framework (Falcon + Lightek Reactor)"
  spec.description   = "Standalone Ruby framework — HTTP/WS with Falcon, Async reactor, ActiveRecord support, systemd integration, UI Schema DSL."
  spec.files         = Dir["lib/**/*", "exe/*", "templates/**/*", "Rakefile", "install_marlon.sh", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  # runtime
  spec.add_dependency "thor"
  spec.add_dependency "zeitwerk"
  spec.add_dependency "activesupport"
  spec.add_dependency "async"
  spec.add_dependency "falcon", "~> 0.31"
  spec.add_dependency "async-http"
  spec.add_dependency "async-websocket"
  spec.add_dependency "rack"
  spec.add_dependency "puma" # optional
  spec.add_dependency "activerecord"
  # include a db adapter at host level as needed (pg/sqlite3/mysql2)

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
