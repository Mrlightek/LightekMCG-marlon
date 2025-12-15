# lib/marlon/modules/cloud/module.rb
module Marlon
  module Modules
    module Cloud
      MODULE_NAME = "Cloud"
      def self.root
        File.expand_path(__dir__)
      end
    end
  end
end
