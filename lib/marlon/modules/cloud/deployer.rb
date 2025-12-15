# lib/marlon/modules/cloud/deployer.rb
module Marlon
  module Modules
    module Cloud
      class Deployer
        def initialize(ovh_provider: nil)
          @ovh = ovh_provider || OVHProvider.new
        end

        # Provision a tenant VM and return tenant metadata
        def provision_tenant(slug:, plan:, ssh_keys: [])
          res = @ovh.create_instance(name: "marlon-#{slug}", image: "ubuntu-22.04", flavor: plan, ssh_keys: ssh_keys)
          ip = res[:ip]
          tenant = Tenant.create(slug: slug, ip: ip, ovh_id: res[:id], plan: plan)
          # Optionally create a bootstrap job for the agent to run (control-plane holds script url)
          tenant
        end

        # Schedule deploy by creating Job records for selected tenants
        def schedule_rollout(artifact_url:, signature_url:, tenants:, batch_size: 10, pause_s: 600)
          tenants.each do |tenant|
            Job.create!(tenant: tenant.slug, job_type: "deploy_bundle", payload: { artifact_url: artifact_url, signature_url: signature_url })
          end
          { scheduled: true, count: tenants.size }
        end
      end
    end
  end
end
