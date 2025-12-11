# lib/marlon/reactor/auto_watcher.rb
require "listen"
require_relative "../docs/parser"
require_relative "../docs/markdown_generator"
require_relative "../docs/playground_generator"

require "digest"
require "yaml"

module Marlon::Reactor
  class AutoWatcher
    HEARTBEAT_INTERVAL = 5
    CORE_FILES = %w[
      lib/marlon/server.rb
      lib/marlon/reactor.rb
      lib/marlon/gatekeeper.rb
      lib/marlon/marlon.rb
    ]

    def self.start
      puts "[Reactor] 🔥 Auto-watcher active"

      @watched_dirs = load_watch_dirs
      @file_hashes = snapshot_files

      heartbeat_thread
      watch_loop
    end

    def self.load_watch_dirs
      config_file = "config/marlon/watch.yml"
      dirs = ["services", "commands", "lib/marlon"]

      if File.exist?(config_file)
        config = YAML.load_file(config_file)
        dirs += Array(config["watch"])
      end

      dirs.uniq.select { |d| Dir.exist?(d) }
    end

    def self.snapshot_files
      files = {}

      @watched_dirs.each do |dir|
        Dir["#{dir}/**/*.rb"].each do |file|
          files[file] = Digest::SHA256.file(file).hexdigest
        end
      end

      files
    end

    def self.watch_loop
      loop do
        sleep 1
        @file_hashes.keys.each do |file|
          next unless File.exist?(file)

          new_hash = Digest::SHA256.file(file).hexdigest

          if new_hash != @file_hashes[file]
            @file_hashes[file] = new_hash
            handle_change(file)
          end
        end
      end
    end

    def self.handle_change(file)
      if CORE_FILES.include?(file)
        puts "[Reactor] ♻️ Core file changed (#{file}). Restarting…"
        exec("marlon watch")
      end

      puts "[Reactor] ✏️ Reloading: #{file}"

      diff = compute_diff(file)
      puts diff unless diff.empty?

      begin
        load file
        Marlon::Reactor.regen_docs if Marlon.const_defined?(:Reactor)
        puts "[Reactor] ✅ Reloaded"
      rescue => e
        puts "[Reactor] 💥 Reload failed in #{file}"
        puts "Error: #{e.class} - #{e.message}"
      end
    end

    def self.compute_diff(file)
      old_content = (@previous_content ||= {})[file] || ""
      new_content = File.read(file)

      @previous_content[file] = new_content

      old_lines = old_content.split("\n")
      new_lines = new_content.split("\n")

      diff_output = ""

      new_lines.each_with_index do |line, idx|
        diff_output << "+ #{line}\n" if old_lines[idx] != line
      end

      diff_output
    end

    def self.heartbeat_thread
      Thread.new do
        loop do
          sleep HEARTBEAT_INTERVAL
          puts "[Reactor] 🔄 Watching… (#{@file_hashes.size} files)"
        end
      end
    end
  end
end


# module Marlon
#   module Reactor
#     class AutoWatcher
#       WATCH_PATHS = ["./services", "./commands", "./lib/marlon"]

#       # Start watching directories
#       def self.start
#         puts "[Reactor] 👀 Starting auto-watcher..."
#         listener = Listen.to(*WATCH_PATHS) do |modified, added, removed|
#           handle_changes(modified, "modified") unless modified.empty?
#           handle_changes(added, "added")       unless added.empty?
#           handle_changes(removed, "removed")   unless removed.empty?
#         end
#         listener.start
#         sleep
#       end

#       # Handle file changes
#       def self.handle_changes(files, change_type)
#         files.each do |file|
#           begin
#             load file
#             puts "[Reactor] ♻️ Reloaded #{file} (#{change_type})"
#           rescue => e
#             puts "[Reactor] ⚠️ Error reloading #{file}: #{e.message}"
#           end
#         end

#         regen_docs
#       end

#       # Regenerate all docs and API Playground
#       def self.regen_docs
#         docs = Marlon::Docs::Parser.parse(WATCH_PATHS)
#         Marlon::Docs::MarkdownGenerator.generate(docs)
#         Marlon::Docs::PlaygroundGenerator.generate(docs)
#         puts "[Reactor] 📘 Docs regenerated"
#       rescue => e
#         puts "[Reactor] ⚠️ Error regenerating docs: #{e.message}"
#       end
#     end
#   end
# end
