# lib/marlon/cli/commands/live_console_command.rb
require "irb"

module Marlon::CLI::Commands
  class LiveConsoleCommand
    def self.run
      puts "[Marlon] Starting live console. Type `help_reload` to run docs reload, `status` to view snapshot."
      define_reload_helpers
      ARGV.clear
      IRB.start
    end

    def self.define_reload_helpers
      # define a few methods in main
      main = TOPLEVEL_BINDING.eval("self")
      main.define_singleton_method(:help_reload) do
        puts "help_reload: regenerates docs and prints status"
        Marlon::Reactor::AutoWatcher.regen_docs rescue nil
        p Marlon::Reactor::Status.snapshot
      end

      main.define_singleton_method(:status) do
        p Marlon::Reactor::Status.snapshot
      end

      main.define_singleton_method(:reload_file) do |path|
        load path
        puts "reloaded #{path}"
      end
    end
  end
end
