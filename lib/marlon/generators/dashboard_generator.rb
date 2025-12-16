# lib/marlon/generators/dashboard_generator.rb
require 'erb'
require 'fileutils'
require 'webrick'
require 'json'

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
        start_server
        puts "🎨 Dashboard generated and running at http://localhost:4567"
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
              <tbody id="services-table">
              </tbody>
            </table>

            <script>
              async function fetchStatus() {
                const res = await fetch('/status');
                const data = await res.json();
                const tbody = document.getElementById('services-table');
                tbody.innerHTML = '';
                for (const [name, info] of Object.entries(data)) {
                  const row = document.createElement('tr');
                  row.className = info.status;
                  row.innerHTML = \`
                    <td>\${name}</td>
                    <td>\${info.status.charAt(0).toUpperCase() + info.status.slice(1)}</td>
                    <td>\${info.description}</td>
                    <td>
                      <button onclick="control('\${name}', 'start')">Start</button>
                      <button onclick="control('\${name}', 'stop')">Stop</button>
                      <button onclick="control('\${name}', 'restart')">Restart</button>
                    </td>
                  \`;
                  tbody.appendChild(row);
                }
              }

              async function control(service, action) {
                await fetch(\`/service/\${service}/\${action}\`, { method: 'POST' });
                fetchStatus();
              }

              fetchStatus();
              setInterval(fetchStatus, 5000);
            </script>
          </body>
          </html>
        HTML

        File.write(TEMPLATE_FILE, template)
      end

      def render_html
        # Initial render (can be overwritten by server)
        erb = ERB.new(File.read(TEMPLATE_FILE))
        html = erb.result(binding)
        File.write("#{DASHBOARD_DIR}/index.html", html)
      end

      # Start a simple HTTP server to serve the dashboard and handle actions
      def start_server
        server = WEBrick::HTTPServer.new(Port: 4567, DocumentRoot: DASHBOARD_DIR)

        # Serve the dashboard HTML
        server.mount_proc '/' do |req, res|
          res.body = File.read("#{DASHBOARD_DIR}/index.html")
          res['Content-Type'] = 'text/html'
        end

        # API to get current service statuses
        server.mount_proc '/status' do |req, res|
          statuses = @services_registry.transform_values do |info|
            { status: systemd_status(info[:unit]), description: info[:description] }
          end
          res.body = statuses.to_json
          res['Content-Type'] = 'application/json'
        end

        # API to control services
        server.mount_proc '/service' do |req, res|
          path_parts = req.path.split('/')
          service = path_parts[2]
          action = path_parts[3]
          if @services_registry.key?(service) && %w[start stop restart].include?(action)
            system("sudo systemctl #{action} #{@services_registry[service][:unit]}")
          end
          res.body = { ok: true }.to_json
          res['Content-Type'] = 'application/json'
        end

        trap 'INT' do
          server.shutdown
        end

        Thread.new { server.start }
      end

      def systemd_status(unit)
        return :unknown unless unit
        output = `systemctl is-active #{unit}`.strip
        output == 'active' ? :running : :stopped
      end
    end
  end
end

# Example usage:
# services = {
#   "web_server" => { unit: "nginx.service", description: "Handles HTTP requests" },
#   "db_service"  => { unit: "postgresql.service", description: "Database backend" }
# }
# Marlon::Generators::DashboardGenerator.new(services).generate
