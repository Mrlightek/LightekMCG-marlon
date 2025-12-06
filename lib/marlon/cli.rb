require "thor"

module Marlon
  class CLI < Thor
    desc "g GENERATOR NAME", "Generate files (service, model, controller)"
    def g(generator, name, *fields)
      generator = generator.downcase

      case generator
      when "service"
        Marlon::Generators::ServiceGenerator.new(name).generate
      when "model"
        Marlon::Generators::ModelGenerator.new(name, fields).generate
      when "install"
        Marlon::Generators::InstallGenerator.new.generate
      else
        puts "Unknown generator: #{generator}"
      end
    end

    desc "new APP_NAME", "Create a new MARLON-powered gem or service"
    def new(app_name)
      Marlon::Generators::AppGenerator.new(app_name).generate
    end
  end
end
