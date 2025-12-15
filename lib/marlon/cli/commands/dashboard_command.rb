# lib/marlon/cli/commands/dashboard_command.rb
require "io/console"
require "json"

module Marlon::CLI::Commands
  class DashboardCommand
    REFRESH = 1.0

    def self.run
      puts "[Marlon] Opening Terminal Dashboard — press Ctrl-C to exit"
      trap("INT") { puts "\n[Marlon] Dashboard exiting."; exit }

      loop do
        draw_screen
        sleep REFRESH
      end
    end

    def self.draw_screen
      status = Marlon::Reactor::Status.snapshot
      clear_screen
      puts "=== MARLON DASHBOARD — #{Time.now.utc.iso8601} ==="
      puts "Watcher: #{status[:watcher_alive] ? '●' : '○'}   Reloads: #{status[:reload_count]}   Errors: #{status[:reload_errors]}"
      puts "Last reload: #{status[:last_reload_at] || 'never'}"
      puts "Files reloaded (latest 10):"
      status[:files_reloaded].last(10).each do |f|
        puts "  - #{f[:file]} @ #{f[:at]}"
      end
      puts "-"*60
      puts "Services (#{status[:services].keys.size}):"
      status[:services].keys.first(30).each_with_index do |s,i|
        puts "  #{i+1}. #{s}"
      end
      puts "-"*60
      cpu = status[:cpu]
      mem = status[:memory]
      puts "CPU (utime/stime): #{'%.2f' % cpu[:utime]}s / #{'%.2f' % cpu[:stime]}s"
      if mem[:rss_kb]
        puts "Memory RSS: #{mem[:rss_kb]} KB"
      else
        puts "Memory: (no /proc) GC stats: #{mem[:gc] ? mem[:gc].inspect : 'n/a'}"
      end
      puts "-"*60
      puts "Reactions: enqueued=#{status[:reactions][:enqueued]} processed=#{status[:reactions][:processed]}"
      puts "-"*60
      puts "Hints: Ctrl-C to quit | marlon watch runs server + watcher | marlon dashboard opens this UI"
    end

    def self.clear_screen
      print "\e[2J\e[f"
    end
  end
end
