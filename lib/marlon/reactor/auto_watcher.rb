# lib/marlon/reactor/auto_watcher.rb
require "listen"
require_relative "../docs/parser"
require_relative "../docs/markdown_generator"
require_relative "../docs/playground_generator"

module Marlon
  module Reactor
    class AutoWatcher
      WATCH_PATHS = ["./services", "./commands", "./lib/marlon"]

      # Start watching directories
      def self.start
        puts "[Reactor] 👀 Starting auto-watcher..."
        listener = Listen.to(*WATCH_PATHS) do |modified, added, removed|
          handle_changes(modified, "modified") unless modified.empty?
          handle_changes(added, "added")       unless added.empty?
          handle_changes(removed, "removed")   unless removed.empty?
        end
        listener.start
        sleep
      end

      # Handle file changes
      def self.handle_changes(files, change_type)
        files.each do |file|
          begin
            load file
            puts "[Reactor] ♻️ Reloaded #{file} (#{change_type})"
          rescue => e
            puts "[Reactor] ⚠️ Error reloading #{file}: #{e.message}"
          end
        end

        regen_docs
      end

      # Regenerate all docs and API Playground
      def self.regen_docs
        docs = Marlon::Docs::Parser.parse(WATCH_PATHS)
        Marlon::Docs::MarkdownGenerator.generate(docs)
        Marlon::Docs::PlaygroundGenerator.generate(docs)
        puts "[Reactor] 📘 Docs regenerated"
      rescue => e
        puts "[Reactor] ⚠️ Error regenerating docs: #{e.message}"
      end
    end
  end
end
