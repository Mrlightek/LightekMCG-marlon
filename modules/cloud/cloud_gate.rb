# marlon/modules/cloud/cloud_gate.rb
module Marlon
  module Modules
    module Cloud
      class CloudGate
        def self.call(payload)
          op = payload["op"]
          case op
          when "cloud.create_app"
            Reactions::CreateApp.perform(payload["params"])
          when "cloud.deploy"
            Reactions::DeployApp.perform(payload["params"])
          when "cloud.scale"
            Reactions::ScaleApp.perform(payload["params"])
          when "cloud.terminate"
            Reactions::TerminateApp.perform(payload["params"])
          else
            raise "Unknown cloud operation: #{op}"
          end
        end
      end
    end
  end
end
