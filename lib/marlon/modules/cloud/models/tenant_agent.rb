# lib/marlon/modules/cloud/models/tenant_agent.rb
require "active_record"
require "json"

module Marlon
  module Modules
    module Cloud
      class TenantAgent < ActiveRecord::Base
        self.table_name = "marlon_tenant_agents"
        serialize :metrics, JSON

        def self.upsert(attrs)
          a = find_by(agent_id: attrs[:agent_id]) || new(agent_id: attrs[:agent_id])
          a.hostname = attrs[:hostname] if attrs[:hostname]
          a.ip = attrs[:ip] if attrs[:ip]
          a.metrics = attrs[:metrics] if attrs[:metrics]
          a.last_seen = attrs[:last_seen] || Time.now.utc
          a.save!; a
        end
      end
    end
  end
end
