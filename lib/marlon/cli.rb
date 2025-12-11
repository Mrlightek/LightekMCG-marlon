# lib/marlon/cli.rb
require "thor"
require_relative "installer"
require_relative "server"
require_relative "generators"
require_relative "systemd_manager"
require_relative "db_adapter"
require_relative "migrator"
require_relative "migration_runner" rescue nil

# === Core CLI class ===
module Marlon
  class CLI < Thor
    package_name "marlon"

    # --- Basic commands ---
    desc "install", "Install marlon into current project"
    def install
      Installer.new.run
    end

    desc "server [PORT]", "Start Falcon HTTP server"
    option :bind, aliases: "-b", default: "0.0.0.0"
    option :hot, type: :boolean, default: true
    def server(port = 3000)
      DBAdapter.establish_connection if File.exist?(File.join(Dir.pwd, "config", "database.yml"))

      Reactor.start do
        Marlon::AutoWatcher.start if options[:hot]
        Server.start(bind: options[:bind], port: port.to_i)
      end
    end

    desc "g [GENERATOR] [NAME] ...", "Run generators (model, migration, scaffold, service, systemd, proxy)"
    def g(generator = nil, name = nil, *args)
      if generator.nil?
        puts "Available generators: model, migration, scaffold, service, systemd, proxy"
        return
      end
      Generators.exec(generator, name, *args)
    end

    # --- DB commands ---
    desc "generate:model NAME [fields...]", "Generate a model. fields: title:string user:references"
    def generate_model(name, *fields)
      Generators::ModelGenerator.new(name, fields).generate
    end

    desc "generate:migration NAME", "Generate a migration. Uses model attributes if model exists."
    def generate_migration(name)
      Generators::MigrationGenerator.new(name).generate
    end

    desc "db:setup", "Establish DB connection and run migrations"
    def db_setup
      DBAdapter.establish_connection
      Migrator.new.run
    end

    desc "db:migrate", "Run pending migrations"
    def db_migrate
      DBAdapter.establish_connection
      Migrator.new.run
    end

    # --- Console & version ---
    desc "console", "Start interactive Marlon console (loads models and DB)"
    def console
      DBAdapter.establish_connection if File.exist?(File.join(Dir.pwd, "config", "database.yml"))
      Dir[File.join(Dir.pwd, "lib", "marlon", "models", "*.rb")].each { |f| require f }
      require "irb"
      ARGV.clear
      IRB.start
    end

    desc "version", "Show marlon version"
    def version
      puts Marlon::VERSION
    end

    # --- CLI generators ---
    desc "g:command NAME", "Create a new CLI command + generator + service"
    def g_command(name)
      Marlon::Generators::CommandGenerator.new(name).generate
    end

    desc "g:module NAME", "Generate a full Marlon module"
    def g_module(name)
      Marlon::Generators::ModuleGenerator.new(name).generate
    end
  end
end

# === Load all CLI commands AFTER CLI class exists ===
Dir[File.join(__dir__, "cli", "commands", "*.rb")].sort.each { |f| require f }

# Wire all commands dynamically
Marlon::CLI::Commands.constants.each do |command_class|
  klass = Marlon::CLI::Commands.const_get(command_class)
  klass.register(Marlon::CLI) if klass.respond_to?(:register)
end
