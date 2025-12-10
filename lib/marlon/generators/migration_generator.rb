# lib/marlon/generators/migration_generator.rb
require_relative "base_generator"
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
        class_name = @name.split("_").map(&:capitalize).join

        # Determine table_name from name (e.g. create_users -> users)
        table_name = @name.sub(/^create_/, "")

        columns = {}
        # Attempt to load model to get attributes
        begin
          require File.join(Dir.pwd, "lib", "marlon", "models", table_name)
          model_class = Object.const_get(classify(table_name))
          if model_class.respond_to?(:attributes)
            columns = model_class.attributes.transform_keys(&:to_s).transform_values { |v| v[:type] }
            columns.delete("id")
            columns.delete("created_at")
            columns.delete("updated_at")
          end
        rescue LoadError, NameError => e
          puts "[MARLON] No model found for #{table_name} (#{e.class}) — generating migration with defaults"
        end

        content = render("migration.rb.tt", class_name: class_name, table_name: table_name, columns: columns)
        write_file(File.join(Dir.pwd, "db", "migrate", filename), content)
      end

      private

      def classify(name)
        name.to_s.split(/_|-/).map(&:capitalize).join
      end
    end
  end
end
