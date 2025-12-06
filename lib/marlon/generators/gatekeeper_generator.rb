# lib/marlon/generators/gatekeeper_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class GatekeeperGenerator < BaseGenerator
      def generate
        content = render("gatekeeper_controller.rb.tt", {})
        path = "app/controllers/gatekeeper_controller.rb"
        write_file(path, content)

        # Add default route
        routes_path = "config/routes.rb"
        if File.exist?(routes_path)
          inject_route(routes_path)
        else
          puts "No routes.rb found at #{routes_path}. Please add:\n\n  post '/marlon/gatekeeper', to: 'gatekeeper#accept'\n\n"
        end
      end

      def inject_route(routes_path)
        route_line = "  post '/marlon/gatekeeper', to: 'gatekeeper#accept'"
        content = File.read(routes_path)
        unless content.include?(route_line)
          # Try to insert inside Rails.application.routes.draw do ... end
          updated = content.sub(/(Rails\.application\.routes\.draw do\s*\n)/, "\\1#{route_line}\n")
          if updated == content
            # fallback: append
            append_to_file(routes_path, "\n#{route_line}\n")
          else
            write_file(routes_path, updated)
            puts "Inserted gatekeeper route into #{routes_path}"
          end
        else
          puts "Gatekeeper route already present in #{routes_path}"
        end
      rescue => e
        puts "Failed to update routes: #{e.message}"
      end
    end
  end
end
