# lib/marlon/modules/cloud/ovh_provider.rb
require "securerandom"

module Marlon
  module Modules
    module Cloud
      class OVHProvider
        def initialize(config = {})
          @ak = config[:ak]
          @sk = config[:sk]
          @endpoint = config[:endpoint] || "https://eu.api.ovh.com/1.0"
        end

        # Return simulated structure { id: "...", ip: "x.x.x.x" }
        
        def create_instance(name:, image:, flavor:, ssh_keys: [])
  # Call OVH API using Net::HTTP or HTTParty (your choice)
  # For now, return a structured stub that looks real:
  {
    id: "stub-#{SecureRandom.hex(6)}",
    ip: "0.0.0.0" # temporary until OVH returns the real one
  }
end

def delete_instance(id:)
  # Call OVH API here
  true
end


        def reboot_instance(id:)
          true
        end
      end
    end
  end
end
