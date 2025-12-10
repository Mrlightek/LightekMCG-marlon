# lib/marlon/migrator.rb
require "fileutils"

module Marlon
  class Migrator
    SCHEMA_TABLE = "marlon_schema_migrations"
    MIGRATE_DIR = File.join(Dir.pwd, "db", "migrate")

    def initialize
      raise "[MARLON] DB not connected" unless Marlon::DB.adapter
      ensure_schema_table!
    end

    def ensure_schema_table!
      # create schema table if missing
      Marlon::DB.ensure_table(SCHEMA_TABLE, { "version" => :string })
    end

    def applied_versions
      rows = Marlon::DB.where(SCHEMA_TABLE, {})
      rows.map { |r| (r["version"] || r[:version]).to_s }
    end

    def run
      files = Dir[File.join(MIGRATE_DIR, "*.rb")].sort
      files.each do |file|
        version = File.basename(file).split("_").first
        next if applied_versions.include?(version)

        require file
        class_name = File.basename(file, ".rb").split("_").map(&:capitalize).join
        if Object.const_defined?(class_name)
          migration_class = Object.const_get(class_name)
          migration_class.up
          record_version(version)
          puts "[MARLON] Migrated #{class_name} (#{version})"
        else
          puts "[MARLON] Migration class #{class_name} not found in #{file}"
        end
      end
    end

    def record_version(version)
      Marlon::DB.save(SCHEMA_TABLE, { "version" => version })
    end
  end
end
