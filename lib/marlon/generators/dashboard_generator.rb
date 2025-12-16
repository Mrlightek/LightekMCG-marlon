# lib/marlon/generators/dashboard_generator.rb
require "fileutils"
require "falcon"
require "json"
require "marlon/gatekeeper"

module Marlon
  module Generators
    class DashboardGenerator
      DASHBOARD_DIR = File.expand_path("../../../dashboard", __dir__)

      attr_reader :services

      def initialize(services = [])
        @services = services
      end

      # Generate dashboard files (HTML/CSS/JS)
      def generate_dashboard_files
        FileUtils.mkdir_p(DASHBOARD_DIR)

        # Basic HTML dashboard
        File.write("#{DASHBOARD_DIR}/index.html", <<~HTML)
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <title>Marlon Dashboard</title>
            <style>
              body { font-family: sans-serif; background: #111; color: #eee; }
              h1 { text-align: center; }
              .service { padding: 10px; margin: 5px; border: 1px solid #444; border-radius: 5px; }
              .running { color: #0f0; }
              .stopped { color: #f00; }
              button { margin-left: 10px; }
            </style>
          </head>
          <body>
            <h1>Marlon Dashboard</h1>
            <div id="services"></div>
            <script>
              async function fetchStatus() {
                const token = prompt("Enter Marlon token:");
                const resp = await fetch("/", {
                  method: "POST",
                  headers: { "Content-Type": "application/json", "X-Marlon-Token": token },
                  body: JSON.stringify({ object: "dashboard_status" })
                });
                const data = await resp.json();
                const container = document.getElementById("services");
                container.innerHTML = "";
                for (const svc of data.services) {
                  const div = document.createElement("div");
                  div.className = "service";
                  div.innerHTML = \`
                    <strong>\${svc.name}</strong> -
                    <span class="\${svc.running ? 'running' : 'stopped'}">\${svc.running ? 'RUNNING' : 'STOPPED'}</span>
                    <button onclick="control('\${svc.name}', 'start')">Start</button>
                    <button onclick="control('\${svc.name}', 'stop')">Stop</button>
                  \`;
                  container.appendChild(div);
                }
              }

              async function control(name, action) {
                const token = prompt("Enter Marlon token:");
                await fetch("/", {
                  method: "POST",
                  headers: { "Content-Type": "application/json", "X-Marlon-Token": token },
                  body: JSON.stringify({ object: "dashboard_control", service: name, action })
                });
                await fetchStatus();
              }

              fetchStatus();
              setInterval(fetchStatus, 5000); // refresh every 5s
            </script>
          </body>
          </html>
        HTML
      end

      # Integrate with Falcon/Gatekeeper
      def integrate_with_falcon
        # Monkey-patch Gatekeeper to handle dashboard payloads
        gatekeeper = Marlon::Gatekeeper.new
        original_call = gatekeeper.method(:call)

        gatekeeper.define_singleton_method(:call) do |env|
          req = Rack::Request.new(env)
          if req.post?
            body = req.body.read
            payload = JSON.parse(body) rescue {}
            case payload["object"]
            when "dashboard_status"
              services_status = services.map { |svc| { name: svc.name, running: svc.running? } }
              return [200, { "Content-Type" => "application/json" }, [ { services: services_status }.to_json ]]
            when "dashboard_control"
              svc = services.find { |s| s.name == payload["service"] }
              svc.send(payload["action"]) if svc
              return [200, { "Content-Type" => "application/json" }, [ { status: "ok" }.to_json ]]
            end
          end
          original_call.call(env)
        end
      end

      # CLI command integration
      def add_cli_command(cli)
        cli.register_command("dashboard") do |_args|
          puts "🚀 Starting Marlon dashboard at http://localhost:4567/dashboard"
          generate_dashboard_files
          integrate_with_falcon
          # Falcon server already running; just ensure assets are served
          Falcon::Server.new(app: Rack::Directory.new(DASHBOARD_DIR)).run
        end
      end
    end
  end
end
