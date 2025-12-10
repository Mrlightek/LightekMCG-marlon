# lib/marlon/generators/gatekeeper_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class GatekeeperGenerator < BaseGenerator
      def generate
        content = render("gatekeeper.rb.tt", {})
        path = File.join(Dir.pwd, "app", "gatekeeper.rb")
        write_file(path, content)
        # ensure routes file exists
        routes_file = File.join(Dir.pwd, "config", "marlon_routes.rb")
        unless File.exist?(routes_file)
          write_file(routes_file, "# config/marlon_routes.rb\n")
        end
        puts "Gatekeeper app created and ready."
      end
    end
  end
end
