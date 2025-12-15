# lib/marlon/reactor/status.rb
require "time"
require "json"

module Marlon::Reactor
  class Status
    @mutex = Mutex.new
    @metrics = {
      started_at: Time.now.utc.iso8601,
      last_reload_at: nil,
      reload_count: 0,
      reload_errors: 0,
      files_reloaded: [],
      last_error: nil,
      services: {},
      watcher_alive: false,
      cpu: { utime: 0.0, stime: 0.0 },
      memory: { rss_kb: nil, gc_mem: nil },
      reactions: { enqueued: 0, processed: 0 }
    }

    class << self
      def snapshot
        @mutex.synchronize { deep_dup(@metrics) }
      end

      def set(key, value)
        @mutex.synchronize { @metrics[key] = value }
      end

      def update_metrics(hash)
        @mutex.synchronize { @metrics.merge!(hash) }
      end

      def mark_reload(file)
        @mutex.synchronize do
          @metrics[:last_reload_at] = Time.now.utc.iso8601
          @metrics[:reload_count] += 1
          @metrics[:files_reloaded] << { file: file, at: Time.now.utc.iso8601 }
          @metrics[:files_reloaded] = @metrics[:files_reloaded].last(200)
        end
      end

      def mark_error(err)
        @mutex.synchronize do
          @metrics[:reload_errors] += 1
          @metrics[:last_error] = { message: err.to_s, at: Time.now.utc.iso8601 }
        end
      end

      def set_watcher_alive(v)
        @mutex.synchronize { @metrics[:watcher_alive] = v }
      end

      def update_services!
        # collect available services and modules
        srv = {}
        if defined?(Marlon::Services)
          Marlon::Services.constants.each { |c| srv[c.to_s] = :top_level }
        end
        if defined?(Marlon::Modules)
          Marlon::Modules.constants.each do |m|
            mod = Marlon::Modules.const_get(m) rescue nil
            next unless mod.is_a?(Module)
            mod.constants.each do |c|
              name = "#{m}::#{c}"
              srv[name] = :module
            end
          end
        end
        @mutex.synchronize { @metrics[:services] = srv }
      end

      def update_cpu_mem!
        # CPU: Process.times
        t = Process.times
        ut = t.utime
        st = t.stime

        # Memory: try /proc/self/status on linux
        rss_kb = nil
        if File.exist?("/proc/self/status")
          begin
            File.read("/proc/self/status").each_line do |l|
              if l.start_with?("VmRSS:")
                rss_kb = l.split[1].to_i
                break
              end
            end
          rescue; end
        end

        # GC memory fallback
        gc_mem = nil
        if defined?(GC)
          stats = GC.stat rescue nil
          gc_mem = stats && stats[:total_allocated_objects] ? stats : nil
        end

        @mutex.synchronize do
          @metrics[:cpu] = { utime: ut, stime: st }
          @metrics[:memory] = { rss_kb: rss_kb, gc: gc_mem }
        end
      end

      private

      def deep_dup(obj)
        Marshal.load(Marshal.dump(obj))
      rescue
        obj.dup rescue obj
      end
    end
  end
end
