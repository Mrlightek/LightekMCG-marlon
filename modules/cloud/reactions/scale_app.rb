# marlon/modules/cloud/reactions/scale_app.rb
module Marlon
  module Modules
    module Cloud
      module Reactions
        class ScaleApp
          def self.perform(params)
            name = params[:name]
            count = params[:count].to_i
            app = CloudRegistry.status(name)
            return {error: "App not found"} unless app

            # Simulate scaling nodes
            app[:nodes_scaled] = count
            {status: "scaled", app: name, nodes: count}
          end
        end
      end
    end
  end
end
