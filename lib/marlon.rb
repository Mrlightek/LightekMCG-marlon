# lib/marlon.rb
# frozen_string_literal: true

require "zeitwerk"
require "fileutils"

require_relative "marlon/version"

module Marlon
  class << self
    def loader
      @loader ||= Zeitwerk::Loader.for_gem.tap do |l|
        l.inflector.inflect("mcg" => "MCG") if l.respond_to?(:inflector)
        l.setup
      end
    end

    def boot!
      loader
    end

    # route convenience
    def route(payload)
      Router.route(payload)
    end
  end
end

Marlon.boot!
