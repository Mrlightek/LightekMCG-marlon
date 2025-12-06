# lib/marlon/framework.rb
module Marlon
  class Framework
    def self.initialize!(opts = {})
      # global initialization (logging, instrumentation, config)
      @config = opts
    end

    def self.config
      @config ||= {}
    end
  end
end
