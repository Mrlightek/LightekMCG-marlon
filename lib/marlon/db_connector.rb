# lib/marlon/db_connector.rb
require_relative "db"
require "yaml"
require "erb"

module Marlon
  module DBConnector
    # Load a simple YAML config for dev/prod
    # Example config:
    # development:
    #   adapter: sqlite
    #   file: dev.db
    # production:
    #   adapter: postgres
    #   db: marlon
    #   host: localhost
    #   user: marlon
    #   password: secret
    def self.load_config(path = File.join(Dir.pwd, "config", "database.yml"))
      return {} unless File.exist?(path)
      YAML.load(ERB.new(File.read(path)).result)
    end

    # Establish connection for the current environment
    def self.connect(env = ENV["MARLON_ENV"] || "development")
      cfg = load_config
      if cfg[env]
        Marlon::DB.connect(:main, **cfg[env].transform_keys(&:to_sym))
        puts "[MARLON] Connected to DB (#{cfg[env][:adapter]}) for #{env} environment"
      else
        raise "[MARLON] No database config for environment #{env}"
      end
    end
  end
end
