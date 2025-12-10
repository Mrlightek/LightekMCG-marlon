# lib/marlon/installer.rb
require "fileutils"
require "erb"

module Marlon
  class Installer
    def initialize(root = Dir.pwd)
      @cwd = root
    end

    def run
      create_dirs
      create_config
      create_routes_loader
      create_gatekeeper
      puts "Marlon installed into #{@cwd}"
    end

    private

    def create_dirs
      %w[config app/marlon/services app/marlon/payloads app/marlon/routers db/migrate public].each do |d|
        path = File.join(@cwd, d)
        FileUtils.mkdir_p(path)
      end
    end

    def create_config
      cfg = File.join(@cwd, "config", "marlon.yml")
      unless File.exist?(cfg)
        tpl = File.read(File.join(File.dirname(__FILE__), "templates", "marlon.yml.tt"))
        File.write(cfg, ERB.new(tpl).result)
        puts "Created #{cfg}"
      end

      proxy = File.join(@cwd, "config", "proxy.yml")
      unless File.exist?(proxy)
        tpl = File.read(File.join(File.dirname(__FILE__), "templates", "proxy.yml.tt"))
        File.write(proxy, ERB.new(tpl).result)
        puts "Created #{proxy}"
      end
    end

    def create_gatekeeper
      path = File.join(@cwd, "app", "gatekeeper.rb")
      unless File.exist?(path)
        tpl = File.read(File.join(File.dirname(__FILE__), "templates", "gatekeeper.rb.tt")) rescue nil
        if tpl
          File.write(path, ERB.new(tpl).result)
        else
          File.write(path, <<~RUBY)
            # simple gatekeeper
            require_relative "../../lib/marlon/gatekeeper"
          RUBY
        end
        puts "Created #{path}"
      end
    end

    def create_routes_loader
      path = File.join(@cwd, "config", "marlon_routes.rb")
      unless File.exist?(path)
        File.write(path, "# This file is loaded by marlon server on start\n")
        puts "Created #{path}"
      end
    end
  end
end
