# lib/marlon/cli/commands/cloud_command.rb
module Marlon::CLI::Commands
  class CloudCommand
    # Usage:
    # marlon cloud create_tenant acme standard
    def self.register(cli)
      cli.desc "cloud create_tenant SLUG PLAN", "Provision a tenant VM (calls Cloud::Deployer via internal service)"
      cli.define_method("cloud:create_tenant") do |slug, plan = "standard"|
        res = Marlon.route(service: "Cloud::Deployer", action: "provision_tenant", payload: { "slug" => slug, "plan" => plan })
        puts res.inspect
      end

      cli.desc "cloud schedule_deploy ARTIFACT_URL SIGNATURE_URL TENANT1,TENANT2", "Schedule a rollout"
      cli.define_method("cloud:schedule_deploy") do |artifact_url, signature_url, tenants_csv|
        tenants = tenants_csv.split(",")
        res = Marlon.route(service: "Cloud::Deployer", action: "schedule_rollout", payload: { "artifact_url" => artifact_url, "signature_url" => signature_url, "tenants" => tenants })
        puts res.inspect
      end
    end
  end
end
