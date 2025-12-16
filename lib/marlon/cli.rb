# lib/marlon/cli.rb
require "thor"
require "fileutils"
require "json"
require "launchy"
require "time"

require_relative "installer"
require_relative "server"
require_relative "systemd_manager"
require_relative "db_adapter"
require_relative "migrator"
require_relative "migration_runner"
require_relative "service_generator"

# Generators folder (explicit loads)
Dir[File.join(__dir__, "generators", "*.rb")].sort.each { |f| require f }

# Suppress warnings
Warning[:deprecated] = false if defined?(Warning)

# === Core CLI class ===
module Marlon
  class CLI < Thor
    package_name "marlon"

    # --- Basic commands ---
    desc "install", "Install marlon into current project"
    def install
      Installer.new.run
    end

    desc "server [PORT]", "Start Falcon HTTP server with integrated dashboard and live metrics"
    option :bind, aliases: "-b", default: "0.0.0.0"
    option :hot, type: :boolean, default: true
    option :dashboard, type: :boolean, default: true
    def server(port = 3000)
      DBAdapter.establish_connection if File.exist?(File.join(Dir.pwd, "config", "database.yml"))

      Reactor.start do
        Marlon::AutoWatcher.start if options[:hot]

        services_dir = File.join(Marlon::ServiceGenerator::DEFAULT_INSTALL_DIR, "services")
        Dir[File.join(services_dir, "*.rb")].each { |f| require f }

        app = Server.app

        if options[:dashboard]
          dashboard_dir = File.join(Marlon::ServiceGenerator::DEFAULT_INSTALL_DIR, "dashboard")
          FileUtils.mkdir_p(dashboard_dir)
          index_file = File.join(dashboard_dir, "index.html")

          unless File.exist?(index_file)
            File.write(index_file, <<~HTML)
              <!DOCTYPE html>
              <html>
              <head>
                <title>Marlon Dashboard</title>
                <style>
                  body { font-family: sans-serif; background: #f9f9f9; padding: 2rem; }
                  pre { background: #222; color: #0f0; padding: 1rem; overflow: auto; }
                  h3 { margin-top: 1.5rem; }
                </style>
              </head>
              <body>
                <h1>Marlon Observability Dashboard</h1>
                <p>Live metrics for all services.</p>
                <div id="metrics"></div>
                <script>
                  async function fetchMetrics() {
                    const res = await fetch('/__marlon_dashboard/metrics.json');
                    const data = await res.json();
                    const container = document.getElementById('metrics');
                    container.innerHTML = '';
                    Object.keys(data).forEach(service => {
                      const stats = data[service];
                      const div = document.createElement('div');
                      div.innerHTML = `<h3>${service}</h3><pre>${JSON.stringify(stats, null, 2)}</pre>`;
                      container.appendChild(div);
                    });
                  }
                  setInterval(fetchMetrics, 5000);
                  fetchMetrics();
                </script>
              </body>
              </html>
            HTML
          end

          app.mount("/__marlon_dashboard") do |req|
            path = req.path.sub("/__marlon_dashboard", "")
            file = path.empty? || path == "/" ? index_file : File.join(dashboard_dir, path)
            if File.file?(file)
              [200, { "Content-Type" => Rack::Mime.mime_type(File.extname(file)) }, [File.read(file)]]
            else
              [404, {}, ["Dashboard file not found"]]
            end
          end

          metrics_dir = Marlon::ServiceGenerator::DEFAULT_METRICS_DIR
          app.mount("/__marlon_dashboard/metrics.json") do |_req|
            all_metrics = {}
            if Dir.exist?(metrics_dir)
              Dir[File.join(metrics_dir, "*.json")].each do |file|
                service_name = File.basename(file, ".json")
                all_metrics[service_name] =
                  JSON.parse(File.read(file)) rescue { error: "Failed to read metrics" }
              end
            end
            [200, { "Content-Type" => "application/json" }, [all_metrics.to_json]]
          end

          Launchy.open("http://#{options[:bind]}:#{port}/__marlon_dashboard") rescue nil
        end

        puts "🚀 Marlon server running on #{options[:bind]}:#{port}"
        Server.start(bind: options[:bind], port: port.to_i, app: app)
      end
    end

    # --- start all ---
    desc "start:all", "Start all Marlon services with dashboard and live metrics"
    option :bind, aliases: "-b", default: "0.0.0.0"
    option :port, aliases: "-p", default: 3000
    option :hot, type: :boolean, default: true
    def start_all
      services_dir = File.join(Marlon::ServiceGenerator::DEFAULT_INSTALL_DIR, "services")
      unless Dir.exist?(services_dir)
        puts "No services found in #{services_dir}"
        return
      end

      Dir[File.join(services_dir, "*.rb")].each { |f| require f }

      invoke :server, [options[:port]],
             dashboard: true,
             bind: options[:bind],
             hot: options[:hot]
    end

    # --- stop all (FIXED SCOPE) ---
    desc "stop:all", "Gracefully stop all Marlon services and the server"
    def stop_all
      puts "🛑 Stopping Marlon services..."

      if defined?(Falcon::Server)
        Falcon::Server.stop rescue nil
        puts "✔ Falcon server stopped"
      end

      Thread.list.each do |t|
        next if t == Thread.main
        t.kill rescue nil
      end
      puts "✔ Service threads terminated"

      metrics_dir = Marlon::ServiceGenerator::DEFAULT_METRICS_DIR
      if Dir.exist?(metrics_dir)
        Dir[File.join(metrics_dir, "*.json")].each do |file|
          begin
            data = JSON.parse(File.read(file))
            data["status"] = "stopped"
            data["stopped_at"] = Time.now.utc.iso8601
            File.write(file, JSON.pretty_generate(data))
          rescue
          end
        end
        puts "✔ Metrics flushed"
      end

      puts "✅ Marlon fully stopped"
    end
  end
end

# === Load all CLI commands AFTER CLI class exists ===
Dir[File.join(__dir__, "cli", "commands", "*.rb")].sort.each { |f| require f }

Marlon::CLI::Commands.constants.each do |command_class|
  klass = Marlon::CLI::Commands.const_get(command_class)
  klass.register(Marlon::CLI) if klass.respond_to?(:register)
end
