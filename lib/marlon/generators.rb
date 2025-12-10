# lib/marlon/generators.rb
require_relative "generators/base_generator"
require_relative "generators/service_generator"
require_relative "generators/scaffold_generator"
require_relative "generators/migration_generator"
require_relative "generators/payload_router_generator"
require_relative "generators/systemd_generator"
require_relative "generators/proxy_generator"

module Marlon
  module Generators
    module_function

    def exec(cmd, name = nil, *args)
      case cmd.to_s.downcase
      when "service"
        ServiceGenerator.new(name).generate
      when "scaffold"
        ScaffoldGenerator.new(name).generate
      when "migration", "migrate"
        MigrationGenerator.new(name).generate
      when "payload_router"
        PayloadRouterGenerator.new(name).generate
      when "systemd"
        SystemdGenerator.new(name).generate(*args)
      when "proxy"
        ProxyGenerator.new.generate
      when "model"
        ModelGenerator.new(name, args).generate
      when "router"
        RouterGenerator.new.generate
      else
        puts "Unknown generator: #{cmd}"
      end
    end
  end
end
