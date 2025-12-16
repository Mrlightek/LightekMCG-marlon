# lib/marlon/service_generator.rb
require 'fileutils'
require 'yaml'
require 'json'

module Marlon
  class ServiceGenerator
    DEFAULT_SYSTEMD_DIR   = "/etc/systemd/system"
    DEFAULT_CLI_DIR       = "/usr/local/bin"
    DEFAULT_INSTALL_DIR   = "/opt/marlon"
    DEFAULT_LOG_DIR       = "/var/log/marlon"
    DEFAULT_METRICS_DIR   = "/var/lib/marlon/metrics"

    attr_reader :name, :exec, :cpu, :memory, :depends_on, :optional
    attr_reader :network_limit, :disk_limit, :env_vars, :ports, :sockets, :flags
    attr_reader :timer, :watchdog, :transient, :metrics, :alerts

    # -----------------------------
    # Initialize service generator
    # -----------------------------
    def initialize(name:, exec:, cpu: 1, memory: 256, depends_on: [], optional: false,
                   network_limit: nil, disk_limit: nil, env_vars: {}, ports: [], sockets: [], flags: [],
                   timer: nil, watchdog: nil, transient: false,
                   metrics: true, alerts: {})
      @name           = name
      @exec           = exec
      @cpu            = cpu
      @memory         = memory
      @depends_on     = depends_on
      @optional       = optional
      @network_limit  = network_limit
      @disk_limit     = disk_limit
      @env_vars       = env_vars
      @ports          = ports
      @sockets        = sockets
      @flags          = flags
      @timer          = timer
      @watchdog       = watchdog
      @transient      = transient
      @metrics        = metrics
      @alerts         = alerts

      validate!
    end

    # -----------------------------
    # Generate everything
    # -----------------------------
    def generate
      ordered_services = resolve_dependencies
      ordered_services.each do |service|
        write_cli_wrapper(service)
        register_command(service)
        write_systemd_unit(service)
        write_timer_unit(service) if timer
        enable_and_start_service(service)
        write_service_dsl(service)
        setup_metrics_logging(service) if metrics
      end
    end

    private

    # -----------------------------
    # Validation enforcing Service Contract
    # -----------------------------
    def validate!
      raise "Service name required" if name.to_s.strip.empty?
      raise "Exec path required" if exec.to_s.strip.empty?
      raise "CPU must be > 0" if cpu <= 0
      raise "Memory must be > 0" if memory <= 0
    end

    # -----------------------------
    # Topological sort of dependencies
    # -----------------------------
    def resolve_dependencies
      services = {}
      registry_path = File.join(DEFAULT_INSTALL_DIR, "services_registry.yml")
      services = YAML.load_file(registry_path) if File.exist?(registry_path)
      services ||= {}

      services[name] = { depends_on: depends_on }

      visited = {}
      result = []

      visit = lambda do |s|
        return if visited[s]
        visited[s] = true
        Array(services[s][:depends_on]).each { |dep| visit.call(dep) }
        result << s unless result.include?(s)
      end

      visit.call(name)

      FileUtils.mkdir_p(File.dirname(registry_path))
      File.write(registry_path, services.to_yaml)

      puts "🔗 Services start order: #{result.join(' -> ')}"
      result
    end

    # -----------------------------
    # CLI wrapper
    # -----------------------------
    def write_cli_wrapper(service_name)
      cli_path = File.join(DEFAULT_CLI_DIR, service_name)
      puts "🖥 Creating CLI wrapper: #{cli_path}"

      FileUtils.mkdir_p(DEFAULT_CLI_DIR)

      env_exports = env_vars.map { |k, v| "export #{k}=#{v}" }.join("\n")
      flags_str = flags.join(' ')

      File.write(cli_path, <<~BASH)
        #!/bin/bash
        export GEM_HOME=#{DEFAULT_INSTALL_DIR}/gems
        export GEM_PATH=#{DEFAULT_INSTALL_DIR}/gems
        export PATH=#{DEFAULT_INSTALL_DIR}/gems/bin:$PATH
        export RUBYLIB=#{DEFAULT_INSTALL_DIR}/lib:$RUBYLIB
        #{env_exports}

        # Start Marlon service with metrics logging
        exec ruby #{exec} #{flags_str} "$@" 2>&1 | tee -a #{DEFAULT_LOG_DIR}/#{service_name}.log
      BASH

      FileUtils.chmod("+x", cli_path)
    end

    # -----------------------------
    # Register in global Marlon commands
    # -----------------------------
    def register_command(service_name)
      registry_path = File.join(DEFAULT_INSTALL_DIR, "commands.yml")
      FileUtils.mkdir_p(File.dirname(registry_path))
      FileUtils.touch(registry_path)
      registry = File.exist?(registry_path) ? YAML.load_file(registry_path) || {} : {}
      registry[service_name] = { exec: exec, flags: flags, env: env_vars }
      File.write(registry_path, registry.to_yaml)
      puts "📚 Registered command '#{service_name}' in Marlon registry"
    end

    # -----------------------------
    # Systemd service unit
    # -----------------------------
    def write_systemd_unit(service_name)
      systemd_path = File.join(DEFAULT_SYSTEMD_DIR, "#{service_name}.service")
      puts "⚙️ Creating systemd service unit: #{systemd_path}"

      dependencies_str = depends_on.map { |dep| "After=#{dep}.service\nRequires=#{dep}.service" }.join("\n")
      network_quota = network_limit ? "NetworkBandwidthMax=#{network_limit}" : ""
      disk_quota = disk_limit ? "BlockIOWeight=#{disk_limit}" : ""
      env_lines = env_vars.map { |k, v| "Environment=\"#{k}=#{v}\"" }.join("\n")
      socket_lines = sockets.map { |s| "ListenStream=#{s}" }.join("\n")
      ports_comment = ports.any? ? "# Ports: #{ports.join(', ')}" : ""
      watchdog_line = watchdog ? "WatchdogSec=#{watchdog[:interval]}\nRestart=#{watchdog[:restart_on_fail] ? 'always' : 'no'}" : ""

      FileUtils.mkdir_p(DEFAULT_LOG_DIR)

      template = <<~UNIT
        [Unit]
        Description=Marlon Service: #{service_name}
        #{dependencies_str}

        [Service]
        ExecStart=#{exec} #{flags.join(' ')}
        Restart=always
        RestartSec=5
        StartLimitIntervalSec=30
        StartLimitBurst=3
        CPUQuota=#{cpu}%
        MemoryLimit=#{memory}M
        #{network_quota}
        #{disk_quota}
        #{env_lines}
        #{socket_lines}
        StandardOutput=journal
        StandardError=journal
        #{ports_comment}
        #{watchdog_line}
        # Metrics logging enabled: #{metrics}

        [Install]
        WantedBy=multi-user.target
      UNIT

      if transient
        systemd_path.sub!('.service', '@.service')
        template += "\n# Transient service unit\n"
      end

      File.write(systemd_path, template)
    end

    # -----------------------------
    # Optional timer unit
    # -----------------------------
    def write_timer_unit(service_name)
      timer_path = File.join(DEFAULT_SYSTEMD_DIR, "#{service_name}.timer")
      puts "⏱ Creating systemd timer unit: #{timer_path}"

      on_boot = timer[:on_boot_sec] || 0
      on_active = timer[:on_unit_active_sec] || 60
      accuracy = timer[:accuracy_sec] || '1s'

      template = <<~TIMER
        [Unit]
        Description=Timer for #{service_name}

        [Timer]
        OnBootSec=#{on_boot}
        OnUnitActiveSec=#{on_active}
        AccuracySec=#{accuracy}

        [Install]
        WantedBy=timers.target
      TIMER

      File.write(timer_path, template)
    end

    # -----------------------------
    # Enable & start systemd service
    # -----------------------------
    def enable_and_start_service(service_name)
      puts "🚀 Enabling and starting service #{service_name}..."
      system("sudo systemctl daemon-reload")
      system("sudo systemctl enable #{service_name}")
      system("sudo systemctl start #{service_name}")
      system("sudo systemctl enable #{service_name}.timer") if timer
      system("sudo systemctl start #{service_name}.timer") if timer
    end

    # -----------------------------
    # Service DSL for Marlon
    # -----------------------------
    def write_service_dsl(service_name)
      dsl_path = File.join(DEFAULT_INSTALL_DIR, "services", "#{service_name}.rb")
      FileUtils.mkdir_p(File.dirname(dsl_path))
      puts "📄 Writing Marlon DSL file: #{dsl_path}"

      File.write(dsl_path, <<~RUBY)
        Marlon.define_service "#{service_name}" do
          exec "#{exec}"
          cpu #{cpu}
          memory #{memory}
          depends_on #{depends_on.inspect}
          optional #{optional}
          network_limit #{network_limit.inspect}
          disk_limit #{disk_limit.inspect}
          env_vars #{env_vars.inspect}
          ports #{ports.inspect}
          sockets #{sockets.inspect}
          flags #{flags.inspect}
          timer #{timer.inspect}
          watchdog #{watchdog.inspect}
          transient #{transient}
          metrics #{metrics}
          alerts #{alerts.inspect}
        end
      RUBY
    end

    # -----------------------------
    # Metrics & Logging Setup
    # -----------------------------
    def setup_metrics_logging(service_name)
      FileUtils.mkdir_p(DEFAULT_METRICS_DIR)

      metric_script = File.join(DEFAULT_INSTALL_DIR, "services", "#{service_name}_metrics.rb")
      File.write(metric_script, <<~RUBY)
        require 'json'
        metrics_file = "#{DEFAULT_METRICS_DIR}/#{service_name}.json"

        loop do
          stats = {
            timestamp: Time.now.to_i,
            cpu_percent: `ps -p \#{Process.pid} -o %cpu=`.to_f,
            memory_kb: `ps -p \#{Process.pid} -o rss=`.to_i,
            uptime_sec: `cat /proc/uptime`.split[0].to_f
          }
          File.write(metrics_file, JSON.pretty_generate(stats))
          sleep 5
        end
      RUBY

      puts "📊 Metrics script written: #{metric_script}"
    end
  end

  # -----------------------------
  # DSL helper method
  # -----------------------------
  def self.marlon_generate_service(name:, **kwargs)
    ServiceGenerator.new(name: name, **kwargs).generate
  end
end
