# lib/marlon/generators/migration_generator.rb
require_relative "base_generator"
require_relative "../inflector"
require "time"

module Marlon
  module Generators
    class MigrationGenerator < BaseGenerator
      def initialize(name)
        raise "Migration name required" unless name
        @name = name
      end

      def generate
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        filename = "#{timestamp}_#{@name}.rb"
        class_name = Marlon::Inflector.camelize(@name)

        content = render("migration.rb.tt", class_name: class_name)
        write_file(File.join(Dir.pwd, "db", "migrate", filename), content)
      end
    end
  end
end
