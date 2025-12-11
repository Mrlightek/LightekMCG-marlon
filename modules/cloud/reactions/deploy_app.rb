# marlon/modules/cloud/reactions/deploy_app.rb
module Marlon
  module Modules
    module Cloud
      module Reactions
        class DeployApp
          def self.perform(params)
            name = params[:name] || params["name"]
            app = CloudRegistry.status(name)
            return {error: "App not found"} unless app

            # Simulate deployment
            app[:status] = "deployed"
            {status: "deployed", app: name, node: app[:node]}
          end
        end
      end
    end
  end
end
