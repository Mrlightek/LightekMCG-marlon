# lib/marlon/modules/cloud/models/job.rb
require "active_record"
require "json"

module Marlon
  module Modules
    module Cloud
      class Job < ActiveRecord::Base
        self.table_name = "marlon_jobs"
        serialize :payload, JSON

        scope :pending, -> { where(status: "pending") }

        def self.pending_for_agent(agent_id)
          pending.limit(10).map do |j|
            { "id" => j.id, "type" => j.job_type, "payload" => j.payload }
          end
        end

        def self.mark_complete(job_id, result = {})
          j = find(job_id) rescue nil
          return unless j
          j.update!(status: "complete", result: result.to_json)
        end

        def self.mark_failed(job_id, error)
          j = find(job_id) rescue nil
          return unless j
          j.update!(status: "failed", result: { error: error }.to_json)
        end
      end
    end
  end
end
