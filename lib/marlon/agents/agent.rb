# lib/marlon/agents/agent.rb
require "net/http"
require "uri"
require "json"
require "fileutils"
require "securerandom"
require "socket"

module Marlon
  module Agents
    class Agent
      # Control-plane gatekeeper URL (example: https://control.lightek.com/marlon/gatekeeper)
      def initialize(control_url:, token:)
        @gatekeeper_url = control_url
        @token = token
        @agent_id = "agent-#{Socket.gethostname}-#{SecureRandom.hex(4)}"
        @work_dir = "/var/lib/marlon-agent"
        FileUtils.mkdir_p(@work_dir)
      end

      attr_reader :agent_id

      # Register the agent in control plane (via Gatekeeper payload)
      def register!(meta = {})
        payload = {
          service: "Cloud::Agent",
          action: "register",
          payload: { agent_id: agent_id, hostname: Socket.gethostname, local_ip: local_ip }.merge(meta)
        }
        post_gatekeeper(payload)
      end

      # Send heartbeat (health metrics). Control plane replies with commands or nothing.
      def heartbeat!(metrics = {})
        payload = {
          service: "Cloud::Agent",
          action: "heartbeat",
          payload: { agent_id: agent_id, metrics: metrics, timestamp: Time.now.to_i }
        }
        post_gatekeeper(payload)
      end

      # Poll for jobs explicitly (control-plane returns job list)
      def poll_jobs!
        payload = { service: "Cloud::Agent", action: "poll_jobs", payload: { agent_id: agent_id } }
        post_gatekeeper(payload)
      end

      # Main loop: register + heartbeat + poll jobs + handle jobs
      def run(poll_interval: 15)
        register! rescue nil
        loop do
          begin
            heartbeat_response = heartbeat!(collect_metrics)
            handle_control_response(heartbeat_response)

            jobs_response = poll_jobs!
            handle_control_response(jobs_response)

          rescue => e
            puts "[agent] error: #{e.class}: #{e.message}"
          end
          sleep poll_interval
        end
      end

      # Handle control-plane responses (jobs or immediate commands)
      def handle_control_response(res)
        return unless res.is_a?(Hash)
        # Expected response format: { success: true, result: { jobs: [ {id:, type:, payload: {...}} ] } }
        result = res["result"] || res[:result] || {}
        (result["jobs"] || result[:jobs] || []).each { |job| handle_job(job) }
        # support direct commands in `result["command"]` if desired
      end

      # Job runner (safe, idempotent where possible)
      def handle_job(job)
        puts "[agent] Running job #{job['id']} (#{job['type']})"
        case job["type"]
        when "deploy_bundle"
          deploy_bundle(job)
        when "run_command"
          run_command(job)
        else
          report_job_failed(job["id"], "unknown_job_type")
        end
      rescue => e
        report_job_failed(job["id"], e.message)
      end

      def deploy_bundle(job)
        payload = job["payload"] || {}
        artifact = payload["artifact_url"]
        sig = payload["signature_url"]
        job_id = job["id"]

        tmp = File.join(@work_dir, "bundle-#{SecureRandom.hex(6)}.tgz")
        File.open(tmp, "wb") { |f| f.write URI.open(artifact).read }

        # verify signature - placeholder: implement ed25519 verify
        unless verify_signature(tmp, sig)
          return report_job_failed(job_id, "signature_verification_failed")
        end

        # backup current app (best-effort)
        backup_dir = File.join(@work_dir, "backups", Time.now.utc.strftime("%Y%m%d%H%M%S"))
        FileUtils.mkdir_p(backup_dir)
        FileUtils.cp_r(Dir["/srv/marlon/*"], backup_dir) rescue nil

        # apply bundle: extract to /srv/marlon
        FileUtils.mkdir_p("/srv/marlon")
        system("tar xzf #{tmp} -C /srv/marlon") or return report_job_failed(job_id, "untar_failed")

        # run migrations (safely): wrap in `marlon db:migrate` call
        system("cd /srv/marlon && bundle exec marlon db:migrate") rescue nil

        # restart marlon service
        system("systemctl restart marlon.service") rescue nil

        # smoke test: call gatekeeper health in local marlon
        ok = smoke_test_local
        if ok
          report_job_complete(job_id, { ok: true })
        else
          # rollback
          FileUtils.rm_rf("/srv/marlon")
          FileUtils.cp_r(backup_dir, "/srv/marlon") rescue nil
          system("systemctl restart marlon.service") rescue nil
          report_job_failed(job_id, "smoke_test_failed")
        end
      end

      def run_command(job)
        cmd = job.dig("payload", "command")
        out = `#{cmd} 2>&1`
        report_job_complete(job["id"], { output: out })
      end

      # Helpers: post a Gatekeeper payload and parse response JSON
      def post_gatekeeper(payload)
        uri = URI.parse(@gatekeeper_url)
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["X-MARLON-TOKEN"] = @token if @token
        req.body = payload.to_json
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(req)
        end
        JSON.parse(res.body) rescue nil
      end

      def report_job_complete(job_id, result = {})
        payload = { service: "Cloud::Agent", action: "job_complete", payload: { agent_id: agent_id, job_id: job_id, result: result } }
        post_gatekeeper(payload)
      end

      def report_job_failed(job_id, reason)
        payload = { service: "Cloud::Agent", action: "job_failed", payload: { agent_id: agent_id, job_id: job_id, error: reason } }
        post_gatekeeper(payload)
      end

      def local_ip
        Socket.ip_address_list.detect(&:ipv4_private?)&.ip_address || "127.0.0.1"
      end

      def collect_metrics
        {
          uptime: `uptime`.strip,
          load: (File.read("/proc/loadavg").split[0] rescue nil),
          free_mem_kb: (`grep MemAvailable /proc/meminfo 2>/dev/null` =~ /(\d+)/ ? $1.to_i : nil),
          disk_free_kb: (`df -k / | tail -1 | awk '{print $4}'` rescue nil)
        }
      rescue
        {}
      end

      def verify_signature(bundle_path, sig_url)
        # placeholder: implement ed25519 verify using control-plane public key and signature download
        # For now, return true to allow testing; replace for production.
        true
      end

      def smoke_test_local
        begin
          uri = URI("http://127.0.0.1:3000/marlon/gatekeeper")
          req = Net::HTTP::Post.new(uri)
          req["Content-Type"] = "application/json"
          req.body = { service: "Health::Main", action: "ping", payload: {} }.to_json
          res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
          res.is_a?(Net::HTTPSuccess)
        rescue
          false
        end
      end
    end
  end
end
