# lib/marlon/generators/scaffold_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class ScaffoldGenerator < BaseGenerator
      def initialize(name)
        raise "Name required" unless name
        @name = name
        @class_name = name.split(/_|-/).map(&:capitalize).join
        @file_name = name.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
      end

      def generate
        # Service
        svc = render("service.rb.tt", class_name: "#{@class_name}Service")
        write_file(File.join(Dir.pwd, "app", "marlon", "services", "#{@file_name}_service.rb"), svc)

        # payload
        payload = render("payload.rb.tt", class_name: @class_name)
        write_file(File.join(Dir.pwd, "app", "marlon", "payloads", "#{@file_name}_payload.rb"), payload)

        # migration
        MigrationGenerator.new("create_#{Marlon::Inflector.pluralize(@file_name)}").generate

        # router entry
        entry = "Marlon::Router.map(\"#{@file_name}\", Marlon::Services::#{@class_name}Service)\n"
        append_file(File.join(Dir.pwd, "config", "marlon_routes.rb"), entry)
        puts "Scaffold created for #{@name}"
      end
    end
  end
end
