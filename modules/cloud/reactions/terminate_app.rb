# marlon/modules/cloud/reactions/terminate_app.rb
module Marlon
  module Modules
    module Cloud
      module Reactions
        class TerminateApp
          def self.perform(params)
            name = params[:name]
            app = CloudRegistry.status(name)
            return {error: "App not found"} unless app

            # Remove from registry
            CloudRegistry.status(name).clear
            {status: "terminated", app: name}
          end
        end
      end
    end
  end
end
