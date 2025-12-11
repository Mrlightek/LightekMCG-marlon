# marlon/modules/cloud/reactions/create_app.rb
module Marlon
  module Modules
    module Cloud
      module Reactions
        class CreateApp
          def self.perform(params)
            name = params["name"]
            plan = params["plan"] || "standard"

            node = CloudRegistry.assign_node
            volume = CloudRegistry.allocate_volume(plan)
            network = CloudRegistry.setup_network(node)
            CloudRegistry.register_app(name, node, volume, network)
            CloudScheduler.enqueue(:deploy_app, name: name, node: node, volume: volume)

            {status: "success", node: node, volume: volume, network: network}
          end
        end
      end
    end
  end
end

