# lib/marlon/reactor/auto_watcher.rb
require "listen"

module Marlon
  class AutoWatcher
    WATCH_DIRS = [
      File.join(Dir.pwd, "lib", "marlon"),
      File.join(Dir.pwd, "services"),
      File.join(Dir.pwd, "commands")
    ].freeze

    def self.start
      listener = Listen.to(*WATCH_DIRS, only: /\.rb$/) do |modified, added, removed|
        (modified + added).each { |file| reload_file(file) }
      end

      puts "[Reactor] 🔥 Hot-Reload Active — watching #{WATCH_DIRS.join(", ")}"
      listener.start
    end

    def self.reload_file(path)
      relative = path.sub(Dir.pwd + "/", "")

      puts "[Reactor] ♻️  Reloading #{relative} at #{Time.now}"

      # unload old constants
      unload_constants_for(path)

      # reload the file
      load path
    rescue => e
      puts "[Reactor] ❌ Failed to reload #{relative}: #{e}"
    end

    def self.unload_constants_for(path)
      source = File.read(path)
      constants = source.scan(/class\s+([A-Z]\w*)|module\s+([A-Z]\w*)/)
                       .flatten.compact

      constants.each do |const|
        parent = Object
        if parent.const_defined?(const)
          parent.send(:remove_const, const)
          puts "[Reactor]   → Unloaded #{const}"
        end
      end
    end
  end
end
