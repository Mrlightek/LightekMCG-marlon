module Marlon::CLI::Commands
  class Provision
    def self.call(args)
      require_relative "../../marlon"
      Marlon.boot!    # ensures DB + config + routing + modules load

      slug = args[0]
      plan = args[1] || "basic"

      deployer = Marlon::Modules::Cloud::Deployer.new
      tenant = deployer.provision_tenant(slug: slug, plan: plan)

      puts "Tenant provisioned: #{tenant.inspect}"
    end
  end
end
