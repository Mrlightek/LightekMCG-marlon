# lib/marlon/service.rb
module Marlon
  class Service
    # services can be started inside reactor or run as a systemd unit
    def initialize(context = {})
      @context = context
    end

    def call(payload)
      raise NotImplementedError, "Implement #call(payload) in #{self.class}"
    end
  end
end

