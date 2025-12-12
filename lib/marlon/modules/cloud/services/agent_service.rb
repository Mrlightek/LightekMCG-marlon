# lib/marlon/modules/cloud/services/agent_service.rb
require "json"

module Marlon
  module Modules
    module Cloud
      module Services
        class Agent
          # payload expected keys: agent_id, hostname, local_ip, metrics, etc.
          def register(params = {})
            agent_id = params["agent_id"]
            hostname = params["hostname"]
            ip = params["local_ip"]
            # Persist agent metadata to DB (TenantAgent model) - simple in-memory for skeleton
            TenantAgent.upsert({ agent_id: agent_id, hostname: hostname, ip: ip, last_seen: Time.now.utc })
            { ok: true, agent_id: agent_id }
          end

          def heartbeat(params = {})
            agent_id = params["agent_id"]
            metrics = params["metrics"] || {}
            TenantAgent.upsert({ agent_id: agent_id, last_seen: Time.now.utc, metrics: metrics })
            # Return any immediate commands? For now, no.
            { ok: true }
          end

          # Agent polls for jobs; return list of jobs assigned to agent
          def poll_jobs(params = {})
            agent_id = params["agent_id"]
            jobs = Job.pending_for_agent(agent_id)
            { jobs: jobs }
          end

          def job_complete(params = {})
            agent_id = params["agent_id"]
            job_id = params["job_id"]
            result = params["result"] || {}
            Job.mark_complete(job_id, result)
            { ok: true }
          end

          def job_failed(params = {})
            agent_id = params["agent_id"]
            job_id = params["job_id"]
            err = params["error"]
            Job.mark_failed(job_id, err)
            { ok: true }
          end
        end
      end
    end
  end
end
