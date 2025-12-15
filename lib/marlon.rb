# lib/marlon.rb
# frozen_string_literal: true

require "zeitwerk"
require "yaml"
require "fileutils"
require_relative "marlon/version"

module Marlon
  class << self
    def loader
      return @loader if @loader
      @loader = Zeitwerk::Loader.new
      @loader.push_dir(File.expand_path("..", __dir__)) # lib/
      @loader.setup
      @loader
    end

    def boot!
      loader
    end

    def root
      File.expand_path("..", __dir__)
    end

    def config
      @config ||= load_config
    end

    def load_config
      path = File.join(Dir.pwd, "config", "marlon.yml")
      if File.exist?(path)
        YAML.load_file(path).with_indifferent_access
      else
        {}.with_indifferent_access
      end
    rescue => e
      warn "[MARLON] failed to load config: #{e}"
      {}.with_indifferent_access
    end

    def reload_config!
      @config = load_config
    end

    def route(payload)
      Router.route(payload)
    end
  end
end

Marlon.boot!
