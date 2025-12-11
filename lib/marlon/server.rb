# lib/marlon/server.rb
require "falcon"
require "async"
require "json"
require "yaml"

module Marlon
  class Server
    def self.load_project_routes
      path = File.join(Dir.pwd, "config", "marlon_routes.rb")
      load(path) if File.exist?(path)
      true
    end

    def self.app
      load_project_routes
      # Build a simple Falcon app with Gatekeeper mount + static file serving + proxy
      gatekeeper = Gatekeeper.new(Marlon.config["gatekeeper"] || {})

      builder = Falcon::Server.build do |server|
        # Enables server endpoint that reports the latest modification time in public/docs/

        #Notes:
         
         #This returns JSON like { "last_modified": 1700000000 } where the value is a UNIX second timestamp.
        #No background process required — it computes max mtime on demand.

      server.map "/marlon/docs/last_modified" do
       run lambda { |env|
       docs_dir = File.join(Dir.pwd, "public", "docs")
       unless Dir.exist?(docs_dir)
      return [404, { "Content-Type" => "application/json" }, [{ error: "no_docs" }.to_json]]
    end

    files = Dir[File.join(docs_dir, "**", "*")].select { |f| File.file?(f) }
    last_mtime = files.map { |f| File.mtime(f).to_i }.max || 0

    body = { last_modified: last_mtime, generated_at: Time.now.to_i }
    [200, { "Content-Type" => "application/json" }, [body.to_json]]
  }
end

        # mount /marlon/gatekeeper to gatekeeper Rack app
        server.map "/marlon/gatekeeper" do
          run gatekeeper
        end

        # static serve public/
        public_dir = File.join(Dir.pwd, "public")
        if Dir.exist?(public_dir)
          server.map "/" do
            run Rack::File.new(public_dir)
          end
        else
          server.map "/" do
            run lambda { |env| [200, { "Content-Type" => "application/json" }, [ { status: "marlon", version: Marlon::VERSION }.to_json ]] }
          end
        end

        # optionally mount proxy rules from config/proxy.yml
        proxy_cfg = {}
        proxy_path = File.join(Dir.pwd, "config", "proxy.yml")
        if File.exist?(proxy_path)
          proxy_cfg = YAML.load_file(proxy_path) || {}
          if proxy_cfg["proxy"].is_a?(Hash)
            proxy_cfg["proxy"].each do |mount, backend|
              server.map mount do
                run lambda { |env|
                  # Use HttpProxy to forward
                  proxy = Proxy::HttpProxy.new
                  proxy.forward(env, backend)
                }
              end
            end
          end
        end
      end

      builder
    end

    def self.start(bind: "0.0.0.0", port: 3000)
      puts "[MARLON] Starting Falcon-based server on #{bind}:#{port}"
      # Falcon's own runner expects env args — run directly with Async
      Async do
        server = app
        server.run
      end
      # keep main thread alive
      sleep
    rescue Interrupt
      puts "[MARLON] Shutting down server..."
      Reactor.shutdown
      exit(0)
    end
  end
end
