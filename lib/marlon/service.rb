# lib/marlon/service.rb
module Marlon
  class Service
    def initialize(context = {})
      @context = context
    end

    def call(_payload)
      raise NotImplementedError, "Service must implement #call"
    end
  end
end
