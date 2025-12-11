#lib/marlon/cli/commands/watch_command.rb

module Marlon::CLI::Commands
    class WatchCommand
      def self.run(port: 3000, bind: "0.0.0.0")
        puts "[Reactor] 🔥 Starting server + auto-watcher..."

        # Start watcher in background thread
        Thread.new do
          Marlon::Reactor::AutoWatcher.start
        end

        # Start server normally
        DBAdapter.establish_connection if File.exist?(File.join(Dir.pwd, "config", "database.yml"))
        Reactor.start do
          Server.start(bind: bind, port: port.to_i)
        end
      end
    end
  end

