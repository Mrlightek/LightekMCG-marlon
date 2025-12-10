# lib/marlon/proxy/ws_proxy.rb
require "async/websocket"
require "async/http/client"
require "async/io"

module Marlon
  module Proxy
    class WSProxy
      def initialize; end

      # a naive ws proxy: upgrades and forwards messages to upstream
      def proxy(env, upstream_url)
        # This is a skeleton — for real deployments, use a tested proxy library
        [501, { "Content-Type" => "application/json" }, [ { error: "ws_proxy_not_implemented" }.to_json ]]
      end
    end
  end
end
