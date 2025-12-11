# marlon/modules/cloud/cloud_registry.rb
module Marlon
  module Modules
    module Cloud
      class CloudRegistry
        @nodes = []
        @apps = {}

        class << self
          def assign_node
            node = @nodes.sample || "node_#{rand(1000)}"
            @nodes << node unless @nodes.include?(node)
            node
          end

          def allocate_volume(plan = "standard")
            "vol_#{rand(10000)}_#{plan}"
          end

          def setup_network(node)
            "net_#{node}_#{rand(1000)}"
          end

          def register_app(name, node, volume, network)
            @apps[name] = { node: node, volume: volume, network: network, status: "pending" }
          end

          def status(name)
            @apps[name] || {}
          end
        end
      end
    end
  end
end
