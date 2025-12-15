# lib/marlon/reactor.rb
require "async"
require "async/notification"
require "concurrent-ruby"

module Marlon
  module Reactor
    @supervisors = []
    @root_task = nil

    class Supervisor
      def initialize(name:, restart: :permanent)
        @name = name
        @restart = restart
        @children = {}
        @mutex = Mutex.new
      end

      def start_child(key, &block)
        @mutex.synchronize do
          stop_child(key) if @children[key]
          fiber = Async do |task|
            begin
              block.call(task)
            rescue => e
              puts "[Reactor::Supervisor] child #{key} crashed: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
              raise e
            end
          end
          @children[key] = fiber
        end
      end

      def stop_child(key)
        @mutex.synchronize do
          t = @children.delete(key)
          t.stop if t
        end
      end

      def stop_all
        @mutex.synchronize do
          @children.each { |k, t| t.stop rescue nil }
          @children.clear
        end
      end
    end

    def self.start(&block)
      Thread.new { Marlon::AutoWatcher.start }
      block.call
    end

    def self.create_supervisor(name:, restart: :permanent)
      s = Supervisor.new(name: name, restart: restart)
      @supervisors << s
      s
    end

    def self.shutdown
      @supervisors.each(&:stop_all)
      @root_task&.stop
    end

    def self.run_in_background(&block)
      Async do |task|
        block.call(task)
      end
    end

    # simplified message queue
    def self.pubsub
      @pubsub ||= Concurrent::Map.new
    end

    def self.publish(channel, payload)
      (pubsub[channel.to_s] || []).each do |cb|
        cb.call(payload)
      end
    end

    def self.subscribe(channel, &cb)
      pubsub[channel.to_s] ||= Concurrent::Array.new
      pubsub[channel.to_s] << cb
      cb
    end
  end
end
