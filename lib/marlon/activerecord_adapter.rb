# # lib/marlon/activerecord_adapter.rb
# require "active_record"
# require "yaml"
# require "erb"

# module Marlon
#   module ActiveRecordAdapter
#     def self.load_database_yml(path = File.join(Dir.pwd, "config", "database.yml"))
#       return {} unless File.exist?(path)
#       YAML.load(ERB.new(File.read(path)).result)
#     end

#     def self.establish_connection(env = ENV["MARLON_ENV"] || "development")
#       cfg = load_database_yml
#       if cfg[env]
#         ActiveRecord::Base.establish_connection(cfg[env])
#         puts "[MARLON] ActiveRecord connected (#{env})"
#       else
#         puts "[MARLON] No database config for env #{env} at config/database.yml"
#       end
#     end

#     def self.run_migrations(migrate_dir = File.join(Dir.pwd, "db", "migrate"))
#       if Dir.exist?(migrate_dir)
#         ActiveRecord::Migrator.migrate(migrate_dir)
#       else
#         puts "No migrations directory at #{migrate_dir}"
#       end
#     end
#   end
# end
