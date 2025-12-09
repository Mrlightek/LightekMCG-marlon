# lib/marlon/generators.rb
require_relative "marlon/generators/base_generator"
require_relative "marlon/generators/service_generator"
require_relative "marlon/generators/scaffold_generator"
require_relative "marlon/generators/migration_generator"
require_relative "marlon/generators/payload_router_generator"
require_relative "marlon/generators/systemd_generator"
require_relative "marlon/generators/proxy_generator"

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
      else
        puts "Unknown generator: #{cmd}"
      end
    end
  end
end
