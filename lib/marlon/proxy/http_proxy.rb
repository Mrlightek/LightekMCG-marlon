# lib/marlon/proxy/http_proxy.rb
require "async/http/internet"
require "uri"

module Marlon
  module Proxy
    class HttpProxy
      DEFAULT_OPTS = {
        retries: 2,
        timeout: 10
      }.freeze

      def initialize(opts = {})
        @opts = DEFAULT_OPTS.merge(opts)
        @internet = Async::HTTP::Internet.new
      end

      # naive routing: mount -> backend url
      # target_url must be full upstream URL
      def forward(env, target_url)
        req = Rack::Request.new(env)
        uri = URI.join(target_url, req.fullpath.sub(/^\//, ""))
        headers = extract_headers(env)

        Async do |task|
          attempt = 0
          begin
            attempt += 1
            response = @internet.call(uri, method: req.request_method, headers: headers, body: req.body)
            [response.status, response.headers, [response.read]]
          rescue => e
            if attempt <= @opts[:retries]
              sleep(0.2 * attempt)
              retry
            else
              [502, { "Content-Type" => "application/json" }, [ { error: "bad_gateway", message: e.message }.to_json ]]
            end
          end
        end.wait
      end

      private

      def extract_headers(env)
        headers = {}
        env.each do |k, v|
          if k.start_with?("HTTP_")
            name = k.sub(/^HTTP_/, "").split("_").map(&:capitalize).join("-")
            headers[name] = v if v
          end
        end
        headers["Content-Type"] = env["CONTENT_TYPE"] if env["CONTENT_TYPE"]
        headers
      end
    end
  end
end
