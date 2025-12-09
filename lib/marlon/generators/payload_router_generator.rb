# lib/marlon/generators/payload_router_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class PayloadRouterGenerator < BaseGenerator
      def initialize(name)
        raise "Name required" unless name
        @name = name
        @class_name = name.split(/_|-/).map(&:capitalize).join
      end

      def generate
        path = File.join(Dir.pwd, "app", "marlon", "routers", "#{underscore(@name)}_router.rb")
        content = <<~RUBY
          module Marlon
            module Routers
              class #{@class_name}Router
                def self.register
                  # Example:
                  # Marlon::Router.map("invoice.create", Marlon::Services::InvoiceCreateService)
                end
              end
            end
          end
        RUBY
        write_file(path, content)
      end

      private

      def underscore(name)
        name.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
      end
    end
  end
end
