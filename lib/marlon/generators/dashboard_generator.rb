# lib/marlon/generators/dashboard_generator.rb
require 'erb'
require 'json'
require 'fileutils'

module Marlon
  module Generators
    class DashboardGenerator
      DASHBOARD_DIR = "/opt/marlon/dashboard"
      TEMPLATE_FILE = "#{DASHBOARD_DIR}/index.html.erb"

      def initialize(services_registry)
        # Expecting a hash: { service_name => { status: :running/:stopped, description: "..." } }
        @services_registry = services_registry
      end

      # Generate all files for the dashboard
      def generate
        prepare_directory
        write_template
        render_html
        puts "🎨 Dashboard generated at #{DASHBOARD_DIR}/index.html"
      end

      private

      def prepare_directory
        FileUtils.mkdir_p(DASHBOARD_DIR)
      end

      def write_template
        template = <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Marlon Service Dashboard</title>
            <style>
              body { font-family: sans-serif; background: #f4f4f4; padding: 20px; }
              h1 { text-align: center; }
              table { width: 100%; border-collapse: collapse; margin-top: 20px; }
              th, td { padding: 10px; border: 1px solid #ccc; text-align: left; }
              th { background: #333; color: white; }
              tr.running { background: #d4ffd4; }
              tr.stopped { background: #ffd4d4; }
              button { padding: 5px 10px; margin-right: 5px; }
            </style>
          </head>
          <body>
            <h1>Marlon Service Dashboard</h1>
            <table>
              <thead>
                <tr>
                  <th>Service</th>
                  <th>Status</th>
                  <th>Description</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <% @services_registry.each do |name, info| %>
                  <tr class="<%= info[:status] %>">
                    <td><%= name %></td>
                    <td><%= info[:status].to_s.capitalize %></td>
                    <td><%= info[:description] %></td>
                    <td>
                      <button onclick="fetch('/service/<%= name %>/start', { method: 'POST' })">Start</button>
                      <button onclick="fetch('/service/<%= name %>/stop', { method: 'POST' })">Stop</button>
                      <button onclick="fetch('/service/<%= name %>/restart', { method: 'POST' })">Restart</button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <script>
              // Optional: auto-refresh every 5 seconds
              setInterval(() => { location.reload(); }, 5000);
            </script>
          </body>
          </html>
        HTML

        File.write(TEMPLATE_FILE, template)
      end

      def render_html
        erb = ERB.new(File.read(TEMPLATE_FILE))
        html = erb.result(binding)
        File.write("#{DASHBOARD_DIR}/index.html", html)
      end
    end
  end
end

# Example usage:
# services = {
#   "web_server" => { status: :running, description: "Handles HTTP requests" },
#   "db_service" => { status: :stopped, description: "Database backend" }
# }
# Marlon::Generators::DashboardGenerator.new(services).generate
