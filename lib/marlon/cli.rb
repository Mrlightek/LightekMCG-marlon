# lib/marlon/cli.rb
require "thor"
require_relative "installer"
require_relative "server"
require_relative "generators"
require_relative "systemd_manager"
require_relative "activerecord_adapter"

module Marlon
  class CLI < Thor
    package_name "marlon"

    desc "install", "Install marlon into current project"
    def install
      Installer.new.run
    end

    desc "server [PORT]", "Start Falcon HTTP server"
    option :bind, aliases: "-b", default: "0.0.0.0"
    def server(port = 3000)
      # establish AR if configured
      if File.exist?(File.join(Dir.pwd, "config", "database.yml"))
        ActiveRecordAdapter.establish_connection
      end

      Reactor.start do
        Server.start(bind: options[:bind], port: port.to_i)
      end
    end

    desc "g [GENERATOR] [NAME] ...", "Run generators (service, scaffold, migration, payload_router, systemd, proxy)"
    def g(generator = nil, name = nil, *args)
      if generator.nil?
        puts "Available generators: service, scaffold, migration, payload_router, systemd, proxy"
        return
      end
      Generators.exec(generator, name, *args)
    end

    desc "systemd install NAME", "Install & enable systemd unit for service (requires sudo). Use --deploy to auto move/install."
    method_option :deploy, type: :boolean, default: false
    def systemd(action = nil, name = nil)
      if action == "install" && name
        gen = Generators::SystemdGenerator.new(name)
        gen.generate(deploy: options[:deploy])
      else
        puts "Usage: marlon systemd install NAME [--deploy]"
      end
    end

    desc "version", "Show marlon version"
    def version
      puts Marlon::VERSION
    end
  end
end
