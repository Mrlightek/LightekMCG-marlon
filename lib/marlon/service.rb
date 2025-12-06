module Marlon
  class Service
    def initialize; end

    def call(_payload)
      raise NotImplementedError
    end
  end
end
