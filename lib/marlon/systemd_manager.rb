# lib/marlon/systemd_manager.rb
require "open3"

module Marlon
  class SystemdManager
    def self.unit_name_for(id)
      "marlon-#{id.to_s.downcase}"
    end

    def self.write_unit_to_tmp(id, content)
      tmp = "/tmp/#{unit_name_for(id)}.service"
      File.write(tmp, content)
      tmp
    end

    def self.install_unit_from_tmp(id, target_path: "/etc/systemd/system", force: false)
      tmp = "/tmp/#{unit_name_for(id)}.service"
      unless File.exist?(tmp)
        raise "Unit file not found at #{tmp}"
      end
      dest = File.join(target_path, "#{unit_name_for(id)}.service")
      if File.exist?(dest) && !force
        raise "Target unit exists at #{dest}. Use force: true to overwrite"
      end
      system("sudo mv #{tmp} #{dest}") or raise "sudo mv failed"
      system("sudo systemctl daemon-reload") or raise "systemctl daemon-reload failed"
      dest
    end

    def self.enable_and_start(id)
      name = unit_name_for(id)
      system("sudo systemctl enable #{name}")
      system("sudo systemctl start #{name}")
    end

    def self.status(id)
      name = unit_name_for(id)
      out, err, st = Open3.capture3("systemctl status #{name}")
      { out: out, err: err, code: st.exitstatus }
    end
  end
end
