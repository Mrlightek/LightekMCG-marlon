# lib/marlon/generators/systemd_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class SystemdGenerator < BaseGenerator
      def initialize(name)
        raise "Name required" unless name
        @name = name
        @file_name = name.to_s.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
      end

      def generate(deploy: false)
        unit = render("systemd.service.tt", unit_name: @file_name, exec: exec_path(@file_name))
        tmp = Marlon::SystemdManager.write_unit_to_tmp(@file_name, unit)
        puts "Unit written to #{tmp}"
        if deploy
          Marlon::SystemdManager.install_unit_from_tmp(@file_name, force: true)
          Marlon::SystemdManager.enable_and_start(@file_name)
          puts "Installed and started systemd service marlon-#{@file_name}"
        else
          puts "Run: sudo mv #{tmp} /etc/systemd/system/marlon-#{@file_name}.service && sudo systemctl daemon-reload && sudo systemctl enable marlon-#{@file_name}"
        end
      end

      def exec_path(file_base)
        app_root = Dir.pwd
        service_file = File.join(app_root, "app", "marlon", "services", "#{file_base}.rb")
        %Q{/usr/bin/env ruby -r bundler/setup -e "load '#{service_file}'"}
      end
    end
  end
end
