# lib/marlon/migration_runner.rb
module Marlon
  class MigrationRunner
    MIGRATE_DIR = File.join(Dir.pwd, "db", "migrate")

    def self.run
      raise "[MARLON] No DB connection established" unless Marlon::DB.adapter

      Dir[File.join(MIGRATE_DIR, "*.rb")].sort.each do |file|
        require file
        class_name = File.basename(file, ".rb").split("_").map(&:capitalize).join
        if Object.const_defined?(class_name)
          migration_class = Object.const_get(class_name)
          migration_class.up
          puts "[MARLON] Migrated #{class_name}"
        else
          puts "[MARLON] Could not find class #{class_name} in #{file}"
        end
      end
    end
  end
end
