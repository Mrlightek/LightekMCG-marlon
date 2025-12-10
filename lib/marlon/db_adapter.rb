# lib/marlon/db_adapter.rb
require "yaml"
require "erb"
require_relative "db"

module Marlon
  module DBAdapter
    CONFIG_PATH = File.join(Dir.pwd, "config", "database.yml")

    def self.load_config
      return {} unless File.exist?(CONFIG_PATH)
      YAML.load(ERB.new(File.read(CONFIG_PATH)).result) || {}
    end

    def self.establish_connection(env = ENV["MARLON_ENV"] || "development")
      cfg = load_config[env.to_s]
      raise "[MARLON] No DB config for env '#{env}'" unless cfg
      cfg_sym = cfg.transform_keys(&:to_sym)
      adapter = (cfg_sym[:adapter] || :sqlite).to_sym
      Marlon::DB.connect(:main, adapter: adapter, **cfg_sym)
      puts "[MARLON] DB connected (#{env}) adapter=#{adapter}"
    end
  end
end
