# lib/marlon.rb
# frozen_string_literal: true

require "zeitwerk"

module Marlon
  class << self
    # Main loader
    def loader
      @loader ||= Zeitwerk::Loader.for_gem.tap do |loader|
        loader.inflector.inflect(
          "mcg" => "MCG"
        )
        loader.setup
      end
    end

    def boot!
      loader
    end

    # Entry point for the payload router
    def route(payload)
      Router.route(payload)
    end
  end
end

Marlon.boot!
