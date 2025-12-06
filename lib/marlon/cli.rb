# lib/marlon/cli.rb
require "thor"
require "fileutils"

module Marlon
  class CLI < Thor
    desc "g GENERATOR NAME [fields...]", "Generate files: service, model, gatekeeper, router, install, framework"
    def g(generator, name = nil, *fields)
      generator = generator.to_s.downcase
      case generator
      when "service"
        ensure_name!(name)
        Generators::ServiceGenerator.new(name).generate
      when "model"
        ensure_name!(name)
        Generators::ModelGenerator.new(name, fields).generate
      when "gatekeeper"
        Generators::GatekeeperGenerator.new.generate
      when "router"
        Generators::RouterGenerator.new.generate
      when "install"
        Generators::InstallGenerator.new.generate
      when "framework"
        ensure_name!(name)
        Generators::FrameworkGenerator.new(name).generate
      else
        puts "Unknown generator: #{generator}"
      end
    end

    desc "new-framework NAME", "Create a complete MARLON gem scaffold (alias for g framework NAME)"
    def new_framework(name)
      Generators::FrameworkGenerator.new(name).generate
    end

    desc "version", "Show MARLON version"
    def version
      puts Marlon::VERSION
    end

    private

    def ensure_name!(name)
      raise Thor::Error, "You must provide a NAME" unless name
    end
  end
end
