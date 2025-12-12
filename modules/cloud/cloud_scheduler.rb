# marlon/modules/cloud/cloud_scheduler.rb
require 'thread'

module Marlon
  module Modules
    module Cloud
      class CloudScheduler
        @queue = Queue.new

        class << self
          def enqueue(job_name, params)
            @queue << { job: job_name, params: params }
            Thread.new { process } # simple multi-threaded execution

            Marlon::Reactor::Status.update_metrics(reactions: { enqueued: Marlon::Reactor::Status.snapshot[:reactions][:enqueued] + 1 })
           # after processing:
           Marlon::Reactor::Status.update_metrics(reactions: { processed: Marlon::Reactor::Status.snapshot[:reactions][:processed] + 1 })
          end

          def process
            until @queue.empty?
              item = @queue.pop
              job_class = Object.const_get("Marlon::Modules::Cloud::Reactions::#{item[:job].to_s.split('_').map(&:capitalize).join}")
              job_class.perform(item[:params])
            end
          end
        end
      end
    end
  end
end
